import Testing
import PuzzleKit

@Suite("Calcudoku üretici")
struct CalcudokuGeneratorTests {
    private let generator = CalcudokuGenerator()
    private let solver = CalcudokuSolver()
    private let rules = CalcudokuRules()

    @Test("Kurulan çözüm Latin kısıtını ve bütün kafes hedeflerini tutuyor",
          arguments: Difficulty.allCases)
    func builtSolutionSatisfiesRules(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 606)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        #expect(rules.isSolved(built.solution.board(), in: built.puzzle))
        #expect(rules.duplicatePositions(on: built.solution.board(), in: built.puzzle).isEmpty)
    }

    @Test("Kafes bölüntüsü ızgaranın tamamını bir kez kaplıyor", arguments: Difficulty.allCases)
    func partitionCoversGridExactlyOnce(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 1071)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        let covered = built.puzzle.cages.flatMap(\.cells).sorted()
        #expect(covered == Array(0..<built.puzzle.cellCount))
    }

    @Test("Kafesler bağlı", arguments: Difficulty.allCases)
    func cagesAreConnected(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 2026)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        for cage in built.puzzle.cages {
            #expect(
                CalcudokuPuzzle.isConnected(cage.cells, side: built.puzzle.side),
                "Kopuk kafes: \(cage.cells)"
            )
        }
    }

    // ADR 0005: Easy'de yalnız toplama ve çarpma, Expert'te dört işlem.
    @Test("Easy çıkarma ve bölme kullanmıyor")
    func easyAvoidsSubtractAndDivide() throws {
        for seed in UInt64(1)...12 {
            var rng = SeededGenerator(seed: seed)
            let built = try generator.candidate(difficulty: .easy, using: &rng)
            for cage in built.puzzle.cages {
                #expect(cage.operation != .subtract)
                #expect(cage.operation != .divide)
            }
        }
    }

    @Test("Expert dört işlemi de kullanıyor")
    func expertUsesEveryOperation() throws {
        var seen = Set<CageOperation>()
        for seed in UInt64(1)...25 {
            var rng = SeededGenerator(seed: seed)
            let built = try generator.candidate(difficulty: .expert, using: &rng)
            seen.formUnion(built.puzzle.cages.map(\.operation))
        }
        #expect(seen.contains(.add))
        #expect(seen.contains(.multiply))
        #expect(seen.contains(.subtract))
        #expect(seen.contains(.divide))
    }

    @Test("Izgara boyutları ADR 0005'teki aralıklarda")
    func layoutSizesFollowDecisionRecord() {
        #expect(CalcudokuLayout.standard(for: .easy).side == 4)
        #expect((5...6).contains(CalcudokuLayout.standard(for: .medium).side))
        #expect(CalcudokuLayout.standard(for: .hard).side == 7)
        #expect((8...9).contains(CalcudokuLayout.standard(for: .expert).side))
    }

    @Test("Tahmin gerektiren bulmaca derecelendirilmiyor")
    func guessingPuzzlesAreRejected() throws {
        let puzzle = CalcudokuFixture.ambiguous4x4
        let trace = try solver.trace(of: puzzle)
        #expect(trace.highestTier == .guessing)
        #expect(generator.rate(trace, of: puzzle) == nil)
    }

    // Teknik seviyesi birincil kalıyor: büyük ızgarada olup da yalnız temel tekniklerle
    // çözülen bir bulmaca Easy sayılıyor ve Expert hedefinde eleniyor. Brief b.6'nın
    // engellemek istediği şey buydu.
    @Test("Büyük ızgara tek başına Expert yapmıyor")
    func sizeAloneDoesNotMakeExpert() throws {
        var basic = SolveTrace()
        basic.record("latin", tier: .basic)
        let bigEasy = try makeFullyGivenPuzzle(side: 8)
        #expect(generator.rate(basic, of: bigEasy) == .easy)
    }

    @Test("Mantığın neredeyse bitirdiği büyük bulmaca Hard sayılıyor")
    func nearlySolvedBigPuzzleIsHard() throws {
        var advanced = SolveTrace()
        advanced.record("hypothesis", tier: .advanced)
        // Bütün hücreleri verilmiş 8×8: mantıksal ilerleme 1,0, yani eşiğin üstünde.
        let transparent = try makeFullyGivenPuzzle(side: 8)
        #expect(solver.logicalProgress(of: transparent) == 1)
        #expect(generator.rate(advanced, of: transparent) == .hard)
    }

    private func makeFullyGivenPuzzle(side: Int) throws -> CalcudokuPuzzle {
        var rng = SeededGenerator(seed: 7)
        let values = LatinSquare.random(side: side, using: &rng)
        return CalcudokuPuzzle(side: side, cages: (0..<(side * side)).map { cell in
            CalcudokuCage(
                cells: [cell],
                target: values[cell / side, cell % side],
                operation: .given
            )
        })
    }
}

@Suite("Calcudoku hat entegrasyonu")
struct CalcudokuPipelineTests {
    private let pipeline = CalcudokuGenerator.pipeline()
    private let solver = CalcudokuSolver()
    private let rules = CalcudokuRules()

    @Test("Hat benzersiz ve hedef zorlukta bulmaca veriyor", arguments: Difficulty.allCases)
    func pipelineProducesUniquePuzzle(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .calcudoku, difficulty: difficulty, counter: 5)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

        #expect(puzzle.variant == .calcudoku)
        #expect(puzzle.difficulty == difficulty)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
        #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
    }

    @Test("Çözücünün bulduğu çözüm üreticinin kurduğuyla aynı", arguments: Difficulty.allCases)
    func solverAgreesWithGenerator(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .calcudoku, difficulty: difficulty, counter: 23)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2) == [puzzle.solution])
    }

    @Test("Aynı tohum aynı bulmacayı veriyor")
    func sameSeedProducesSamePuzzle() throws {
        let seed = Seed.daily(variant: .calcudoku, year: 2026, month: 10, day: 20)
        let first = try pipeline.generate(difficulty: .medium, seed: seed)
        let second = try pipeline.generate(difficulty: .medium, seed: seed)
        #expect(first.definition == second.definition)
        #expect(first.solution == second.solution)
    }

    @Test("Farklı tohum farklı bulmaca veriyor")
    func differentSeedProducesDifferentPuzzle() throws {
        let first = try pipeline.generate(difficulty: .medium, seed: 31)
        let second = try pipeline.generate(difficulty: .medium, seed: 32)
        #expect(first.definition != second.definition)
    }
}
