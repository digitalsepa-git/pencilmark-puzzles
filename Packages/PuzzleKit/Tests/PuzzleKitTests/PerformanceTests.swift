import Testing
import PuzzleKit

@Suite("Performans", .serialized)
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

// Varyant üretim performansı — **yalnız release derlemede, seri koşuyor**.
//
// `.serialized`: paralel yük altında yapılan süre ölçümü anlamsız. Kakuro Expert ölçümünde
// görüldü — tek başına 720 ms olan üretim, diğer testlerle birlikte koşunca 2.606 ms'ye
// çıkıyor. CI'da performans adımı özellik testlerinden ayrı koşuyor (bkz. ci.yml).
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

@Suite("Performans — Hashi", .serialized)
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

@Suite("Performans — Hitori", .serialized)
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

@Suite("Performans — Calcudoku", .serialized)
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

@Suite("Performans — Kakuro", .serialized)
struct KakuroPerformanceTests {
    // Kakuro dört varyantın en darı: Expert'te ölçülen en kötü 961 ms, yani iki kat pay
    // (Hashi 65, Hitori 20, Calcudoku 11). Eşik yine gerçek bütçe — payın darlığı ADR
    // 0013'te risk olarak yazılı ve Faz 3'teki cihaz ölçümü asıl kapı.
    private static let budget = Duration.milliseconds(2000)

    @Test("Üretim süresi zorluk başına bütçenin altında", arguments: Difficulty.allCases)
    func generationStaysWithinBudget(difficulty: Difficulty) throws {
        let pipeline = KakuroGenerator.pipeline()
        var counter: UInt64 = 0

        let budget = PerformanceBudget(
            name: "Kakuro üretim · \(difficulty.rawValue)",
            iterations: 10,
            ceiling: Self.budget
        )

        try budget.measure {
            let seed = Seed.free(variant: .kakuro, difficulty: difficulty, counter: counter)
            counter += 1
            _ = try pipeline.generate(difficulty: difficulty, seed: seed)
        }
    }

    // Temel seviyedeki bulmaca mantıkla kapanıyor, yani benzersizlik kontrolü aramaya hiç
    // inmiyor — bütçe sıfır olsa bile çözülüyor. Bu testin işi o kestirmenin yerinde
    // durduğunu korumak: kaybolursa kontrol saniyelere çıkar (ADR 0013).
    //
    // İleri seviyedeki bulmacalar için aynı şey geçerli değil ve bu bilinçli: onlar sınırlı
    // aramayla kabul ediliyor, çünkü varsayım tekniğini kabul kapısında kullanmak Kakuro'nun
    // boyutlarında saniyelere çıkıyor.
    @Test("Temel seviyede benzersizlik kontrolü aramaya inmiyor")
    func uniquenessCheckStaysInPropagation() throws {
        let pipeline = KakuroGenerator.pipeline()
        let puzzle = try pipeline.generate(difficulty: .easy, seed: 7)
        let budgetless = KakuroSolver(searchNodeBudget: 0)

        let budget = PerformanceBudget(
            name: "Kakuro benzersizlik kontrolü · easy",
            iterations: 20,
            ceiling: .milliseconds(100)
        )

        try budget.measure {
            let outcome = try budgetless.uniquenessCheck(puzzle.definition)
            #expect(outcome.isUnique)
        }
    }
}

@Suite("Performans — Slitherlink", .serialized)
struct SlitherlinkPerformanceTests {
    // Ölçülen en kötü 180 ms (Expert, 12×12), yani 11 kat pay — Calcudoku ile aynı sınıf.
    // Eşik yine briefin gerçek bütçesi, ölçülen değerin biraz üstü değil: testin işi
    // bütçeyi korumak, ölçümü dondurmak değil.
    private static let budget = Duration.milliseconds(2000)

    @Test("Üretim süresi zorluk başına bütçenin altında", arguments: Difficulty.allCases)
    func generationStaysWithinBudget(difficulty: Difficulty) throws {
        let pipeline = SlitherlinkGenerator.pipeline()
        var counter: UInt64 = 0

        let budget = PerformanceBudget(
            name: "Slitherlink üretim · \(difficulty.rawValue)",
            iterations: 10,
            ceiling: Self.budget
        )

        try budget.measure {
            let seed = Seed.free(variant: .slitherlink, difficulty: difficulty, counter: counter)
            counter += 1
            _ = try pipeline.generate(difficulty: difficulty, seed: seed)
        }
    }

    // Kakuro'nun aynı testi yalnız Easy'yi kapsıyor; Slitherlink'te dört zorluk da
    // kapsanıyor, çünkü burada "yayılım kapatmıyorsa aday reddedilir" üreticinin kabul
    // kuralı. Bu test o kuralın bütün merdivende durduğunu koruyor: kaybolursa benzersizlik
    // kontrolü aramaya iner ve 12×12'de saniyelere çıkar.
    @Test("Benzersizlik kontrolü hiçbir zorlukta aramaya inmiyor", arguments: Difficulty.allCases)
    func uniquenessCheckStaysInPropagation(difficulty: Difficulty) throws {
        let pipeline = SlitherlinkGenerator.pipeline()
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: 9)
        let budgetless = SlitherlinkSolver(searchNodeBudget: 0)

        let budget = PerformanceBudget(
            name: "Slitherlink benzersizlik kontrolü · \(difficulty.rawValue)",
            iterations: 20,
            ceiling: .milliseconds(100)
        )

        try budget.measure {
            let outcome = try budgetless.uniquenessCheck(puzzle.definition)
            #expect(outcome.isUnique)
        }
    }
}

#endif
