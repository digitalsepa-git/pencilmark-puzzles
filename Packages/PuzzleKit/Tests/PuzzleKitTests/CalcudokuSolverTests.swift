import Testing
import PuzzleKit

@Suite("Calcudoku çözücü")
struct CalcudokuSolverTests {
    private let solver = CalcudokuSolver()
    private let rules = CalcudokuRules()

    @Test("Elle kurulan bulmacanın tek çözümü var ve beklenen çözüm")
    func handmadePuzzleHasKnownUniqueSolution() throws {
        let puzzle = CalcudokuFixture.handmade4x4
        let solutions = try solver.findSolutions(of: puzzle, upTo: 5)
        #expect(solutions == [CalcudokuFixture.handmade4x4Solution])
    }

    @Test("Hedefi ulaşılamaz kafes çözümü engelliyor")
    func impossibleCageHasNoSolution() throws {
        let puzzle = CalcudokuFixture.impossible4x4
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).isEmpty)
        let outcome = try solver.uniquenessCheck(puzzle)
        if case .none = outcome {} else {
            Issue.record("Beklenen .none, gelen \(outcome)")
        }
    }

    // Her kafes bir satır ve hedefi 1+2+3+4 olduğunda kafes kısıtı hiçbir şey söylemiyor:
    // bütün Latin kareleri geçerli. Benzersizliğin kafes yapısından geldiğinin testi.
    @Test("Kafes kısıtı bilgi taşımadığında bulmaca çok çözümlü")
    func uninformativeCagesMakePuzzleAmbiguous() throws {
        let puzzle = CalcudokuFixture.ambiguous4x4
        #expect(try solver.findSolutions(of: puzzle, upTo: 5).count == 5)

        let outcome = try solver.uniquenessCheck(puzzle)
        if case .multiple = outcome {} else {
            Issue.record("Beklenen .multiple, gelen \(outcome)")
        }
    }

    @Test("Dönen her çözüm kural doğrulayıcıdan geçiyor")
    func everySolutionSatisfiesRules() throws {
        for puzzle in [CalcudokuFixture.handmade4x4, CalcudokuFixture.ambiguous4x4] {
            for solution in try solver.findSolutions(of: puzzle, upTo: 5) {
                #expect(rules.isSolved(solution.board(), in: puzzle))
            }
        }
    }

    @Test("Çözüm sayısı sınırına uyuluyor")
    func solutionLimitIsRespected() throws {
        let puzzle = CalcudokuFixture.ambiguous4x4
        #expect(try solver.findSolutions(of: puzzle, upTo: 1).count == 1)
        #expect(try solver.findSolutions(of: puzzle, upTo: 3).count == 3)
        #expect(try solver.findSolutions(of: puzzle, upTo: 0).isEmpty)
    }

    @Test("Arama deterministik")
    func searchIsDeterministic() throws {
        let puzzle = CalcudokuFixture.ambiguous4x4
        let first = try solver.findSolutions(of: puzzle, upTo: 5)
        let second = try solver.findSolutions(of: puzzle, upTo: 5)
        #expect(first == second)
    }
}

@Suite("Calcudoku teknik seviyeleri")
struct CalcudokuTechniqueTests {
    private let solver = CalcudokuSolver()

    // Bütün hücreler tek hücreli kafes: hiçbir teknik gerekmiyor, alanlar baştan tek
    // adaylı. Dejenere ama anlamlı — verilmiş değerlerin alanlara doğru yazıldığının ve
    // teknik gerektirmeyen bir bulmacanın Easy saydığının testi. Gerçek bir temel seviye
    // bulmacası üreticiyle gelecek (#22).
    @Test("Teknik gerektirmeyen bulmaca temel seviye")
    func fullyGivenPuzzleIsBasic() throws {
        let values = [
            1, 2, 3, 4,
            2, 3, 4, 1,
            3, 4, 1, 2,
            4, 1, 2, 3
        ]
        let puzzle = CalcudokuPuzzle(side: 4, cages: values.indices.map {
            CalcudokuCage(cells: [$0], target: values[$0], operation: .given)
        })

        let trace = try solver.trace(of: puzzle)
        #expect(trace.highestTier == .basic)
        #expect(trace.difficulty == .easy)
        #expect(trace.stepCount == 0, "Alanlar baştan tek adaylı, çıkarım adımı olmamalı")
        #expect(try solver.findSolutions(of: puzzle, upTo: 2).count == 1)
    }

    @Test("Elle kurulan bulmaca orta seviye")
    func handmadePuzzleIsIntermediate() throws {
        let trace = try solver.trace(of: CalcudokuFixture.handmade4x4)
        #expect(trace.highestTier == .intermediate)
        #expect(trace.difficulty == .medium)
        #expect(trace.techniques.contains("hiddenSingle"))
    }

    @Test("Mantıkla kapanmayan bulmaca guessing")
    func ambiguousPuzzleIsGuessing() throws {
        let trace = try solver.trace(of: CalcudokuFixture.ambiguous4x4)
        #expect(trace.highestTier == .guessing)
        #expect(trace.difficulty == .expert)
    }
}
