import Testing
import PuzzleKit

@Suite("Hitori üretici")
struct HitoriGeneratorTests {
    private let generator = HitoriGenerator()
    private let solver = HitoriSolver()
    private let rules = HitoriRules()

    @Test("Kurulan karalama deseni kurallara uygun", arguments: Difficulty.allCases)
    func builtShadingSatisfiesRules(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 8181)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        #expect(rules.isSolved(built.solution.board(), in: built.puzzle))
        #expect(!rules.hasAdjacentShaded(built.solution.board(), in: built.puzzle))
    }

    @Test("Beyazlar satır ve sütunlarda tekrarsız", arguments: Difficulty.allCases)
    func whitesHaveNoRepeats(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 5)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        let side = built.puzzle.size.rows

        for line in 0..<side {
            var rowValues: [Int] = []
            var columnValues: [Int] = []
            for other in 0..<side {
                if !built.solution.shaded[line, other] {
                    rowValues.append(built.puzzle.values[line, other])
                }
                if !built.solution.shaded[other, line] {
                    columnValues.append(built.puzzle.values[other, line])
                }
            }
            #expect(Set(rowValues).count == rowValues.count)
            #expect(Set(columnValues).count == columnValues.count)
        }
    }

    // Benzersizliğin dayanağı bu: desen maksimal olduğu için fazladan hiçbir hücre
    // karalanamıyor — her beyazın ya karalı bir komşusu var ya da beyaz bölgenin kesme
    // noktası (bkz. ADR 0011). Kontrol üreticinin iç yöntemlerini çağırmıyor, çıktısına
    // bakıyor: bağlılık kontrolü testin kendi içinde, bağımsız bir uygulama.
    @Test("Karalama deseni maksimal: fazladan hiçbir hücre karalanamıyor",
          arguments: Difficulty.allCases)
    func shadingIsMaximal(difficulty: Difficulty) throws {
        var rng = SeededGenerator(seed: 99)
        let built = try generator.candidate(difficulty: difficulty, using: &rng)
        let mask = built.solution.shaded

        for position in mask.allPositions where !mask[position] {
            let hasShadedNeighbor = position.orthogonalNeighbors.contains {
                mask.element(at: $0) == true
            }
            guard !hasShadedNeighbor else { continue }

            var candidate = mask
            candidate[position] = true
            #expect(
                !whitesConnected(candidate),
                "\(position) ne komşulukla ne bağlılıkla tutturulmuş — desen maksimal değil"
            )
        }
    }

    // Easy'nin temel tekniklerle açılabilmesi için her beyazın karalı bir komşusu olması
    // gerekiyor; yalnız bağlılıkla tutturulmuş bir beyaz bulmacayı en az orta seviye yapıyor.
    // Üretici bunu arıyor ama garanti etmiyor: bulamazsa elde olanla devam ediyor ve hat o
    // adayı zorluk eşleşmesinde eliyor. Test o arayışın işe yaradığını ölçüyor.
    @Test("Easy yerleşimi beyazların çoğunu komşulukla tutturuyor")
    func easyShadingUsuallyDominatesEveryWhite() throws {
        var dominated = 0
        let trials = 20

        for seed in UInt64(1)...UInt64(trials) {
            var rng = SeededGenerator(seed: seed)
            let built = try generator.candidate(difficulty: .easy, using: &rng)
            let mask = built.solution.shaded
            let allDominated = mask.allPositions.allSatisfy { position in
                mask[position] || position.orthogonalNeighbors.contains {
                    mask.element(at: $0) == true
                }
            }
            if allDominated { dominated += 1 }
        }

        #expect(dominated >= trials / 2, "\(trials) denemede yalnız \(dominated) desen tam")
    }

    /// Beyaz hücreler tek bölgede mi — testin kendi bağımsız uygulaması.
    private func whitesConnected(_ mask: Grid<Bool>) -> Bool {
        guard let start = mask.allPositions.first(where: { !mask[$0] }) else { return false }
        var seen = Grid(size: mask.size, repeating: false)
        var stack = [start]
        seen[start] = true
        var visited = 1
        while let position = stack.popLast() {
            for neighbor in mask.neighbors(of: position) where !mask[neighbor] && !seen[neighbor] {
                seen[neighbor] = true
                visited += 1
                stack.append(neighbor)
            }
        }
        return visited == mask.elements.count { !$0 }
    }

    @Test("Izgara boyutları ADR 0005'teki tablodan")
    func layoutSizesFollowDecisionRecord() {
        #expect(HitoriLayout.standard(for: .easy).size == GridSize(square: 5))
        #expect(HitoriLayout.standard(for: .medium).size == GridSize(square: 7))
        #expect(HitoriLayout.standard(for: .hard).size == GridSize(square: 9))
        #expect(HitoriLayout.standard(for: .expert).size == GridSize(square: 11))
    }

    @Test("Tahmin gerektiren bulmaca derecelendirilmiyor")
    func guessingPuzzlesAreRejected() throws {
        let trace = try solver.trace(of: HitoriFixture.handmade4x4)
        #expect(trace.highestTier == .guessing)
        #expect(generator.rate(trace, of: HitoriFixture.handmade4x4) == nil)
    }
}

@Suite("Hitori hat entegrasyonu")
struct HitoriPipelineTests {
    private let pipeline = HitoriGenerator.pipeline()
    private let solver = HitoriSolver()
    private let rules = HitoriRules()

    @Test("Hat benzersiz ve hedef zorlukta bulmaca veriyor", arguments: Difficulty.allCases)
    func pipelineProducesUniquePuzzle(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .hitori, difficulty: difficulty, counter: 3)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

        #expect(puzzle.variant == .hitori)
        #expect(puzzle.difficulty == difficulty)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
        #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
    }

    @Test("Çözücünün bulduğu çözüm üreticinin kurduğuyla aynı", arguments: Difficulty.allCases)
    func solverAgreesWithGenerator(difficulty: Difficulty) throws {
        let seed = Seed.free(variant: .hitori, difficulty: difficulty, counter: 17)
        let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)
        #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2) == [puzzle.solution])
    }

    @Test("Aynı tohum aynı bulmacayı veriyor")
    func sameSeedProducesSamePuzzle() throws {
        let seed = Seed.daily(variant: .hitori, year: 2026, month: 10, day: 23)
        let first = try pipeline.generate(difficulty: .medium, seed: seed)
        let second = try pipeline.generate(difficulty: .medium, seed: seed)
        #expect(first.definition == second.definition)
        #expect(first.solution == second.solution)
    }

    @Test("Farklı tohum farklı bulmaca veriyor")
    func differentSeedProducesDifferentPuzzle() throws {
        let first = try pipeline.generate(difficulty: .medium, seed: 11)
        let second = try pipeline.generate(difficulty: .medium, seed: 12)
        #expect(first.definition != second.definition)
    }
}

@Suite("Hitori üretici — özellik testi")
struct HitoriPropertyTests {
    // Brief b.11: zorluk başına 125 bulmaca, dört zorluk = 500.
    @Test("500 bulmacanın hepsi benzersiz çözümlü ve hedef zorlukta")
    func fiveHundredPuzzlesAreUnique() throws {
        let pipeline = HitoriGenerator.pipeline()
        let solver = HitoriSolver()
        let rules = HitoriRules()
        var produced = 0
        var worstAttempts = 0

        for difficulty in Difficulty.allCases {
            for index in 0..<125 {
                let seed = Seed.free(variant: .hitori, difficulty: difficulty, counter: UInt64(index))
                let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

                #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
                #expect(puzzle.difficulty == difficulty)
                #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))

                worstAttempts = max(worstAttempts, puzzle.attempts)
                produced += 1
            }
        }

        #expect(produced == 500)
        #expect(worstAttempts < 1500, "En kötü deneme sayısı \(worstAttempts) — sınıra yaklaşıyor")
        print("[hitori] 500 bulmaca üretildi, en kötü deneme sayısı \(worstAttempts)")
    }
}
