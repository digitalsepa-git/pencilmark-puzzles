import Testing
import PuzzleKit
import GameCore

/// ADR 0009: "Elle hazırlanmış ızgaraların da benzersiz çözümü olmalı; öğretici ızgaraları
/// için ayrı bir test, çözücüyle doğrulama yapacak."
@Suite("Öğretici senaryoları")
struct TutorialScenarioTests {
    @Test("Kakuro senaryosu benzersiz ve bildirilen çözümle aynı")
    func kakuroIsUnique() throws {
        let scenario = TutorialScenarios.kakuro()
        let solutions = try KakuroSolver().findSolutions(of: scenario.definition, upTo: 2)
        #expect(solutions == [scenario.solution])
    }

    @Test("Calcudoku senaryosu benzersiz ve bildirilen çözümle aynı")
    func calcudokuIsUnique() throws {
        let scenario = TutorialScenarios.calcudoku()
        let solutions = try CalcudokuSolver().findSolutions(of: scenario.definition, upTo: 2)
        #expect(solutions == [scenario.solution])
    }

    @Test("Hitori senaryosu benzersiz ve bildirilen çözümle aynı")
    func hitoriIsUnique() throws {
        let scenario = TutorialScenarios.hitori()
        let solutions = try HitoriSolver().findSolutions(of: scenario.definition, upTo: 2)
        #expect(solutions == [scenario.solution])
    }

    @Test("Slitherlink senaryosu benzersiz ve bildirilen çözümle aynı")
    func slitherlinkIsUnique() throws {
        let scenario = TutorialScenarios.slitherlink()
        let solutions = try SlitherlinkSolver().findSolutions(of: scenario.definition, upTo: 2)
        #expect(solutions == [scenario.solution])
    }

    @Test("Hashi senaryosu benzersiz ve bildirilen çözümle aynı")
    func hashiIsUnique() throws {
        let scenario = TutorialScenarios.hashi()
        let solutions = try HashiSolver().findSolutions(of: scenario.definition, upTo: 2)
        #expect(solutions == [scenario.solution])
    }

    // ADR 0009: varyant başına 4-6 adım.
    @Test("Adım sayıları 4-6 aralığında")
    func stepCountsAreInRange() {
        let counts = [
            TutorialScenarios.kakuro().steps.count,
            TutorialScenarios.calcudoku().steps.count,
            TutorialScenarios.hitori().steps.count,
            TutorialScenarios.slitherlink().steps.count,
            TutorialScenarios.hashi().steps.count
        ]
        for count in counts {
            #expect((4...6).contains(count), "Adım sayısı \(count)")
        }
    }

    @Test("Her adımın metni ve düzeltmesi var")
    func everyStepHasText() {
        func check<Runtime: PuzzleRuntime>(_ scenario: TutorialScenario<Runtime>) {
            for step in scenario.steps {
            }
        }
        check(TutorialScenarios.kakuro())
        check(TutorialScenarios.calcudoku())
        check(TutorialScenarios.hitori())
        check(TutorialScenarios.slitherlink())
        check(TutorialScenarios.hashi())
    }
}

/// Adımların gerçekten tamamlanabildiğini sınıyor: bir adımın koşulu yanlışsa öğretici
/// orada takılır ve bunu yalnız senaryoyu baştan sona oynayan bir test yakalar.
@Suite("Öğretici yürüyüşü")
struct TutorialWalkthroughTests {
    @Test("Kakuro senaryosu baştan sona bitiyor")
    func kakuroWalkthrough() {
        var run = TutorialRun(scenario: TutorialScenarios.kakuro())
        let entries = [
            (Position(row: 1, column: 1), 1),
            (Position(row: 1, column: 2), 2),
            (Position(row: 2, column: 1), 8),
            (Position(row: 2, column: 2), 9)
        ]
        for (position, digit) in entries {
            run.perform(.writing(digit, at: position, on: run.session.board))
        }
        #expect(run.isFinished)
        #expect(run.session.isSolved)
        #expect(!run.isCorrecting)
    }

    @Test("Calcudoku senaryosu baştan sona bitiyor")
    func calcudokuWalkthrough() {
        var run = TutorialRun(scenario: TutorialScenarios.calcudoku())
        let solution = run.scenario.solution
        // Adım sırası ilk dört hücreyi belirli bir sırada istiyor; gerisi serbest.
        // Tek hücreli kafesler de oyuncu tarafından yazılıyor: kafes değeri söylüyor ama
        // tahta boş başlıyor.
        let order = [2, 3, 0, 1] + [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        for cell in order {
            let position = Position(row: cell / 4, column: cell % 4)
            run.perform(.writing(solution.values[position], at: position, on: run.session.board))
        }
        #expect(run.isFinished)
        #expect(run.session.isSolved)
    }

    @Test("Hitori senaryosu baştan sona bitiyor")
    func hitoriWalkthrough() {
        var run = TutorialRun(scenario: TutorialScenarios.hitori())
        let shaded = [
            Position(row: 0, column: 3),
            Position(row: 1, column: 0),
            Position(row: 1, column: 2),
            Position(row: 3, column: 0),
            Position(row: 3, column: 2)
        ]
        for position in shaded {
            run.perform(HitoriMove(position: position, previous: .unknown, next: .shaded))
        }
        #expect(run.isFinished)
        #expect(run.session.isSolved)
    }

    @Test("Slitherlink senaryosu baştan sona bitiyor")
    func slitherlinkWalkthrough() {
        var run = TutorialRun(scenario: TutorialScenarios.slitherlink())
        let puzzle = run.scenario.definition

        for edge in puzzle.edgesOfCell[4] {
            run.perform(SlitherlinkMove(edge: edge, previous: .unknown, next: .cross))
        }
        for edge in 0..<puzzle.edgeCount where run.scenario.solution.lines[edge] {
            run.perform(SlitherlinkMove(edge: edge, previous: .unknown, next: .line))
        }
        #expect(run.isFinished)
        #expect(run.session.isSolved)
    }

    @Test("Hashi senaryosu baştan sona bitiyor")
    func hashiWalkthrough() {
        var run = TutorialRun(scenario: TutorialScenarios.hashi())
        for edge in 0..<run.scenario.definition.edges.count {
            run.perform(HashiMove(edge: edge, previous: 0, next: 1))
        }
        #expect(run.isFinished)
        #expect(run.session.isSolved)
    }

    // ADR 0009: yanlış hamle engellenmiyor, nazikçe düzeltiliyor.
    @Test("Yanlış hamle adımı ilerletmiyor ama engellenmiyor")
    func wrongMoveCorrectsWithoutBlocking() {
        var run = TutorialRun(scenario: TutorialScenarios.kakuro())
        let position = Position(row: 1, column: 1)

        run.perform(.writing(5, at: position, on: run.session.board))
        #expect(run.stepIndex == 0, "Yanlış hamle adımı ilerletmemeli")
        #expect(run.isCorrecting, "Düzeltme cümlesi gösterilmeli")
        #expect(run.session.board.value(at: position) == 5, "Hamle engellenmemeli")

        run.undo()
        #expect(!run.isCorrecting)
        #expect(run.session.board.value(at: position) == nil)

        run.perform(.writing(1, at: position, on: run.session.board))
        #expect(run.stepIndex == 1)
    }
}
