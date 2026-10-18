import Testing
import PuzzleKit

@Suite("Calcudoku kural doğrulayıcı")
struct CalcudokuRulesTests {
    private let rules = CalcudokuRules()
    private let puzzle = CalcudokuFixture.handmade4x4

    @Test("Izgara boyutunu aşan rakam engelleniyor")
    func outOfRangeDigitIsIllegal() {
        let board = CalcudokuBoard(puzzle)
        let tooBig = CalcudokuMove(
            position: pos(0, 0), previous: .empty, next: DigitCell(value: 5)
        )
        #expect(!rules.isLegal(tooBig, on: board, in: puzzle))

        let valid = CalcudokuMove.writing(4, at: pos(0, 0), on: board)
        #expect(rules.isLegal(valid, on: board, in: puzzle))
    }

    @Test("Izgara boyutunu aşan kalem işareti engelleniyor")
    func outOfRangeCandidateIsIllegal() {
        let board = CalcudokuBoard(puzzle)
        let move = CalcudokuMove(
            position: pos(0, 0), previous: .empty, next: DigitCell(candidates: DigitSet([9]))
        )
        #expect(!rules.isLegal(move, on: board, in: puzzle))
    }

    // Satırda zaten var olan rakamı yazmak engellenmiyor: yanlış ama kurallara uygun ve
    // oyuncunun deneyip görmesi oyunun kendisi.
    @Test("Tekrar eden rakam kurallara uygun, ama ihlal olarak görünüyor")
    func duplicateIsLegalButReported() {
        var board = CalcudokuBoard(puzzle)
        CalcudokuMove.writing(1, at: pos(0, 0), on: board).apply(to: &board)

        let duplicate = CalcudokuMove.writing(1, at: pos(0, 3), on: board)
        #expect(rules.isLegal(duplicate, on: board, in: puzzle))
        duplicate.apply(to: &board)

        let reported = rules.violations(on: board, in: puzzle)
        #expect(reported.contains(pos(0, 0)))
        #expect(reported.contains(pos(0, 3)))
    }

    @Test("Dolu kafesin hedefi tutmaması ihlal")
    func fullCageMismatchIsReported() {
        var board = CalcudokuBoard(puzzle)
        // (0,0)+(0,1) toplamı 3 olmalı; 2+4 = 6.
        CalcudokuMove.writing(2, at: pos(0, 0), on: board).apply(to: &board)
        CalcudokuMove.writing(4, at: pos(0, 1), on: board).apply(to: &board)

        let reported = rules.violations(on: board, in: puzzle)
        #expect(reported.contains(pos(0, 0)))
        #expect(reported.contains(pos(0, 1)))
    }

    // "Toplamı 7 olan kafese 5 ve 4 yazmak" en sık yapılan hata; oyuncunun bunu kafes
    // tamamen dolmadan görmesi gerekiyor.
    @Test("Hedefe artık ulaşamayan kafes dolmadan ihlal bildiriyor")
    func unreachableCageIsReportedEarly() {
        var board = CalcudokuBoard(puzzle)
        // (1,1)+(1,2)+(1,3) toplamı 8 olmalı. 4 yazılınca kalan iki hücre en az 1+1=2,
        // en fazla 4+4=8 verir; 4 hâlâ mümkün. 1 yazmak da mümkün. Ama 4 ve 4 yazılınca
        // kalan hücreye 0 gerekir — ulaşılamaz.
        CalcudokuMove.writing(4, at: pos(1, 1), on: board).apply(to: &board)
        #expect(rules.violations(on: board, in: puzzle).isEmpty)

        CalcudokuMove.writing(4, at: pos(1, 2), on: board).apply(to: &board)
        let reported = rules.violations(on: board, in: puzzle)
        #expect(reported.contains(pos(1, 1)))
        #expect(reported.contains(pos(1, 3)))
    }

    @Test("Eksik hücre ihlal değil, tamamlanmamışlık")
    func incompleteBoardHasNoViolations() {
        var board = CalcudokuBoard(puzzle)
        CalcudokuMove.writing(1, at: pos(0, 0), on: board).apply(to: &board)
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
        #expect(!rules.isSolved(board, in: puzzle))
    }

    @Test("Elle kurulan çözüm kurallara uygun")
    func handmadeSolutionIsSolved() {
        let board = CalcudokuFixture.handmade4x4Solution.board()
        #expect(rules.isSolved(board, in: puzzle))
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
        #expect(board.isComplete)
    }

    @Test("Boş tahta çözüm değil")
    func emptyBoardIsNotSolved() {
        #expect(!rules.isSolved(CalcudokuBoard(puzzle), in: puzzle))
    }

    @Test("Latin karesi olmayan dolu tahta çözüm değil")
    func nonLatinBoardIsNotSolved() {
        let allOnes = CalcudokuBoard(
            cells: Grid(size: puzzle.size, repeating: DigitCell(value: 1))
        )
        #expect(allOnes.isComplete)
        #expect(!rules.isSolved(allOnes, in: puzzle))
        #expect(!rules.duplicatePositions(on: allOnes, in: puzzle).isEmpty)
    }
}
