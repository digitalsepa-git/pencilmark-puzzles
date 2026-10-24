import Testing
import PuzzleKit

@Suite("Slitherlink döngü kurucu")
struct SlitherlinkLoopBuilderTests {
    // Bir hücre kümesinin sınırının tek kapalı döngü olması iki koşula denk: küme bağlı ve
    // deliksiz, ve hiçbir nokta derece 4 olmuyor. Bu testler o iki koşulu koruyor.
    @Test("Kurulan küme geçerli", arguments: [6, 8, 10, 12])
    func builtInsideIsValid(side: Int) {
        let size = GridSize(square: side)
        for seed in UInt64(1)...6 {
            var rng = SeededGenerator(seed: seed)
            guard let inside = SlitherlinkLoopBuilder.inside(
                size: size, target: size.cellCount * 45 / 100, using: &rng
            ) else { continue }
            #expect(SlitherlinkLoopBuilder.isValid(inside, size: size))
        }
    }

    @Test("Köşe köşeye değen hücreler geçersiz")
    func diagonalTouchIsRejected() {
        let size = GridSize(square: 4)
        // (0,0) ve (1,1) köşe köşeye: aradaki nokta derece 4 olur.
        let pinched: Set<Int> = [0, 5, 1, 4]
        // Bu küme aslında 2×2 blok, geçerli. Asıl kıstırma: köşegen ikili, komşuları dışta.
        #expect(SlitherlinkLoopBuilder.isValid(pinched, size: size))

        let diagonal: Set<Int> = [0, 1, 4, 5, 10, 11, 14, 15]
        // İki ayrı 2×2 blok köşe köşeye değiyor; aradaki nokta derece 4.
        #expect(!SlitherlinkLoopBuilder.isValid(diagonal, size: size))
    }

    @Test("Delikli küme geçersiz")
    func holeIsRejected() {
        let size = GridSize(square: 5)
        // Ortadaki hücre hariç 3×3 blok: ortası delik.
        var ring = Set<Int>()
        for row in 1...3 {
            for column in 1...3 where !(row == 2 && column == 2) {
                ring.insert(row * 5 + column)
            }
        }
        #expect(!SlitherlinkLoopBuilder.isValid(ring, size: size))
    }

    @Test("Sınır kenarları iki komşudan tam biri içte olanlar")
    func boundaryPicksEdgesWithOneInsideNeighbour() {
        let size = GridSize(square: 3)
        let inside: Set<Int> = [0, 1, 3, 4]
        let lines = SlitherlinkLoopBuilder.boundary(of: inside, in: size)
        // 2×2 bloğun çevresi sekiz kenar.
        #expect(lines.count { $0 } == 8)

        let puzzle = SlitherlinkPuzzle(clues: Grid(size: size, repeating: nil))
        let rules = SlitherlinkRules()
        let board = SlitherlinkSolution(lines: lines).board()
        #expect(rules.loopCount(on: board, in: puzzle) == 1)
        for dot in 0..<puzzle.dotCount {
            let degree = board.degree(ofDot: dot, in: puzzle)
            #expect(degree == 0 || degree == 2)
        }
    }
}

@Suite("Slitherlink üretici")
struct SlitherlinkGeneratorTests {
    private let rules = SlitherlinkRules()
    private let solver = SlitherlinkSolver()

    private func puzzle(
        _ difficulty: Difficulty,
        seed: UInt64 = 515
    ) throws -> GeneratedPuzzle<SlitherlinkPuzzle, SlitherlinkSolution> {
        try SlitherlinkGenerator.pipeline().generate(difficulty: difficulty, seed: seed)
    }

    @Test("Üretilen bulmaca yapısal olarak geçerli", arguments: Difficulty.allCases)
    func generatedPuzzleIsStructurallyValid(difficulty: Difficulty) throws {
        let built = try puzzle(difficulty)

        #expect(rules.isSolved(built.solution.board(), in: built.definition))
        #expect(rules.violations(on: built.solution.board(), in: built.definition).isEmpty)
        #expect(rules.loopCount(on: built.solution.board(), in: built.definition) == 1)

        // Her noktanın derecesi 0 ya da 2: döngü dallanmıyor, serbest uç bırakmıyor.
        for dot in 0..<built.definition.dotCount {
            let degree = built.solution.board().degree(ofDot: dot, in: built.definition)
            #expect(degree == 0 || degree == 2)
        }
    }

    @Test("İpuçlar çözümden türüyor ve 0-3 aralığında", arguments: Difficulty.allCases)
    func cluesComeFromTheSolution(difficulty: Difficulty) throws {
        let built = try puzzle(difficulty, seed: 616)
        let board = built.solution.board()

        for cell in built.definition.cluedCells {
            guard let clue = built.definition.clue(at: cell) else { continue }
            #expect((0...3).contains(clue))
            #expect(board.lineCount(ofCell: cell, in: built.definition) == clue)
        }
    }

    // Bütün ipuçlar verilmiş bir bulmaca kurallara uygun ve benzersiz ama oynanacak bir şey
    // bırakmıyor: her hücre kendi kenarlarını söylüyor. Yayınlanmış Slitherlink hücrelerin
    // yarısına yakınını boş bırakıyor.
    @Test("İpucu yoğunluğu zorlukla seyrekleşiyor")
    func clueDensityThinsWithDifficulty() throws {
        var densities: [Difficulty: Int] = [:]
        for difficulty in Difficulty.allCases {
            let built = try puzzle(difficulty, seed: 717)
            densities[difficulty] = 100 * built.definition.cluedCells.count
                / built.definition.cellCount
        }
        #expect(densities[.easy]! <= 75)
        #expect(densities[.expert]! <= 55)
        #expect(densities[.expert]! < densities[.easy]!)
    }

    @Test("Izgara boyutları ADR 0005'teki tablodan")
    func layoutSizesFollowDecisionRecord() {
        #expect(SlitherlinkLayout.standard(for: .easy).size == GridSize(square: 6))
        #expect(SlitherlinkLayout.standard(for: .medium).size == GridSize(square: 8))
        #expect(SlitherlinkLayout.standard(for: .hard).size == GridSize(square: 10))
        #expect(SlitherlinkLayout.standard(for: .expert).size == GridSize(square: 12))
    }

    // Slitherlink'te `advanced` de reddediliyor, yalnız `guessing` değil: gönderilen her
    // bulmaca temel ve orta tekniklerle çözülebilir (ADR 0014).
    @Test("İleri teknik gerektiren bulmaca derecelendirilmiyor")
    func advancedPuzzlesAreRejected() {
        let generator = SlitherlinkGenerator()
        let puzzle = SlitherlinkFixture.square2x2

        var advanced = SolveTrace()
        advanced.record("hypothesis", tier: .advanced)
        #expect(generator.rate(advanced, of: puzzle) == nil)

        var guessing = SolveTrace()
        guessing.record("search", tier: .guessing)
        #expect(generator.rate(guessing, of: puzzle) == nil)
    }

    @Test("Orta seviye boyuta göre Medium, Hard ya da Expert")
    func intermediateTierSplitsBySize() {
        let generator = SlitherlinkGenerator()
        var trace = SolveTrace()
        trace.record("prematureClosure", tier: .intermediate)

        func empty(_ side: Int) -> SlitherlinkPuzzle {
            SlitherlinkPuzzle(clues: Grid(size: GridSize(square: side), repeating: nil))
        }
        #expect(generator.rate(trace, of: empty(8)) == .medium)
        #expect(generator.rate(trace, of: empty(10)) == .hard)
        #expect(generator.rate(trace, of: empty(12)) == .expert)
    }
}

@Suite("Slitherlink hat entegrasyonu")
struct SlitherlinkPipelineTests {
    private let pipeline = SlitherlinkGenerator.pipeline()
    private let solver = SlitherlinkSolver()
    private let rules = SlitherlinkRules()

    @Test("Hat benzersiz ve hedef zorlukta bulmaca veriyor", arguments: Difficulty.allCases)
    func pipelineProducesUniquePuzzle(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .slitherlink, difficulty: difficulty, counter: 3)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

        #expect(puzzle.variant == .slitherlink)
        #expect(puzzle.difficulty == difficulty)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
        #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
    }

    @Test("Çözücünün bulduğu çözüm üreticinin kurduğuyla aynı", arguments: Difficulty.allCases)
    func solverAgreesWithGenerator(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .slitherlink, difficulty: difficulty, counter: 11)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2) == [puzzle.solution])
    }

    @Test("Aynı tohum aynı bulmacayı veriyor")
    func sameSeedProducesSamePuzzle() throws {
        let seed = Seed.daily(variant: .slitherlink, year: 2026, month: 10, day: 21)
        let first = try pipeline.generate(difficulty: .medium, seed: seed)
        let second = try pipeline.generate(difficulty: .medium, seed: seed)
        #expect(first.definition == second.definition)
        #expect(first.solution == second.solution)
    }

    @Test("Farklı tohum farklı bulmaca veriyor")
    func differentSeedProducesDifferentPuzzle() throws {
        let first = try pipeline.generate(difficulty: .medium, seed: 61)
        let second = try pipeline.generate(difficulty: .medium, seed: 62)
        #expect(first.definition != second.definition)
    }
}
