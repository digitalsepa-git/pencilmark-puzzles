/// Oyuncunun Hitori tahtası: hücre başına karalama durumu.
public struct HitoriBoard: Hashable, Sendable {
    public private(set) var cells: Grid<ShadeState>

    public init(_ puzzle: HitoriPuzzle) {
        self.cells = Grid(size: puzzle.size, repeating: .unknown)
    }

    public init(cells: Grid<ShadeState>) {
        self.cells = cells
    }

    public subscript(position: Position) -> ShadeState {
        get { cells[position] }
        set { cells[position] = newValue }
    }

    public var isEmpty: Bool { cells.elements.allSatisfy { $0 == .unknown } }

    /// Karar verilmemiş hücre kalmadı mı.
    public var isComplete: Bool { !cells.elements.contains(.unknown) }

    /// Çözümde beyaz kalacak hücreler.
    ///
    /// `unknown` de beyaz sayılıyor: oyuncu yalnız karalayarak bulmacayı bitirebiliyor,
    /// her beyaz hücreyi ayrıca işaretlemek zorunda değil. `marked` oyuncunun kendi notu.
    public func isWhite(at position: Position) -> Bool {
        cells[position] != .shaded
    }

    public func solution() -> HitoriSolution {
        HitoriSolution(shaded: cells.map { $0 == .shaded })
    }
}

/// Tamamlanmış ve doğrulanmış karalama deseni.
public struct HitoriSolution: Hashable, Sendable {
    public let shaded: Grid<Bool>

    public init(shaded: Grid<Bool>) {
        self.shaded = shaded
    }

    public func board() -> HitoriBoard {
        HitoriBoard(cells: shaded.map { $0 ? ShadeState.shaded : .marked })
    }
}

/// Tek hücrenin karalama durumunu değiştiren hamle.
public struct HitoriMove: PuzzleMove, Codable {
    public typealias Board = HitoriBoard

    public let position: Position
    public let previous: ShadeState
    public let next: ShadeState

    public init(position: Position, previous: ShadeState, next: ShadeState) {
        self.position = position
        self.previous = previous
        self.next = next
    }

    public func apply(to board: inout HitoriBoard) {
        board[position] = next
    }

    public func undo(on board: inout HitoriBoard) {
        board[position] = previous
    }

    /// Brief b.7'deki giriş modeli: "Hücreye dokun: karala → işaretle → boş döngüsü".
    public static func cycling(at position: Position, on board: HitoriBoard) -> HitoriMove {
        let current = board[position]
        return HitoriMove(position: position, previous: current, next: current.next)
    }
}
