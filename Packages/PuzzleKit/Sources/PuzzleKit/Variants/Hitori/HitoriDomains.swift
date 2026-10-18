// Çözücünün alan (domain) gösterimi ve yayılım adımının sonucu.

extension HitoriSolver {
    enum Step {
        case unchanged
        case changed
        case contradiction
    }

    /// Hücre başına hâlâ mümkün durumlar, bit maskesi olarak.
    ///
    /// Hashi'deki `Domains` ile aynı desen: iki durumlu bir alan için `Set` veya `Bool?`
    /// kullanmak yerine bit maskesi, çünkü çözücü hücre başına milyonlarca kez okuyor.
    struct Domains {
        static let whiteBit: UInt8 = 0b01
        static let shadedBit: UInt8 = 0b10

        var bits: [UInt8]

        init(puzzle: HitoriPuzzle) {
            bits = [UInt8](repeating: Self.whiteBit | Self.shadedBit, count: puzzle.cellCount)
        }

        func allowsWhite(_ cell: Int) -> Bool { bits[cell] & Self.whiteBit != 0 }
        func allowsShaded(_ cell: Int) -> Bool { bits[cell] & Self.shadedBit != 0 }

        /// Kesinleşmiş durumlar — "mümkün" değil, "öyle".
        func isWhite(_ cell: Int) -> Bool { bits[cell] == Self.whiteBit }
        func isShaded(_ cell: Int) -> Bool { bits[cell] == Self.shadedBit }
        func isUndecided(_ cell: Int) -> Bool { bits[cell] == Self.whiteBit | Self.shadedBit }

        mutating func forceWhite(_ cell: Int) { bits[cell] &= Self.whiteBit }
        mutating func forceShaded(_ cell: Int) { bits[cell] &= Self.shadedBit }

        var isDecided: Bool {
            bits.allSatisfy { $0.nonzeroBitCount == 1 }
        }

        var hasEmptyDomain: Bool {
            bits.contains(0)
        }

        /// İlk karar verilmemiş hücre.
        ///
        /// Hashi'deki gibi "en az seçenekli" sıralamaya gerek yok: burada her alan ya tek
        /// ya iki seçenekli, yani karar verilmemiş hücrelerin hepsi eşit kısıtlı. Sıra
        /// deterministik olmak zorunda (ADR 0006), o yüzden indeks sırası.
        func firstUndecided() -> Int? {
            bits.indices.first { bits[$0].nonzeroBitCount > 1 }
        }

        func solution(for puzzle: HitoriPuzzle) -> HitoriSolution {
            HitoriSolution(
                shaded: Grid(size: puzzle.size, elements: bits.map { $0 == Self.shadedBit })
            )
        }

        func board(for puzzle: HitoriPuzzle) -> HitoriBoard {
            HitoriBoard(
                cells: Grid(
                    size: puzzle.size,
                    elements: bits.map { $0 == Self.shadedBit ? ShadeState.shaded : .marked }
                )
            )
        }
    }
}
