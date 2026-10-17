import Testing
import PuzzleKit

@Suite("Hashi üretici")
struct HashiGeneratorTests {
    private let generator = HashiGenerator()
    private let solver = HashiSolver()
    private let rules = HashiRules()

    @Test("Kurulan çözüm kurallara uygun", arguments: Difficulty.allCases)
    func builtSolutionSatisfiesRules(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 4242)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        #expect(rules.isSolved(built.solution.board(), in: built.puzzle))
    }

    @Test("Ada dereceleri kurulan çözümle tutarlı", arguments: Difficulty.allCases)
    func requiredDegreesMatchBuiltSolution(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 777)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        let board = built.solution.board()
        for island in built.puzzle.islands.indices {
            #expect(
                board.degree(ofIsland: island, in: built.puzzle)
                    == built.puzzle.islands[island].required
            )
        }
    }

    @Test("Kurulum gereği köprüler kesişmiyor", arguments: Difficulty.allCases)
    func builtBridgesNeverCross(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 31337)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        #expect(!rules.hasCrossing(built.solution.board(), in: built.puzzle))
    }

    @Test("Izgara boyutları ADR 0005'teki tablodan")
    func layoutSizesFollowDecisionRecord() {
        #expect(HashiLayout.standard(for: .easy).size == GridSize(square: 7))
        #expect(HashiLayout.standard(for: .medium).size == GridSize(square: 9))
        #expect(HashiLayout.standard(for: .hard).size == GridSize(square: 11))
        #expect(HashiLayout.standard(for: .expert).size == GridSize(square: 13))
    }

    // Mantıkla çözülemeyen bulmaca hiçbir zorluğa ait değil ve kullanıcıya verilmiyor.
    // Rakip analizinde (PR #10) en can alıcı şikâyet buydu.
    @Test("Tahmin gerektiren bulmaca derecelendirilmiyor")
    func guessingPuzzlesAreRejected() throws {
        let trace = try solver.trace(of: HashiFixture.ambiguous5x5)
        #expect(trace.highestTier == .guessing)
        #expect(generator.rate(trace, of: HashiFixture.ambiguous5x5) == nil)
    }

    @Test("Hard ile Expert ayrımı varsayım sayısına bağlı")
    func expertNeedsMoreHypotheses() {
        let puzzle = HashiFixture.loop3x3

        var once = SolveTrace()
        once.record("hypothesis", tier: .advanced)
        #expect(generator.rate(once, of: puzzle) == .hard)

        var twice = SolveTrace()
        twice.record("hypothesis", tier: .advanced)
        twice.record("hypothesis", tier: .advanced)
        #expect(generator.rate(twice, of: puzzle) == .expert)
    }
}

@Suite("Hashi hat entegrasyonu")
struct HashiPipelineTests {
    private let pipeline = HashiGenerator.pipeline()
    private let solver = HashiSolver()
    private let rules = HashiRules()

    @Test("Hat benzersiz ve hedef zorlukta bulmaca veriyor", arguments: Difficulty.allCases)
    func pipelineProducesUniquePuzzle(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .hashi, difficulty: difficulty, counter: 1)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

        #expect(puzzle.variant == .hashi)
        #expect(puzzle.difficulty == difficulty)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
        #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
    }

    @Test("Çözücünün bulduğu çözüm üreticinin kurduğuyla aynı", arguments: Difficulty.allCases)
    func solverAgreesWithGenerator(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .hashi, difficulty: difficulty, counter: 9)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)
        let solutions = try solver.findSolutions(of: puzzle.definition, upTo: 2)
        #expect(solutions == [puzzle.solution])
    }

    @Test("Aynı tohum aynı bulmacayı veriyor")
    func sameSeedProducesSamePuzzle() throws {
        let seed = Seed.daily(variant: .hashi, year: 2026, month: 10, day: 22)
        let first = try pipeline.generate(difficulty: .medium, seed: seed)
        let second = try pipeline.generate(difficulty: .medium, seed: seed)
        #expect(first.definition == second.definition)
        #expect(first.solution == second.solution)
        #expect(first.attempts == second.attempts)
    }

    @Test("Farklı tohum farklı bulmaca veriyor")
    func differentSeedProducesDifferentPuzzle() throws {
        let first = try pipeline.generate(difficulty: .medium, seed: 1)
        let second = try pipeline.generate(difficulty: .medium, seed: 2)
        #expect(first.definition != second.definition)
    }
}

@Suite("Hashi üretici — özellik testi")
struct HashiPropertyTests {
    // Brief b.11: "Rastgele 500 bulmaca üret → hepsi benzersiz çözümlü."
    // Zorluk başına 125 bulmaca, dört zorluk = 500. Her biri ayrıca çözücüden geçiriliyor.
    @Test("500 bulmacanın hepsi benzersiz çözümlü ve hedef zorlukta")
    func fiveHundredPuzzlesAreUnique() throws {
        let pipeline = HashiGenerator.pipeline()
        let solver = HashiSolver()
        let rules = HashiRules()
        var produced = 0
        var worstAttempts = 0

        for difficulty in Difficulty.allCases {
            for index in 0..<125 {
                let seed = Seed.free(variant: .hashi, difficulty: difficulty, counter: UInt64(index))
                let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

                let solutions = try solver.findSolutions(of: puzzle.definition, upTo: 2)
                #expect(solutions.count == 1, "Tohum \(seed) benzersiz değil")
                #expect(puzzle.difficulty == difficulty)
                #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))

                worstAttempts = max(worstAttempts, puzzle.attempts)
                produced += 1
            }
        }

        #expect(produced == 500)
        // Deneme sınırına yaklaşıyorsak üretici bozulmaya başlamış demektir; bu sayı
        // ADR 0010'daki ölçümün koruması.
        #expect(worstAttempts < 1500, "En kötü deneme sayısı \(worstAttempts) — sınıra yaklaşıyor")
        print("[hashi] 500 bulmaca üretildi, en kötü deneme sayısı \(worstAttempts)")
    }
}
