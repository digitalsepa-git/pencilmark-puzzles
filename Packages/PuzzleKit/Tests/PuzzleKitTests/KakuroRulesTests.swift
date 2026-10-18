import Testing
import PuzzleKit

@Suite("Kakuro kural doğrulayıcı")
struct KakuroRulesTests {
    private let rules = KakuroRules()
    private let puzzle = KakuroFixture.unique2x2

    @Test("İpucu hücresine yazmak engelleniyor")
    func writingOnClueCellIsIllegal() {
        let board = KakuroBoard(puzzle)
        let move = KakuroMove(position: pos(1, 1), previous: .empty, next: DigitCell(value: 3))
        #expect(!rules.isLegal(move, on: board, in: puzzle))
    }

    @Test("1-9 dışı rakam ve aday engelleniyor")
    func outOfRangeDigitIsIllegal() {
        let board = KakuroBoard(puzzle)
        #expect(!rules.isLegal(
            KakuroMove(position: pos(1, 2), previous: .empty, next: DigitCell(value: 0)),
            on: board, in: puzzle
        ))
        #expect(rules.isLegal(
            KakuroMove.writing(9, at: pos(1, 2), on: board), on: board, in: puzzle
        ))
    }

    // Kesitte zaten var olan rakamı yazmak engellenmiyor: yanlış ama kurallara uygun.
    @Test("Kesit içi tekrar kurallara uygun, ama ihlal olarak görünüyor")
    func duplicateInRunIsLegalButReported() {
        var board = KakuroBoard(puzzle)
        KakuroMove.writing(3, at: pos(1, 2), on: board).apply(to: &board)

        let duplicate = KakuroMove.writing(3, at: pos(1, 3), on: board)
        #expect(rules.isLegal(duplicate, on: board, in: puzzle))
        duplicate.apply(to: &board)

        let reported = rules.violations(on: board, in: puzzle)
        #expect(reported.contains(pos(1, 2)))
        #expect(reported.contains(pos(1, 3)))
    }

    @Test("Dolu kesitin toplamı tutmaması ihlal")
    func fullRunMismatchIsReported() {
        var board = KakuroBoard(puzzle)
        // (1,2)+(1,3) toplamı 7 olmalı; 2+9 = 11.
        KakuroMove.writing(2, at: pos(1, 2), on: board).apply(to: &board)
        KakuroMove.writing(9, at: pos(1, 3), on: board).apply(to: &board)
        #expect(rules.violations(on: board, in: puzzle).contains(pos(1, 2)))
    }

    // Kalan hücreye yazılabilecek en küçük/en büyük toplam kullanılmamış rakamlardan
    // hesaplanıyor: kesit içinde tekrar yasak olduğu için "kalan × 1" sınırı gevşek kalırdı.
    @Test("Toplama artık ulaşamayan kesit dolmadan ihlal bildiriyor")
    func unreachableRunIsReportedEarly() {
        var board = KakuroBoard(puzzle)
        // (1,2) kesidinin toplamı 7; 6 yazılınca kalan hücreye 1 gerekir, hâlâ mümkün.
        KakuroMove.writing(6, at: pos(1, 2), on: board).apply(to: &board)
        #expect(rules.violations(on: board, in: puzzle).isEmpty)

        KakuroMove.erasing(at: pos(1, 2), on: board).apply(to: &board)
        // 7 yazılınca kalan hücreye 0 gerekir — imkânsız.
        KakuroMove.writing(7, at: pos(1, 2), on: board).apply(to: &board)
        #expect(rules.violations(on: board, in: puzzle).contains(pos(1, 3)))
    }

    @Test("Eksik hücre ihlal değil, tamamlanmamışlık")
    func incompleteBoardHasNoViolations() {
        var board = KakuroBoard(puzzle)
        KakuroMove.writing(1, at: pos(1, 2), on: board).apply(to: &board)
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
        #expect(!rules.isSolved(board, in: puzzle))
    }

    @Test("Beklenen çözüm kurallara uygun")
    func knownSolutionIsSolved() {
        let board = KakuroFixture.unique2x2Solution.board()
        #expect(rules.isSolved(board, in: puzzle))
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
        #expect(board.isComplete(in: puzzle))
    }

    @Test("Boş tahta çözüm değil")
    func emptyBoardIsNotSolved() {
        let board = KakuroBoard(puzzle)
        #expect(board.isEmpty(in: puzzle))
        #expect(!rules.isSolved(board, in: puzzle))
    }
}

@Suite("Kakuro çözücü")
struct KakuroSolverTests {
    private let solver = KakuroSolver()
    private let rules = KakuroRules()

    @Test("Bilinen bulmacanın tek çözümü var ve beklenen çözüm")
    func knownPuzzleHasKnownUniqueSolution() throws {
        let solutions = try solver.findSolutions(of: KakuroFixture.unique2x2, upTo: 4)
        #expect(solutions == [KakuroFixture.unique2x2Solution])
    }

    // Çözümsüzlük tek bir kesitte değil, kesitler arasındaki tutarsızlıkta: satır
    // toplamları 23, sütun toplamları 24.
    @Test("Kesitler arası tutarsızlık çözümü engelliyor")
    func inconsistentSumsHaveNoSolution() throws {
        let puzzle = KakuroFixture.impossible2x2
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).isEmpty)
        let outcome = try solver.uniquenessCheck(puzzle)
        if case .none = outcome {} else {
            Issue.record("Beklenen .none, gelen \(outcome)")
        }
    }

    // Gerçek Kakuro'yu benzersiz yapan şey iç siyah hücreler: dolu bir blok, toplamlar
    // doğru olsa bile yetmiyor.
    @Test("Dolu blok çok çözümlü")
    func solidBlockIsAmbiguous() throws {
        let puzzle = KakuroFixture.ambiguous3x3
        #expect(try solver.findSolutions(of: puzzle, upTo: 4).count == 4)

        let outcome = try solver.uniquenessCheck(puzzle)
        if case .multiple = outcome {} else {
            Issue.record("Beklenen .multiple, gelen \(outcome)")
        }
    }

    @Test("Dönen her çözüm kural doğrulayıcıdan geçiyor")
    func everySolutionSatisfiesRules() throws {
        for puzzle in [KakuroFixture.unique2x2, KakuroFixture.ambiguous3x3] {
            for solution in try solver.findSolutions(of: puzzle, upTo: 4) {
                #expect(rules.isSolved(solution.board(), in: puzzle))
            }
        }
    }

    @Test("Çözüm sayısı sınırına uyuluyor")
    func solutionLimitIsRespected() throws {
        let puzzle = KakuroFixture.ambiguous3x3
        #expect(try solver.findSolutions(of: puzzle, upTo: 1).count == 1)
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).count == 2)
        #expect(try solver.findSolutions(of: puzzle, upTo: 0).isEmpty)
    }

    @Test("Arama deterministik")
    func searchIsDeterministic() throws {
        let puzzle = KakuroFixture.ambiguous3x3
        #expect(
            try solver.findSolutions(of: puzzle, upTo: 4)
                == solver.findSolutions(of: puzzle, upTo: 4)
        )
    }
}

@Suite("Kakuro teknik seviyeleri")
struct KakuroTechniqueTests {
    private let solver = KakuroSolver()

    // "İki hücrede 17" demek {8,9} demek; bundan sonrası kesit elemesiyle geliyor.
    @Test("Bileşim tekniği temel seviye")
    func combinationTechniqueIsBasic() throws {
        let trace = try solver.trace(of: KakuroFixture.unique2x2)
        #expect(trace.highestTier == .basic)
        #expect(trace.difficulty == .easy)
        #expect(trace.techniques.contains("combination"))
    }

    @Test("Mantıkla kapanmayan bulmaca guessing")
    func ambiguousPuzzleIsGuessing() throws {
        let trace = try solver.trace(of: KakuroFixture.ambiguous3x3)
        #expect(trace.highestTier == .guessing)
        #expect(trace.difficulty == .expert)
    }

    @Test("Mantıksal ilerleme tek çözümlü bulmacada tam")
    func logicalProgressIsCompleteOnEasyPuzzle() {
        #expect(solver.logicalProgress(of: KakuroFixture.unique2x2) == 1)
        #expect(solver.logicalProgress(of: KakuroFixture.ambiguous3x3) < 1)
    }
}
