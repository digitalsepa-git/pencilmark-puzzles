// Çözücünün alan gösterimi ve yayılım adımının sonucu.

extension KakuroSolver {
    enum Step {
        case unchanged
        case changed
        case contradiction
    }

    /// Hücre başına hâlâ mümkün rakamlar.
    ///
    /// Dizi bütün ızgarayı kapsıyor ve ipucu hücrelerinin alanı boş kalıyor. Giriş
    /// hücrelerini ayrı indekslemek yerine bulmacayla aynı indekslemeyi kullanmak, çözücüde
    /// ve kurallarda dönüşüm yapmaktan ucuz — boş alanlar yalnızca hiç okunmuyor.
    struct Domains {
        var sets: [DigitSet]
        let entryCells: [Int]

        init(puzzle: KakuroPuzzle) {
            self.entryCells = puzzle.entryCells
            var sets = [DigitSet](repeating: .empty, count: puzzle.size.cellCount)
            for cell in puzzle.entryCells {
                sets[cell] = .all
            }
            self.sets = sets
        }

        func value(of cell: Int) -> Int? { sets[cell].singleDigit }
        func isDecided(_ cell: Int) -> Bool { sets[cell].count == 1 }
        var isDecided: Bool { entryCells.allSatisfy { sets[$0].count == 1 } }
        var hasEmptyDomain: Bool { entryCells.contains { sets[$0].isEmpty } }

        mutating func restrict(_ cell: Int, to allowed: DigitSet) -> Bool {
            let narrowed = sets[cell].intersection(allowed)
            guard narrowed != sets[cell] else { return false }
            sets[cell] = narrowed
            return true
        }

        mutating func remove(_ digit: Int, from cell: Int) -> Bool {
            guard sets[cell].contains(digit) else { return false }
            sets[cell].remove(digit)
            return true
        }

        /// En az adayı kalan karar verilmemiş giriş hücresi.
        func mostConstrainedUndecided() -> Int? {
            var best: Int?
            var bestCount = Int.max
            for cell in entryCells {
                let count = sets[cell].count
                guard count > 1, count < bestCount else { continue }
                best = cell
                bestCount = count
                if count == 2 { break }
            }
            return best
        }

        func solution(for puzzle: KakuroPuzzle) -> KakuroSolution {
            KakuroSolution(
                values: Grid(size: puzzle.size, elements: sets.map { $0.singleDigit ?? 0 })
            )
        }

        func board(for puzzle: KakuroPuzzle) -> KakuroBoard {
            KakuroBoard(
                cells: Grid(
                    size: puzzle.size,
                    elements: sets.map { set in
                        set.singleDigit.map { DigitCell(value: $0) } ?? .empty
                    }
                )
            )
        }
    }
}
