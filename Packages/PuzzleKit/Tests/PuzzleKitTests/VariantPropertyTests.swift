import Testing
import PuzzleKit

// Brief b.11'in istediği özellik testi, üç varyant için: "Rastgele 500 bulmaca üret →
// hepsi benzersiz çözümlü." Zorluk başına 125 bulmaca, dört zorluk = 500.
//
// Bu testler **yalnız release derlemede** koşuyor ve sebebi ölçüm: debug derlemede üç
// varyantın 500'lükleri birlikte 93 saniye alıyordu, release'te 5 saniye. CI'ın her PR'da
// 93 saniye beklemesinin karşılığı yok — aynı doğrulama release koşusunda da yapılıyor ve
// CI o koşuyu zaten çalıştırıyor (bkz. `.github/workflows/ci.yml`, "Performans testleri").
//
// Hepsi tek dosyada, çünkü koşma koşulu ortak ve ayrı dosyalarda tekrar eden bir
// `#if` bloğu gözden kaçmaya müsait.
#if !DEBUG

@Suite("Hashi üretici — özellik testi")
struct HashiPropertyTests {
    @Test("500 bulmacanın hepsi benzersiz çözümlü ve hedef zorlukta")
    func fiveHundredPuzzlesAreUnique() throws {
        let pipeline = HashiGenerator.pipeline()
        let solver = HashiSolver()
        let rules = HashiRules()
        var worstAttempts = 0

        for difficulty in Difficulty.allCases {
            for index in 0..<125 {
                let seed = Seed.free(variant: .hashi, difficulty: difficulty, counter: UInt64(index))
                let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

                #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
                #expect(puzzle.difficulty == difficulty)
                #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
                worstAttempts = max(worstAttempts, puzzle.attempts)
            }
        }

        // Sınıra yaklaşıyorsak üretici bozulmaya başlamış demektir ve ADR'deki ölçüm
        // geçersizdir.
        #expect(worstAttempts < 1500, "En kötü deneme sayısı \(worstAttempts)")
        print("[hashi] 500 bulmaca, en kötü deneme sayısı \(worstAttempts)")
    }
}

@Suite("Hitori üretici — özellik testi")
struct HitoriPropertyTests {
    @Test("500 bulmacanın hepsi benzersiz çözümlü ve hedef zorlukta")
    func fiveHundredPuzzlesAreUnique() throws {
        let pipeline = HitoriGenerator.pipeline()
        let solver = HitoriSolver()
        let rules = HitoriRules()
        var worstAttempts = 0

        for difficulty in Difficulty.allCases {
            for index in 0..<125 {
                let seed = Seed.free(variant: .hitori, difficulty: difficulty, counter: UInt64(index))
                let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

                #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
                #expect(puzzle.difficulty == difficulty)
                #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
                worstAttempts = max(worstAttempts, puzzle.attempts)
            }
        }

        #expect(worstAttempts < 1500, "En kötü deneme sayısı \(worstAttempts)")
        print("[hitori] 500 bulmaca, en kötü deneme sayısı \(worstAttempts)")
    }
}

@Suite("Calcudoku üretici — özellik testi")
struct CalcudokuPropertyTests {
    @Test("500 bulmacanın hepsi benzersiz çözümlü ve hedef zorlukta")
    func fiveHundredPuzzlesAreUnique() throws {
        let pipeline = CalcudokuGenerator.pipeline()
        let solver = CalcudokuSolver()
        let rules = CalcudokuRules()
        var worstAttempts = 0

        for difficulty in Difficulty.allCases {
            for index in 0..<125 {
                let seed = Seed.free(
                    variant: .calcudoku, difficulty: difficulty, counter: UInt64(index)
                )
                let puzzle = try pipeline.generate(difficulty: difficulty, seed: seed)

                #expect(try solver.findSolutions(of: puzzle.definition, upTo: 2).count == 1)
                #expect(puzzle.difficulty == difficulty)
                #expect(rules.isSolved(puzzle.solution.board(), in: puzzle.definition))
                worstAttempts = max(worstAttempts, puzzle.attempts)
            }
        }

        #expect(worstAttempts < 1500, "En kötü deneme sayısı \(worstAttempts)")
        print("[calcudoku] 500 bulmaca, en kötü deneme sayısı \(worstAttempts)")
    }
}

#endif
