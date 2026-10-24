import Testing
import PuzzleKit

@Suite("Slitherlink kural doğrulayıcı")
struct SlitherlinkRulesTests {
    private let rules = SlitherlinkRules()
    private let puzzle = SlitherlinkFixture.block3x3

    /// `block3x3`'ün çözümü: sol üstteki 2×2 bloğun çevresi.
    private var expectedLoop: Set<Int> {
        // 3×3 ızgarada yatay kenar indeksi = satır * 3 + sütun, dikey = 12 + satır * 4 + sütun.
        [0, 1, 6, 7, 12, 16, 14, 18]
    }

    @Test("Izgara dışı ve eski değeri tutmayan hamle engelleniyor")
    func invalidMovesAreRejected() {
        let board = SlitherlinkBoard(puzzle)
        #expect(!rules.isLegal(
            SlitherlinkMove(edge: 99, previous: .unknown, next: .line), on: board, in: puzzle
        ))
        #expect(!rules.isLegal(
            SlitherlinkMove(edge: 0, previous: .line, next: .cross), on: board, in: puzzle
        ))
        #expect(rules.isLegal(
            SlitherlinkMove(edge: 0, previous: .unknown, next: .line), on: board, in: puzzle
        ))
    }

    // Hitori'deki gibi: üç çizgiyi aynı noktada birleştirmek mümkün, yalnız yanlış.
    @Test("Üç çizgiyi bir noktada birleştirmek kurallara uygun, ama ihlal")
    func branchingIsLegalButReported() {
        var board = SlitherlinkBoard(puzzle)
        // (1,1) iç noktasına değen üç kenar.
        let dot = (puzzle.size.columns + 1) + 1
        for edge in puzzle.edgesOfDot[dot].prefix(3) {
            let move = SlitherlinkMove(edge: edge, previous: board[edge], next: .line)
            #expect(rules.isLegal(move, on: board, in: puzzle))
            move.apply(to: &board)
        }
        #expect(board.degree(ofDot: dot, in: puzzle) == 3)
        #expect(!rules.violations(on: board, in: puzzle).isEmpty)
    }

    @Test("İpucunu aşan hücre ihlal")
    func clueOverflowIsReported() {
        var board = SlitherlinkBoard(puzzle)
        let cell = puzzle.index(of: pos(2, 2))
        // (2,2) ipucu 0; tek bir çizgi bile aşırı.
        board[puzzle.edgesOfCell[cell][0]] = .line
        #expect(rules.violations(on: board, in: puzzle).contains(pos(2, 2)))
    }

    @Test("İpucuna artık ulaşamayan hücre ihlal")
    func unreachableClueIsReported() {
        var board = SlitherlinkBoard(puzzle)
        let cell = puzzle.index(of: pos(0, 0))
        // (0,0) ipucu 2; üç kenarı çarpılanınca kalan tek kenarla 2'ye ulaşılamıyor.
        for edge in puzzle.edgesOfCell[cell].prefix(3) {
            board[edge] = .cross
        }
        #expect(rules.violations(on: board, in: puzzle).contains(pos(0, 0)))
    }

    @Test("Eksik kenar ihlal değil, tamamlanmamışlık")
    func incompleteBoardHasNoViolations() {
        var board = SlitherlinkBoard(puzzle)
        board[0] = .line
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
        #expect(!rules.isSolved(board, in: puzzle))
    }

    @Test("Beklenen döngü çözüm sayılıyor")
    func expectedLoopIsSolved() {
        var board = SlitherlinkBoard(puzzle)
        for edge in 0..<puzzle.edgeCount {
            board[edge] = expectedLoop.contains(edge) ? .line : .cross
        }
        #expect(rules.isSolved(board, in: puzzle))
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
        #expect(rules.loopCount(on: board, in: puzzle) == 1)
    }

    @Test("Boş tahta çözüm değil: döngü yok")
    func emptyBoardIsNotSolved() {
        let board = SlitherlinkBoard(edges: [EdgeState](repeating: .cross, count: puzzle.edgeCount))
        // Bütün noktaların derecesi 0 ve ipucu 0 olan hücre tutuyor, ama döngü yok.
        #expect(rules.loopCount(on: board, in: puzzle) == 0)
        #expect(!rules.isSolved(board, in: puzzle))
    }

    // Tek döngü koşulu Slitherlink'i diğer varyantlardan ayıran şey: bütün noktaların
    // derecesi 2 olsa ve ipuçlar tutsa bile iki ayrı döngü çözüm değil.
    @Test("İki ayrı döngü çözüm değil")
    func twoLoopsAreNotSolved() {
        // 5×5 ipuçsuz ızgara: iki ayrı 2×2 döngü kurulabiliyor.
        let open = SlitherlinkFixture.parse("""
        . . . . .
        . . . . .
        . . . . .
        . . . . .
        . . . . .
        """)
        var board = SlitherlinkBoard(edges: [EdgeState](repeating: .cross, count: open.edgeCount))
        for block in [pos(0, 0), pos(3, 3)] {
            let cells = [
                block, block.offset(byRows: 0, columns: 1),
                block.offset(byRows: 1, columns: 0), block.offset(byRows: 1, columns: 1)
            ]
            var border = Set<Int>()
            for cell in cells {
                for edge in open.edgesOfCell[open.index(of: cell)] {
                    if border.contains(edge) { border.remove(edge) } else { border.insert(edge) }
                }
            }
            for edge in border { board[edge] = .line }
        }

        for dot in 0..<open.dotCount {
            let degree = board.degree(ofDot: dot, in: open)
            #expect(degree == 0 || degree == 2, "nokta \(dot) derecesi \(degree)")
        }
        #expect(rules.loopCount(on: board, in: open) == 2)
        #expect(!rules.isSolved(board, in: open))
        #expect(!rules.violations(on: board, in: open).isEmpty)
    }
}

@Suite("Slitherlink çözücü")
struct SlitherlinkSolverTests {
    private let solver = SlitherlinkSolver()
    private let rules = SlitherlinkRules()

    @Test("Bilinen bulmacanın tek çözümü var ve beklenen döngü")
    func knownPuzzleHasKnownUniqueSolution() throws {
        let puzzle = SlitherlinkFixture.block3x3
        let solutions = try solver.findSolutions(of: puzzle, upTo: 4)
        #expect(solutions.count == 1)

        let lines = Set(solutions[0].lines.indices.filter { solutions[0].lines[$0] })
        #expect(lines == [0, 1, 6, 7, 12, 14, 16, 18])
    }

    @Test("En küçük bulmacanın tek çözümü var")
    func smallestPuzzleIsUnique() throws {
        let solutions = try solver.findSolutions(of: SlitherlinkFixture.square2x2, upTo: 4)
        #expect(solutions.count == 1)
        #expect(solutions[0].lineCount == 8)
    }

    @Test("Bütün ipuçlar 3 olan bulmacanın çözümü yok")
    func allThreesHaveNoSolution() throws {
        let puzzle = SlitherlinkFixture.impossible2x2
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).isEmpty)
        let outcome = try solver.uniquenessCheck(puzzle)
        if case .none = outcome {} else {
            Issue.record("Beklenen .none, gelen \(outcome)")
        }
    }

    @Test("Tek ipuçlu bulmaca çok çözümlü")
    func singleClueIsAmbiguous() throws {
        let puzzle = SlitherlinkFixture.ambiguous3x3
        #expect(try solver.findSolutions(of: puzzle, upTo: 4).count == 4)
        let outcome = try solver.uniquenessCheck(puzzle)
        if case .multiple = outcome {} else {
            Issue.record("Beklenen .multiple, gelen \(outcome)")
        }
    }

    @Test("Dönen her çözüm kural doğrulayıcıdan geçiyor")
    func everySolutionSatisfiesRules() throws {
        for puzzle in [
            SlitherlinkFixture.block3x3,
            SlitherlinkFixture.square2x2,
            SlitherlinkFixture.ambiguous3x3
        ] {
            for solution in try solver.findSolutions(of: puzzle, upTo: 4) {
                #expect(rules.isSolved(solution.board(), in: puzzle))
            }
        }
    }

    @Test("Çözüm sayısı sınırına uyuluyor")
    func solutionLimitIsRespected() throws {
        let puzzle = SlitherlinkFixture.ambiguous3x3
        #expect(try solver.findSolutions(of: puzzle, upTo: 1).count == 1)
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).count == 2)
        #expect(try solver.findSolutions(of: puzzle, upTo: 0).isEmpty)
    }

    @Test("Arama deterministik")
    func searchIsDeterministic() throws {
        let puzzle = SlitherlinkFixture.ambiguous3x3
        #expect(
            try solver.findSolutions(of: puzzle, upTo: 4)
                == solver.findSolutions(of: puzzle, upTo: 4)
        )
    }

    @Test("Bütçe tükendiğinde sonuç belirsiz, sessizce benzersiz sayılmıyor")
    func exhaustedBudgetYieldsIndeterminate() throws {
        let tight = SlitherlinkSolver(searchNodeBudget: 1)
        let outcome = try tight.uniquenessCheck(SlitherlinkFixture.ambiguous3x3)
        #expect(outcome.isIndeterminate)
        #expect(!outcome.isUnique)
    }
}

@Suite("Slitherlink teknik seviyeleri")
struct SlitherlinkTechniqueTests {
    private let solver = SlitherlinkSolver()

    // Klasik açılış desenleri — köşedeki 3, yan yana iki 3, köşedeki 1 — ipucu ile köşe
    // noktalarının paritesinin birleşiminden çıkıyor. Tek tek yazmak yerine birleşim
    // sayılıyor, ve bu test o sayımın gerçekten temel seviyede çözdüğünü koruyor.
    @Test("Hücre + köşe sayımı temel seviyede çözüyor")
    func cellEnumerationSolvesAtBasicTier() throws {
        let trace = try solver.trace(of: SlitherlinkFixture.block3x3)
        #expect(trace.highestTier == .basic)
        #expect(trace.difficulty == .easy)
        #expect(trace.techniques.contains("cell"))
    }

    @Test("Mantıkla kapanmayan bulmaca guessing")
    func ambiguousPuzzleIsGuessing() throws {
        let trace = try solver.trace(of: SlitherlinkFixture.ambiguous3x3)
        #expect(trace.highestTier == .guessing)
        #expect(trace.difficulty == .expert)
    }

    @Test("Mantıksal ilerleme temel seviyede tam")
    func logicalProgressIsCompleteOnEasyPuzzle() {
        #expect(solver.logicalProgress(of: SlitherlinkFixture.block3x3) == 1)
        #expect(solver.logicalProgress(of: SlitherlinkFixture.ambiguous3x3) < 1)
    }
}
