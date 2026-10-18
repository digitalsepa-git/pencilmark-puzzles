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

// Varyant üretim performansı — **yalnız release derlemede**.
//
// Eşik, brief b.11'in bütçesinin kendisi: "Expert seviyede iPhone 12'de 2 saniyenin
// altında". Uydurma bir kat değil gerçek ürün kısıtı, çünkü release ölçümünde pay yeterince
// geniş (Hashi 65, Hitori 20, Calcudoku 11 kat).
//
// Debug derlemede koşmuyorlar ve sebebi ölçüm: optimize edilmemiş derlemede Calcudoku
// Expert üretimi CI runner'ında en kötü **6 saniye** alıyor, release'te 200 ms civarı.
// Debug süresi ürün ölçümü değil — eşiği o sayıya göre gevşetmek testi anlamsız kılar,
// sıkı tutmak runner gürültüsüne bağlı kırmızı PR'lar üretir. ADR 0003'ün "CI eşiği gevşek"
// maddesi bu suretle güncellendi: eşik gerçek bütçe, ölçüm release'te.
//
// Cihaz ölçümü yine PR şablonundaki "cihazda denendi" satırıyla raporlanıyor.
#if !DEBUG

@Suite("Performans — Hashi")
struct HashiPerformanceTests {
    private static let budget = Duration.milliseconds(2000)

    @Test("Üretim süresi zorluk başına bütçenin altında", arguments: Difficulty.allCases)
    func generationStaysWithinBudget(difficulty: Difficulty) throws {
        let pipeline = HashiGenerator.pipeline()
        var counter: UInt64 = 0

        let budget = PerformanceBudget(
            name: "Hashi üretim · \(difficulty.rawValue)",
            iterations: 20,
            ceiling: Self.budget
        )

        try budget.measure {
            let seed = Seed.free(variant: .hashi, difficulty: difficulty, counter: counter)
            counter += 1
            _ = try pipeline.generate(difficulty: difficulty, seed: seed)
        }
    }

    @Test("Benzersizlik kontrolü bütçenin küçük bir payını alıyor")
    func uniquenessCheckIsCheap() throws {
        // Kontrol kapatılamaz (brief b.11), o yüzden maliyetinin ölçülmesi gerekiyor:
        // pahalı olduğu ortaya çıkarsa çözüm kapatmak değil algoritmayı değiştirmek.
        let pipeline = HashiGenerator.pipeline()
        let solver = HashiSolver()
        let puzzle = try pipeline.generate(difficulty: .expert, seed: 2026)

        let budget = PerformanceBudget(
            name: "Hashi benzersizlik kontrolü · expert",
            iterations: 50,
            ceiling: .milliseconds(200)
        )

        try budget.measure {
            let outcome = try solver.uniquenessCheck(puzzle.definition)
            #expect(outcome.isUnique)
        }
    }
}

@Suite("Performans — Hitori")
struct HitoriPerformanceTests {
    // Hitori'nin payı Hashi'den dar: Expert'te ölçülen en kötü 93 ms, Hashi'de 31 ms.
    private static let budget = Duration.milliseconds(2000)

    @Test("Üretim süresi zorluk başına bütçenin altında", arguments: Difficulty.allCases)
    func generationStaysWithinBudget(difficulty: Difficulty) throws {
        let pipeline = HitoriGenerator.pipeline()
        var counter: UInt64 = 0

        let budget = PerformanceBudget(
            name: "Hitori üretim · \(difficulty.rawValue)",
            iterations: 20,
            ceiling: Self.budget
        )

        try budget.measure {
            let seed = Seed.free(variant: .hitori, difficulty: difficulty, counter: counter)
            counter += 1
            _ = try pipeline.generate(difficulty: difficulty, seed: seed)
        }
    }

    @Test("Benzersizlik kontrolü bütçenin küçük bir payını alıyor")
    func uniquenessCheckIsCheap() throws {
        let pipeline = HitoriGenerator.pipeline()
        let solver = HitoriSolver()
        let puzzle = try pipeline.generate(difficulty: .expert, seed: 2026)

        let budget = PerformanceBudget(
            name: "Hitori benzersizlik kontrolü · expert",
            iterations: 50,
            ceiling: .milliseconds(300)
        )

        try budget.measure {
            let outcome = try solver.uniquenessCheck(puzzle.definition)
            #expect(outcome.isUnique)
        }
    }
}

@Suite("Performans — Calcudoku")
struct CalcudokuPerformanceTests {
    // Calcudoku üç varyantın en darı: Expert'te ölçülen en kötü 183 ms, yani on bir kat pay.
    private static let budget = Duration.milliseconds(2000)

    @Test("Üretim süresi zorluk başına bütçenin altında", arguments: Difficulty.allCases)
    func generationStaysWithinBudget(difficulty: Difficulty) throws {
        let pipeline = CalcudokuGenerator.pipeline()
        var counter: UInt64 = 0

        let budget = PerformanceBudget(
            name: "Calcudoku üretim · \(difficulty.rawValue)",
            iterations: 20,
            ceiling: Self.budget
        )

        try budget.measure {
            let seed = Seed.free(variant: .calcudoku, difficulty: difficulty, counter: counter)
            counter += 1
            _ = try pipeline.generate(difficulty: difficulty, seed: seed)
        }
    }

    // Derecelendirme Calcudoku'da üretimin en pahalı adımı ve bir kere ölçülmesi gerekiyor:
    // ilk sürümde tek bir 8×8 bulmacanın derecelendirmesi 1.100 ms alıyordu (ADR 0012).
    @Test("Derecelendirme tek bulmacada bütçenin küçük bir payını alıyor")
    func ratingIsCheap() throws {
        let pipeline = CalcudokuGenerator.pipeline()
        let solver = CalcudokuSolver()
        let puzzle = try pipeline.generate(difficulty: .expert, seed: 4242)

        let budget = PerformanceBudget(
            name: "Calcudoku derecelendirme · expert",
            iterations: 10,
            ceiling: .milliseconds(400)
        )

        try budget.measure {
            _ = try solver.trace(of: puzzle.definition)
        }
    }
}

#endif
