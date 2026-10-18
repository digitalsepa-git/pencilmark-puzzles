// Çözücünün alan gösterimi ve yayılım adımının sonucu.

extension CalcudokuSolver {
    enum Step {
        case unchanged
        case changed
        case contradiction
    }

    /// Hücre başına hâlâ mümkün rakamlar.
    ///
    /// `DigitSet` zaten bit maskesi (bkz. `DigitSet`), yani Hashi ve Hitori'de elle yazılan
    /// maske burada ortak tipten geliyor. Kalem işaretiyle aynı tip olması tesadüf değil:
    /// çözücünün aday kümesi ile oyuncunun aday notu aynı şey.
    struct Domains {
        var sets: [DigitSet]
        let side: Int

        init(puzzle: CalcudokuPuzzle) {
            self.side = puzzle.side
            self.sets = [DigitSet](repeating: .upTo(puzzle.side), count: puzzle.cellCount)
            // Tek hücreli kafesler doğrudan verilmiş değer.
            for cage in puzzle.cages where cage.operation == .given {
                sets[cage.cells[0]] = DigitSet([cage.target])
            }
        }

        func value(of cell: Int) -> Int? { sets[cell].singleDigit }
        func isDecided(_ cell: Int) -> Bool { sets[cell].count == 1 }
        var isDecided: Bool { sets.allSatisfy { $0.count == 1 } }
        var hasEmptyDomain: Bool { sets.contains(where: \.isEmpty) }

        /// Alanı daraltır; gerçekten değiştiyse `true` döner.
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

        /// En az adayı kalan karar verilmemiş hücre. Dallanma çarpanını en küçük tutuyor.
        func mostConstrainedUndecided() -> Int? {
            var best: Int?
            var bestCount = Int.max
            for cell in sets.indices {
                let count = sets[cell].count
                guard count > 1, count < bestCount else { continue }
                best = cell
                bestCount = count
                if count == 2 { break }
            }
            return best
        }

        func solution(for puzzle: CalcudokuPuzzle) -> CalcudokuSolution {
            CalcudokuSolution(
                values: Grid(size: puzzle.size, elements: sets.map { $0.singleDigit ?? 0 })
            )
        }

        func board(for puzzle: CalcudokuPuzzle) -> CalcudokuBoard {
            CalcudokuBoard(
                cells: Grid(
                    size: puzzle.size,
                    elements: sets.map { DigitCell(value: $0.singleDigit) }
                )
            )
        }
    }
}
