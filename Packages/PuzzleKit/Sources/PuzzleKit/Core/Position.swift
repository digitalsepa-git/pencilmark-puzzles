/// Izgara üzerinde satır/sütun konumu.
///
/// Beş varyantın tamamı aynı konum tipini kullanır. Slitherlink'te konum hücreyi değil
/// nokta ızgarasındaki noktayı gösterir; `EdgePosition` onun üzerine kurulur.
public struct Position: Hashable, Sendable, Codable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    /// Dört yönlü komşular. Izgara sınırı kontrolü çağıranın işi; burada sınır bilgisi yok.
    public var orthogonalNeighbors: [Position] {
        [
            Position(row: row - 1, column: column),
            Position(row: row + 1, column: column),
            Position(row: row, column: column - 1),
            Position(row: row, column: column + 1)
        ]
    }

    public func offset(byRows rows: Int, columns: Int) -> Position {
        Position(row: row + rows, column: column + columns)
    }
}

extension Position: Comparable {
    /// Satır öncelikli sıralama. Testlerde ve hata raporlarında kararlı çıktı için gerekli.
    public static func < (lhs: Position, rhs: Position) -> Bool {
        (lhs.row, lhs.column) < (rhs.row, rhs.column)
    }
}

extension Position: CustomStringConvertible {
    public var description: String { "(\(row),\(column))" }
}
