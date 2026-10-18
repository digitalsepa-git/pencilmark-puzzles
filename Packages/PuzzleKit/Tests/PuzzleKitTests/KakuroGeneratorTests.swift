import Testing
import PuzzleKit

// Üretici henüz benzersiz bulmaca üretmiyor (ADR 0013). Bu testler ürettiğinin *geçerli*
// olduğunu doğruluyor — desen kuralları, kesit içi tekrarsızlık, toplam tutarlılığı. Yani
// benzersizlik dışındaki her şey yerinde ve desen tasarımı düzeltildiğinde (#26) bu testler
// o düzeltmenin bir şeyi bozmadığının güvencesi olacak.
@Suite("Kakuro üretici")
struct KakuroGeneratorTests {
    // Onarım döngüsü kapalı (repairLimit 1): bu testler geçerliliği ölçüyor, benzersizliği
    // değil, ve onarım turları testleri gereksiz yavaşlatıyor.
    private let generator = KakuroGenerator(
        solver: KakuroSolver(searchNodeBudget: 200),
        repairLimit: 1
    )
    private let rules = KakuroRules()

    @Test("Kurulan çözüm bütün kesit toplamlarını tutuyor", arguments: Difficulty.allCases)
    func builtSolutionSatisfiesRules(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 515)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        #expect(rules.isSolved(built.solution.board(), in: built.puzzle))
        #expect(rules.violations(on: built.solution.board(), in: built.puzzle).isEmpty)
    }

    @Test("Bütün kesitler 2-9 uzunluğunda", arguments: Difficulty.allCases)
    func everyRunHasLegalLength(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 616)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        for run in built.puzzle.runs {
            #expect((2...9).contains(run.length), "Kesit uzunluğu \(run.length)")
        }
    }

    @Test("Her giriş hücresi bir yatay ve bir dikey kesite ait", arguments: Difficulty.allCases)
    func everyEntryBelongsToTwoRuns(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 717)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        for cell in built.puzzle.entryCells {
            #expect(built.puzzle.runsOfCell[cell].count == 2)
        }
    }

    @Test("Her kesitte rakamlar tekrarsız", arguments: Difficulty.allCases)
    func runsHaveDistinctDigits(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 818)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        for run in built.puzzle.runs {
            let values = run.cells.map { built.solution.values.elements[$0] }
            #expect(Set(values).count == values.count, "Kesitte tekrar: \(values)")
        }
    }

    @Test("Izgara boyutları ADR 0005'teki tablodan")
    func layoutSizesFollowDecisionRecord() {
        #expect(KakuroLayout.standard(for: .easy).side == 8)
        #expect(KakuroLayout.standard(for: .medium).side == 10)
        #expect(KakuroLayout.standard(for: .hard).side == 12)
        #expect(KakuroLayout.standard(for: .expert).side == 14)
    }

    @Test("Aynı tohum aynı bulmacayı veriyor")
    func sameSeedProducesSamePuzzle() throws {
        var first = SeededGenerator(seed: 2026)
        var second = SeededGenerator(seed: 2026)
        let left = try generator.candidate(difficulty: .easy, using: &first)
        let right = try generator.candidate(difficulty: .easy, using: &second)
        #expect(left.puzzle == right.puzzle)
        #expect(left.solution == right.solution)
    }

    @Test("Farklı tohum farklı bulmaca veriyor")
    func differentSeedProducesDifferentPuzzle() throws {
        var first = SeededGenerator(seed: 1)
        var second = SeededGenerator(seed: 2)
        let left = try generator.candidate(difficulty: .easy, using: &first)
        let right = try generator.candidate(difficulty: .easy, using: &second)
        #expect(left.puzzle != right.puzzle)
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
