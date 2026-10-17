import Testing
import PuzzleKit

@Suite("Hashi çözücü")
struct HashiSolverTests {
    private let solver = HashiSolver()
    private let rules = HashiRules()

    // MARK: - Bilinen bulmaca, bilinen çözüm (brief b.11 çözücü katmanı)

    @Test("İki ada arasındaki köprü sayısı dereceden çıkıyor")
    func pairIsForcedByDegree() throws {
        #expect(try solver.findSolutions(of: HashiFixture.parse("1 . 1"), upTo: 2).map(\.counts) == [[1]])
        #expect(try solver.findSolutions(of: HashiFixture.parse("2 . 2"), upTo: 2).map(\.counts) == [[2]])
    }

    @Test("Zincirde orta ada iki yana birer köprü veriyor")
    func chainSplitsBridges() throws {
        let solutions = try solver.findSolutions(of: HashiFixture.parse("1 . 2 . 1"), upTo: 2)
        #expect(solutions.map(\.counts) == [[1, 1]])
    }

    @Test("Kare döngünün tek çözümü var ve bütün kenarlarda birer köprü")
    func loopHasSingleSolution() throws {
        let puzzle = HashiFixture.loop3x3
        let solutions = try solver.findSolutions(of: puzzle, upTo: 5)
        #expect(solutions.count == 1)
        #expect(solutions[0].counts == [1, 1, 1, 1])
    }

    // Bu testin anlamı: yalnız derecelere bakan bir çözücü burada iki çözüm daha bulur
    // (karşılıklı iki kenara çifte köprü). İkisi de ağı ikiye ayırıyor ve bağlılık kısıtı
    // onları eliyor. Kısıt kaldırılırsa bu test kırılır.
    @Test("Dereceleri tutan ama ağı ayıran dizilimler eleniyor")
    func disconnectedAssignmentsAreRejected() throws {
        let puzzle = HashiFixture.loop3x3
        let solutions = try solver.findSolutions(of: puzzle, upTo: 10)
        #expect(solutions.count == 1)

        // Elenen dizilimlerden biri: üst ve alt kenarda çifte köprü, dikeyler boş.
        let split = HashiBoard(counts: [2, 2, 0, 0])
        #expect(rules.degreesAreComplete(split, in: puzzle))
        #expect(!rules.isSolved(split, in: puzzle))
    }

    // MARK: - Negatif durumlar

    @Test("Kesişmek zorunda kalan bulmacanın çözümü yok")
    func crossingPuzzleHasNoSolution() throws {
        let puzzle = HashiFixture.crossing5x5
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).isEmpty)
        let outcome = try solver.uniquenessCheck(puzzle)
        #expect(outcome.isUnique == false)
        if case .none = outcome {} else {
            Issue.record("Beklenen .none, gelen \(outcome)")
        }
    }

    @Test("Derecesi komşularının verebileceğinden küçük ada çelişki")
    func impossibleDegreeHasNoSolution() throws {
        #expect(try solver.findSolutions(of: HashiFixture.impossiblePlus5x5, upTo: 2).isEmpty)
    }

    @Test("Çok çözümlü bulmaca multiple olarak işaretleniyor")
    func ambiguousPuzzleIsMultiple() throws {
        let puzzle = HashiFixture.ambiguous5x5
        let solutions = try solver.findSolutions(of: puzzle, upTo: 5)
        #expect(solutions.count > 1)

        let outcome = try solver.uniquenessCheck(puzzle)
        if case .multiple = outcome {} else {
            Issue.record("Beklenen .multiple, gelen \(outcome)")
        }
    }

    // MARK: - Sözleşme

    @Test("Çözüm sayısı sınırına uyuluyor")
    func solutionLimitIsRespected() throws {
        let puzzle = HashiFixture.ambiguous5x5
        #expect(try solver.findSolutions(of: puzzle, upTo: 1).count == 1)
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).count == 2)
        #expect(try solver.findSolutions(of: puzzle, upTo: 0).isEmpty)
    }

    @Test("Dönen her çözüm kural doğrulayıcıdan geçiyor")
    func everySolutionSatisfiesRules() throws {
        for puzzle in [HashiFixture.loop3x3, HashiFixture.ambiguous5x5] {
            for solution in try solver.findSolutions(of: puzzle, upTo: 5) {
                #expect(rules.isSolved(solution.board(), in: puzzle))
            }
        }
    }

    @Test("Arama deterministik: aynı bulmaca aynı sırayla aynı çözümleri veriyor")
    func searchIsDeterministic() throws {
        let puzzle = HashiFixture.ambiguous5x5
        let first = try solver.findSolutions(of: puzzle, upTo: 5).map(\.counts)
        let second = try solver.findSolutions(of: puzzle, upTo: 5).map(\.counts)
        #expect(first == second)
    }
}

@Suite("Hashi teknik seviyeleri")
struct HashiTechniqueTests {
    private let solver = HashiSolver()

    @Test("Dereceden doğrudan çıkan bulmaca temel seviyede")
    func forcedPuzzleIsBasic() throws {
        let trace = try solver.trace(of: HashiFixture.parse("1 . 2 . 1"))
        #expect(trace.highestTier == .basic)
        #expect(trace.difficulty == .easy)
        #expect(trace.techniques.contains("islandSum"))
    }

    // Kare döngüde hiçbir temel teknik ilerlemiyor: her kenarın üç değeri de derece
    // kısıtına uyuyor. İlerlemenin tek yolu varsayım — "üst kenara çifte köprü koyarsam
    // ağ ikiye ayrılır, demek ki koyamam". Bu yüzden ileri seviye.
    @Test("Kare döngü ileri seviye: ilerlemek için varsayım gerekiyor")
    func loopNeedsHypothesis() throws {
        let trace = try solver.trace(of: HashiFixture.loop3x3)
        #expect(trace.highestTier == .advanced)
        #expect(trace.difficulty == .hard)
        #expect(trace.techniques.contains("hypothesis"))
    }

    @Test("Mantıkla kapanmayan bulmaca guessing olarak işaretleniyor")
    func unresolvablePuzzleIsGuessing() throws {
        // Çok çözümlü bulmaca mantıkla kapanamaz: hangi çözüm olduğu çıkarımla bulunamıyor.
        let trace = try solver.trace(of: HashiFixture.ambiguous5x5)
        #expect(trace.highestTier == .guessing)
        #expect(trace.difficulty == .expert)
        #expect(trace.techniques.contains("search"))
    }

    @Test("Teknik seviyesi zorluk eşlemesi ADR 0005'teki gibi")
    func tierMapsToDifficulty() {
        #expect(TechniqueTier.basic.difficulty == .easy)
        #expect(TechniqueTier.intermediate.difficulty == .medium)
        #expect(TechniqueTier.advanced.difficulty == .hard)
        #expect(TechniqueTier.guessing.difficulty == .expert)
    }
}
