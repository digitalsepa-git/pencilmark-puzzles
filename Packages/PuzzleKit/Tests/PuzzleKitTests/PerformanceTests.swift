import Testing
import PuzzleKit

@Suite("Performans")
struct PerformanceTests {
    @Test("Üretim süresi zorluk başına ölçülür", arguments: Difficulty.allCases)
    func generationStaysWithinCeiling(difficulty: Difficulty) throws {
        let pipeline = GenerationPipeline(generator: MiniLatinGenerator())
        var counter: UInt64 = 0

        let budget = PerformanceBudget(
            name: "MiniLatin üretim · \(difficulty.rawValue)",
            iterations: 25,
            ceiling: .milliseconds(200)
        )

        try budget.measure {
            let seed = Seed.free(variant: .calcudoku, difficulty: difficulty, counter: counter)
            counter += 1
            _ = try pipeline.generate(difficulty: difficulty, seed: seed)
        }
    }

    @Test("Benzersizlik kontrolü iki çözümde durur")
    func uniquenessCheckStopsAtTwoSolutions() throws {
        // Boş 4×4'ün 576 çözümü var. Kontrol ikinci çözümde durmazsa tümünü sayar;
        // bu test o erken çıkışın yerinde durduğunu süreyle doğruluyor.
        let solver = MiniLatinSolver()
        let empty = MiniLatinDefinition(
            side: 4,
            givens: Grid(size: GridSize(square: 4), repeating: nil)
        )

        let budget = PerformanceBudget(
            name: "Benzersizlik kontrolü · boş 4×4",
            iterations: 50,
            ceiling: .milliseconds(50)
        )

        try budget.measure {
            let outcome = try solver.uniquenessCheck(empty)
            #expect(!outcome.isUnique)
        }

        let all = try solver.findSolutions(of: empty, upTo: .max)
        #expect(all.count == 576, "4×4 Latin karesi sayısı 576 olmalı")
    }
}
