import Testing
import PuzzleKit

@Suite("Hitori çözücü")
struct HitoriSolverTests {
    private let solver = HitoriSolver()
    private let rules = HitoriRules()

    @Test("Çözümü olmayan en küçük bulmaca eleniyor")
    func impossiblePuzzleHasNoSolution() throws {
        let puzzle = HitoriFixture.impossible2x2
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).isEmpty)
        let outcome = try solver.uniquenessCheck(puzzle)
        if case .none = outcome {} else {
            Issue.record("Beklenen .none, gelen \(outcome)")
        }
    }

    // Klasik "üçlü" kuralı: yan yana üç aynı sayıda ortadaki beyaz, dıştakiler karalı.
    // Çözücü bunu ayrı bir kural olarak değil, komşuluk + grup kısıtlarının birleşiminden
    // çıkarıyor — bu test o çıkarımı koruyor.
    @Test("Yan yana üç aynı sayıda ortadaki beyaz, dıştakiler karalı")
    func tripleRuleIsForced() throws {
        let puzzle = HitoriFixture.triple3x5
        let solutions = try solver.findSolutions(of: puzzle, upTo: 10)
        #expect(!solutions.isEmpty)

        for solution in solutions {
            #expect(solution.shaded[0, 1], "Soldaki üçlü üyesi karalı olmalı")
            #expect(!solution.shaded[0, 2], "Ortadaki üçlü üyesi beyaz olmalı")
            #expect(solution.shaded[0, 3], "Sağdaki üçlü üyesi karalı olmalı")
        }
    }

    @Test("Amaçlanan çözüm bulunanlar arasında")
    func intendedSolutionIsFound() throws {
        let puzzle = HitoriFixture.handmade4x4
        let solutions = try solver.findSolutions(of: puzzle, upTo: 10)

        var intended = HitoriBoard(puzzle)
        for position in [pos(0, 0), pos(1, 2), pos(3, 3)] {
            intended[position] = .shaded
        }
        #expect(solutions.contains(intended.solution()))
    }

    // Hitori'de karalı hücrenin tekrar olması zorunlu değil: kurallar yalnız beyazlarda
    // tekrarı yasaklıyor. Yani hiçbir gruba girmeyen bir hücre, komşuluk ve bağlılık izin
    // verdiği sürece serbestçe karalanabilir ve bulmaca çok çözümlü olur. Benzersizlik
    // bu yüzden değerlerden değil karalama deseninin sıkılığından geliyor (ADR 0011).
    @Test("Gruba girmeyen hücreler serbest kalırsa bulmaca çok çözümlü")
    func looseCellsMakePuzzleAmbiguous() throws {
        let puzzle = HitoriFixture.handmade4x4
        let solutions = try solver.findSolutions(of: puzzle, upTo: 10)
        #expect(solutions.count > 1)

        let outcome = try solver.uniquenessCheck(puzzle)
        if case .multiple = outcome {} else {
            Issue.record("Beklenen .multiple, gelen \(outcome)")
        }
    }

    @Test("Dönen her çözüm kural doğrulayıcıdan geçiyor")
    func everySolutionSatisfiesRules() throws {
        for puzzle in [HitoriFixture.handmade4x4, HitoriFixture.triple3x5] {
            for solution in try solver.findSolutions(of: puzzle, upTo: 10) {
                #expect(rules.isSolved(solution.board(), in: puzzle))
            }
        }
    }

    @Test("Çözüm sayısı sınırına uyuluyor")
    func solutionLimitIsRespected() throws {
        let puzzle = HitoriFixture.handmade4x4
        #expect(try solver.findSolutions(of: puzzle, upTo: 1).count == 1)
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).count == 2)
        #expect(try solver.findSolutions(of: puzzle, upTo: 0).isEmpty)
    }

    @Test("Arama deterministik")
    func searchIsDeterministic() throws {
        let puzzle = HitoriFixture.handmade4x4
        let first = try solver.findSolutions(of: puzzle, upTo: 10)
        let second = try solver.findSolutions(of: puzzle, upTo: 10)
        #expect(first == second)
    }

    @Test("Teknik seviyesi zorluk eşlemesi ortak çerçeveden geliyor")
    func traceReportsTier() throws {
        let trace = try solver.trace(of: HitoriFixture.triple3x5)
        #expect(trace.techniques.contains("basic"))
        // Serbest hücreler yüzünden bulmaca mantıkla kapanmıyor.
        #expect(trace.highestTier == .guessing)
    }
}
