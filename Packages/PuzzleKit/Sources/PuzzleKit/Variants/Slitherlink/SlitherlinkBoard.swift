/// Oyuncunun Slitherlink tahtası: kenar başına durum.
///
/// Hücre değil kenar indeksliyor — oynanan şey kenarlar (bkz. `SlitherlinkPuzzle`).
public struct SlitherlinkBoard: Hashable, Sendable {
    public private(set) var edges: [EdgeState]

    public init(_ puzzle: SlitherlinkPuzzle) {
        self.edges = [EdgeState](repeating: .unknown, count: puzzle.edgeCount)
    }

    public init(edges: [EdgeState]) {
        self.edges = edges
    }

    public subscript(edge: Int) -> EdgeState {
        get { edges[edge] }
        set { edges[edge] = newValue }
    }

    public var isEmpty: Bool { edges.allSatisfy { $0 == .unknown } }

    /// Karar verilmemiş kenar kalmadı mı.
    public var isComplete: Bool { !edges.contains(.unknown) }

    /// Hücrenin dört kenarından kaçında çizgi var.
    public func lineCount(ofCell cell: Int, in puzzle: SlitherlinkPuzzle) -> Int {
        puzzle.edgesOfCell[cell].count { edges[$0] == .line }
    }

    /// Hücrenin dört kenarından kaçı hâlâ karar verilmemiş.
    public func unknownCount(ofCell cell: Int, in puzzle: SlitherlinkPuzzle) -> Int {
        puzzle.edgesOfCell[cell].count { edges[$0] == .unknown }
    }

    /// Noktaya değen çizgi sayısı — yani noktanın derecesi.
    public func degree(ofDot dot: Int, in puzzle: SlitherlinkPuzzle) -> Int {
        puzzle.edgesOfDot[dot].count { edges[$0] == .line }
    }

    public func solution() -> SlitherlinkSolution {
        SlitherlinkSolution(lines: edges.map { $0 == .line })
    }
}

/// Tamamlanmış ve doğrulanmış döngü.
public struct SlitherlinkSolution: Hashable, Sendable {
    /// Kenar başına: döngüye dahil mi.
    public let lines: [Bool]

    public init(lines: [Bool]) {
        self.lines = lines
    }

    public func board() -> SlitherlinkBoard {
        SlitherlinkBoard(edges: lines.map { $0 ? EdgeState.line : .cross })
    }

    public var lineCount: Int { lines.count { $0 } }
}

/// Tek kenarın durumunu değiştiren hamle.
public struct SlitherlinkMove: PuzzleMove {
    public typealias Board = SlitherlinkBoard

    public let edge: Int
    public let previous: EdgeState
    public let next: EdgeState

    public init(edge: Int, previous: EdgeState, next: EdgeState) {
        self.edge = edge
        self.previous = previous
        self.next = next
    }

    public func apply(to board: inout SlitherlinkBoard) {
        board[edge] = next
    }

    public func undo(on board: inout SlitherlinkBoard) {
        board[edge] = previous
    }

    /// Brief b.7'deki giriş modeli: "Kenara dokun: çizgi → çarpı → boş döngüsü".
    public static func cycling(edge: Int, on board: SlitherlinkBoard) -> SlitherlinkMove {
        let current = board[edge]
        return SlitherlinkMove(edge: edge, previous: current, next: current.next)
    }
}
