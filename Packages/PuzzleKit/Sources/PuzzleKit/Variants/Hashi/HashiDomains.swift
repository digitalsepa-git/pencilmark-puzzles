// Çözücünün alan (domain) gösterimi ve yayılım adımının sonucu.

extension HashiSolver {
    enum Step {
        case unchanged
        case changed
        case contradiction
    }

    /// Kenar başına hâlâ mümkün köprü sayıları, bit maskesi olarak. Bit v → v köprü mümkün.
    struct Domains {
        var bits: [UInt8]

        init(puzzle: HashiPuzzle) {
            bits = puzzle.edges.map { edge in
                var mask: UInt8 = 0
                for value in 0...edge.capacity {
                    mask |= 1 << UInt8(value)
                }
                return mask
            }
        }

        func allows(_ edge: Int, _ value: Int) -> Bool {
            bits[edge] & (1 << UInt8(value)) != 0
        }

        func lowest(_ edge: Int) -> Int {
            Int(bits[edge].trailingZeroBitCount)
        }

        func highest(_ edge: Int) -> Int {
            7 - Int(bits[edge].leadingZeroBitCount)
        }

        mutating func forbid(_ edge: Int, _ value: Int) {
            bits[edge] &= ~(1 << UInt8(value))
        }

        mutating func restrict(_ edge: Int, to value: Int) {
            bits[edge] &= 1 << UInt8(value)
        }

        var isDecided: Bool {
            bits.allSatisfy { $0.nonzeroBitCount == 1 }
        }

        /// En az seçeneği kalan karar verilmemiş kenar. Arama önce buradan dallanıyor;
        /// dallanma çarpanını en küçük tutan sıralama bu.
        func mostConstrainedUndecided() -> Int? {
            var best: Int?
            var bestCount = Int.max
            for edge in bits.indices {
                let count = bits[edge].nonzeroBitCount
                if count > 1 && count < bestCount {
                    best = edge
                    bestCount = count
                    if count == 2 { break }
                }
            }
            return best
        }

        func decidedValues() -> [Int] {
            bits.map { Int($0.trailingZeroBitCount) }
        }
    }
}
