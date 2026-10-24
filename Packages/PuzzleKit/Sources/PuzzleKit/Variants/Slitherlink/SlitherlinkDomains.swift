// Çözücünün alan gösterimi ve yayılım adımının sonucu.

extension SlitherlinkSolver {
    enum Step {
        case unchanged
        case changed
        case contradiction
    }

    /// Kenar başına hâlâ mümkün durumlar: çizgi ve/veya çarpı.
    ///
    /// Hitori'deki `Domains` ile aynı desen — iki durumlu alan için bit maskesi.
    struct Domains {
        static let lineBit: UInt8 = 0b01
        static let crossBit: UInt8 = 0b10

        var bits: [UInt8]

        init(puzzle: SlitherlinkPuzzle) {
            bits = [UInt8](repeating: Self.lineBit | Self.crossBit, count: puzzle.edgeCount)
        }

        func allowsLine(_ edge: Int) -> Bool { bits[edge] & Self.lineBit != 0 }
        func allowsCross(_ edge: Int) -> Bool { bits[edge] & Self.crossBit != 0 }

        /// Kesinleşmiş durumlar — "mümkün" değil, "öyle".
        func isLine(_ edge: Int) -> Bool { bits[edge] == Self.lineBit }
        func isCross(_ edge: Int) -> Bool { bits[edge] == Self.crossBit }
        func isUndecided(_ edge: Int) -> Bool { bits[edge] == Self.lineBit | Self.crossBit }

        mutating func forceLine(_ edge: Int) { bits[edge] &= Self.lineBit }
        mutating func forceCross(_ edge: Int) { bits[edge] &= Self.crossBit }

        var isDecided: Bool { bits.allSatisfy { $0.nonzeroBitCount == 1 } }
        var hasEmptyDomain: Bool { bits.contains(0) }

        func board(for puzzle: SlitherlinkPuzzle) -> SlitherlinkBoard {
            SlitherlinkBoard(edges: bits.map { $0 == Self.lineBit ? EdgeState.line : .cross })
        }

        func solution() -> SlitherlinkSolution {
            SlitherlinkSolution(lines: bits.map { $0 == Self.lineBit })
        }
    }
}
