/// Izgara boyutu. Kare olmayan ızgaralar da var (Kakuro), bu yüzden tek sayı yetmiyor.
public struct GridSize: Hashable, Sendable {
    public let rows: Int
    public let columns: Int

    public init(rows: Int, columns: Int) {
        precondition(rows > 0 && columns > 0, "Izgara boyutu pozitif olmalı")
        self.rows = rows
        self.columns = columns
    }

    public init(square side: Int) {
        self.init(rows: side, columns: side)
    }

    public var cellCount: Int { rows * columns }

    public var isSquare: Bool { rows == columns }

    public func contains(_ position: Position) -> Bool {
        position.row >= 0 && position.row < rows
            && position.column >= 0 && position.column < columns
    }

    /// Satır öncelikli sırayla tüm konumlar.
    public var allPositions: [Position] {
        var result: [Position] = []
        result.reserveCapacity(cellCount)
        for r in 0..<rows {
            for c in 0..<columns {
                result.append(Position(row: r, column: c))
            }
        }
        return result
    }
}

extension GridSize: CustomStringConvertible {
    public var description: String { "\(rows)×\(columns)" }
}
