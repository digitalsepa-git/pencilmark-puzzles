import Testing
import PuzzleKit

@Suite("Kakuro üretici")
struct KakuroGeneratorTests {
    private let generator = KakuroGenerator()
    private let rules = KakuroRules()

    // Bulmacalar hat üzerinden alınıyor, üreticiden doğrudan değil. Sebebi tasarım: üretici
    // hedef zorluğu kendi yönlendirme döngüsünde arıyor ve bulamadığında `attemptFailed`
    // atıyor — bu bir hata değil normal bir sonuç, hattın başka bir tohumla yeniden
    // denemesi gereken durum. Tek tohumla doğrudan çağırmak testi tohum şansına bağlar.
    private func puzzle(
        _ difficulty: Difficulty,
        seed: UInt64 = 515
    ) throws -> GeneratedPuzzle<KakuroPuzzle, KakuroSolution> {
        try KakuroGenerator.pipeline(generator).generate(difficulty: difficulty, seed: seed)
    }

    // Dört yapısal koşul tek bulmaca üretimiyle kontrol ediliyor. Ayrı testler daha
    // okunaklı olurdu ama her biri yeniden üretim demek ve Kakuro üretimi debug derlemede
    // pahalı — dört test yerine bir test, debug koşusunu 27 saniyeden 8 saniyeye indiriyor.
    @Test("Üretilen bulmaca yapısal olarak geçerli", arguments: Difficulty.allCases)
    func generatedPuzzleIsStructurallyValid(difficulty: Difficulty) throws {
        let built = try puzzle(difficulty)

        #expect(rules.isSolved(built.solution.board(), in: built.definition))
        #expect(rules.violations(on: built.solution.board(), in: built.definition).isEmpty)

        for run in built.definition.runs {
            #expect((2...9).contains(run.length), "Kesit uzunluğu \(run.length)")
            let values = run.cells.map { built.solution.values.elements[$0] }
            #expect(Set(values).count == values.count, "Kesitte tekrar: \(values)")
        }

        for cell in built.definition.entryCells {
            #expect(built.definition.runsOfCell[cell].count == 2)
        }
    }

    // ADR 0005'in Kakuro boyutları ölçüm öncesi tahmindi (8/10/12/14); ADR 0013 ile
    // ölçüme göre güncellendi. Expert 14×14'te üretim bütçeyi aşıyordu.
    @Test("Izgara boyutları ADR 0013'teki ölçülmüş tablodan")
    func layoutSizesFollowDecisionRecord() {
        #expect(KakuroLayout.standard(for: .easy).side == 8)
        #expect(KakuroLayout.standard(for: .medium).side == 10)
        #expect(KakuroLayout.standard(for: .hard).side == 10)
        #expect(KakuroLayout.standard(for: .expert).side == 11)
    }

    // Benzersizliğin dayanağı: doldurma, kesitlerin bileşim sayısı toplamını küçültecek
    // şekilde eniyileniyor. Rastgele doldurmada bu maliyet yüksek ve bulmaca çok çözümlü
    // çıkıyor (ADR 0013: 1.160 adayda sıfır benzersiz).
    @Test("Eniyileme bileşim maliyetini belirgin şekilde düşürüyor")
    func optimizationReducesCombinationCost() throws {
        var rng = SeededGenerator(seed: 4242)
        let layout = KakuroLayout.standard(for: .easy)
        guard let pattern = KakuroGenerator.pattern(for: layout, using: &rng),
              let raw = KakuroGenerator.fill(pattern: pattern, using: &rng)
        else {
            Issue.record("Desen ya da doldurma kurulamadı")
            return
        }

        let before = KakuroGenerator.combinationCost(raw, pattern: pattern)
        var optimized = raw
        KakuroGenerator.optimizeFill(
            &optimized, pattern: pattern, iterations: 4000, using: &rng
        )
        let after = KakuroGenerator.combinationCost(optimized, pattern: pattern)

        #expect(after < before / 2, "Maliyet \(before) → \(after); yarıya inmesi bekleniyor")
    }

    @Test("Eniyileme kesit içi tekrarsızlığı bozmuyor")
    func optimizationKeepsRunsDistinct() throws {
        var rng = SeededGenerator(seed: 909)
        let layout = KakuroLayout.standard(for: .medium)
        guard let pattern = KakuroGenerator.pattern(for: layout, using: &rng),
              var digits = KakuroGenerator.fill(pattern: pattern, using: &rng)
        else {
            Issue.record("Desen ya da doldurma kurulamadı")
            return
        }
        KakuroGenerator.optimizeFill(
            &digits, pattern: pattern, iterations: 2000, using: &rng
        )

        for segment in KakuroGenerator.segments(of: pattern) {
            let values = segment.map { digits.elements[$0] }
            #expect(Set(values).count == values.count, "Kesitte tekrar: \(values)")
        }
    }

    // ADR 0013'ün ilk teşhisi: dört kesidi de 2 hücreli olan 2×2 blok, ızgaranın geri
    // kalanından kopuk ve bir serbestlik derecesi bırakıyor. Teşhis eksik çıktı (asıl sorun
    // toplamlardaydı) ama ceza yerinde kaldı — desen aramasının ürettiği desenlerde kapalı
    // blok yok.
    @Test("Üretilen desenlerde kapalı 2×2 blok yok", arguments: Difficulty.allCases)
    func patternsAvoidClosedBlocks(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 31337)
        let layout = KakuroLayout.standard(for: difficulty)
        guard let pattern = KakuroGenerator.pattern(for: layout, using: &rng) else {
            Issue.record("Desen kurulamadı")
            return
        }
        #expect(KakuroGenerator.closedBlockCount(pattern) == 0)
        #expect(KakuroGenerator.patternPenalty(pattern) == 0)
    }

    @Test("Desen ihlal ölçütü tek hücreli ve dokuzdan uzun kesitleri sayıyor")
    func patternPenaltyCountsViolations() {
        // 4×4 tamamen beyaz: sekiz kesit, hepsi dört uzunluğunda, ihlal yok.
        var mask = Grid(size: GridSize(square: 4), repeating: false)
        #expect(KakuroGenerator.violationPenalty(mask) == 0)

        // (1,1) siyahlanınca hem satır hem sütun tek hücreli bir parça doğuruyor: iki ihlal.
        mask[1, 1] = true
        #expect(KakuroGenerator.violationPenalty(mask) == 2)

        // 12×12 tamamen beyaz: 24 kesit, her biri on iki uzunluğunda, her biri üç fazla.
        let long = Grid(size: GridSize(square: 12), repeating: false)
        #expect(KakuroGenerator.violationPenalty(long) == 24 * 3)
    }
}

@Suite("Kakuro arama bütçesi")
struct KakuroSearchBudgetTests {
    // Benzersizliği kanıtlanamamış bulmaca kullanıcıya verilmiyor: brief b.11'in garantisi
    // "benzersiz olduğunu doğruladık" demek, "muhtemelen benzersiz" demek değil.
    @Test("Bütçe tükendiğinde sonuç belirsiz, sessizce benzersiz sayılmıyor")
    func exhaustedBudgetYieldsIndeterminate() throws {
        let tight = KakuroSolver(searchNodeBudget: 1)
        let outcome = try tight.uniquenessCheck(KakuroFixture.ambiguous3x3)
        #expect(outcome.isIndeterminate)
        #expect(!outcome.isUnique)
    }

    @Test("Mantıkla kapanan bulmaca bütçe harcamıyor")
    func logicSolvablePuzzleNeedsNoSearch() throws {
        // Bütçe 0 olsa bile çözülüyor: yayılım bütün hücreleri kesinleştiriyor ve
        // yayılım sağlam olduğu için o tek çözüm demektir.
        let budgetless = KakuroSolver(searchNodeBudget: 0)
        let solutions = try budgetless.findSolutions(of: KakuroFixture.unique2x2, upTo: 2)
        #expect(solutions == [KakuroFixture.unique2x2Solution])
    }
}

@Suite("Kakuro hat entegrasyonu")
struct KakuroPipelineTests {
    private let pipeline = KakuroGenerator.pipeline()
    private let solver = KakuroSolver()
    private let rules = KakuroRules()

    @Test("Hat benzersiz ve hedef zorlukta bulmaca veriyor", arguments: Difficulty.allCases)
    func pipelineProducesUniquePuzzle(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .kakuro, difficulty: difficulty, counter: 4)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

        #expect(puzzle.variant == .kakuro)
        #expect(puzzle.difficulty == difficulty)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
        #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
    }

    @Test("Çözücünün bulduğu çözüm üreticinin kurduğuyla aynı", arguments: Difficulty.allCases)
    func solverAgreesWithGenerator(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .kakuro, difficulty: difficulty, counter: 12)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2) == [puzzle.solution])
    }

    @Test("Aynı tohum aynı bulmacayı veriyor")
    func sameSeedProducesSamePuzzle() throws {
        let seed = Seed.daily(variant: .kakuro, year: 2026, month: 10, day: 19)
        let first = try pipeline.generate(difficulty: .easy, seed: seed)
        let second = try pipeline.generate(difficulty: .easy, seed: seed)
        #expect(first.definition == second.definition)
        #expect(first.solution == second.solution)
    }

    @Test("Farklı tohum farklı bulmaca veriyor")
    func differentSeedProducesDifferentPuzzle() throws {
        let first = try pipeline.generate(difficulty: .easy, seed: 41)
        let second = try pipeline.generate(difficulty: .easy, seed: 42)
        #expect(first.definition != second.definition)
    }
}
