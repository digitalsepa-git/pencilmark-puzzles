import Testing
import PuzzleKit

@Suite("Üretim hattı")
struct GenerationPipelineTests {
    private let pipeline = GenerationPipeline(generator: MiniLatinGenerator())
    private let solver = MiniLatinSolver()

    @Test("Hat yalnızca benzersiz çözümlü bulmaca döndürür", arguments: Difficulty.allCases)
    func generatedPuzzleIsAlwaysUnique(difficulty: Difficulty) throws {
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: 42)
        let solutions = try solver.findSolutions(of: puzzle.definition, upTo: 2)
        #expect(solutions.count == 1)
        #expect(solutions[0] == puzzle.solution)
        #expect(puzzle.difficulty == difficulty)
    }

    @Test("Çözüm, verilen hücrelerle tutarlı", arguments: Difficulty.allCases)
    func solutionAgreesWithGivens(difficulty: Difficulty) throws {
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: 7)
        for position in puzzle.definition.givens.allPositions {
            if let given = puzzle.definition.givens[position] {
                #expect(puzzle.solution[position] == given)
            }
        }
    }

    @Test("Aynı tohum aynı bulmacayı verir")
    func sameSeedProducesSamePuzzle() throws {
        let first = try pipeline.generate(difficulty: .medium, seed: 2026_10_19)
        let second = try pipeline.generate(difficulty: .medium, seed: 2026_10_19)
        #expect(first.definition == second.definition)
        #expect(first.solution == second.solution)
        #expect(first.attempts == second.attempts)
    }

    @Test("Farklı tohum farklı bulmaca verir")
    func differentSeedProducesDifferentPuzzle() throws {
        let first = try pipeline.generate(difficulty: .medium, seed: 1)
        let second = try pipeline.generate(difficulty: .medium, seed: 2)
        #expect(first.definition != second.definition)
    }

    // Hattın karar adımı gerçekten kapı mı? Her zaman çok çözümlü aday üreten bozuk
    // üreticiyle hat hiçbir şey döndürmemeli. Bu test, benzersizlik kontrolünün
    // "performans gerekçesiyle kapatılamaz" olmasının (brief b.11) kanıtı.
    @Test("Çok çözümlü adaylar elenir, hat bulmaca döndürmez")
    func ambiguousCandidatesAreRejected() {
        let broken = GenerationPipeline(generator: AmbiguousGenerator(), maxAttempts: 5)
        #expect(throws: GenerationError.self) {
            _ = try broken.generate(difficulty: .easy, seed: 1)
        }
    }

    @Test("Elenme sebepleri hatada raporlanır")
    func rejectionReasonsAreReported() throws {
        let broken = GenerationPipeline(generator: AmbiguousGenerator(), maxAttempts: 4)
        do {
            _ = try broken.generate(difficulty: .easy, seed: 1)
            Issue.record("Hat bulmaca döndürmemeliydi")
        } catch let error as GenerationError {
            guard case .attemptsExhausted(_, _, let attempts, _, let ambiguous, _, _, _, _) = error else {
                Issue.record("Beklenmeyen hata: \(error)")
                return
            }
            #expect(attempts == 4)
            #expect(ambiguous == 4)
        }
    }
}

@Suite("Üretim hattı — özellik testi")
struct GenerationPropertyTests {
    // Brief b.11: "Rastgele 500 bulmaca üret → hepsi benzersiz çözümlü."
    // Zorluk başına 125 bulmaca, dört zorluk = 500.
    @Test("500 bulmacanın hepsi benzersiz çözümlü ve hedef zorlukta")
    func fiveHundredPuzzlesAreAllUnique() throws {
        let pipeline = GenerationPipeline(generator: MiniLatinGenerator())
        let solver = MiniLatinSolver()
        var produced = 0

        for difficulty in Difficulty.allCases {
            for index in 0..<125 {
                let seed = Seed.free(variant: .calcudoku, difficulty: difficulty, counter: UInt64(index))
                let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)
                let solutions = try solver.findSolutions(of: puzzle.definition, upTo: 2)
                #expect(solutions.count == 1, "Tohum \(seed) benzersiz değil")
                #expect(puzzle.difficulty == difficulty)
                produced += 1
            }
        }

        #expect(produced == 500)
    }
}
