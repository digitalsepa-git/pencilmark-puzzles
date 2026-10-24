/// Oyuncunun Hashi tahtası: kenar başına kaç köprü var.
///
/// Dizi, `HashiPuzzle.edges` ile aynı indekslemeyi kullanıyor. Tahtanın tamamı bu; ayrı bir
/// ızgara tutulmuyor çünkü köprüler hücrelere değil kenarlara ait.
public struct HashiBoard: Hashable, Sendable {
    public private(set) var counts: [Int]

    public init(edgeCount: Int) {
        self.counts = Array(repeating: 0, count: edgeCount)
    }

    public init(counts: [Int]) {
        self.counts = counts
    }

    public init(_ puzzle: HashiPuzzle) {
        self.init(edgeCount: puzzle.edges.count)
    }

    public subscript(edge: Int) -> Int {
        get { counts[edge] }
        set { counts[edge] = newValue }
    }

    public var edgeCount: Int { counts.count }

    public var isEmpty: Bool { counts.allSatisfy { $0 == 0 } }

    /// Adadan çıkan köprü sayısı.
    public func degree(ofIsland island: Int, in puzzle: HashiPuzzle) -> Int {
        puzzle.incidentEdges[island].reduce(0) { $0 + counts[$1] }
    }

    public func solution() -> HashiSolution {
        HashiSolution(counts: counts)
    }
}

/// Tamamlanmış ve doğrulanmış köprü dizilimi.
public struct HashiSolution: Hashable, Sendable {
    public let counts: [Int]

    public init(counts: [Int]) {
        self.counts = counts
    }

    public func board() -> HashiBoard {
        HashiBoard(counts: counts)
    }
}

/// Tek kenardaki köprü sayısını değiştiren hamle.
///
/// Eski değeri taşıyor, bu yüzden geri alma tahtanın anlık görüntüsüne ihtiyaç duymuyor —
/// sınırsız geri alma/ileri alma (brief b.7) yalnızca hamle dizisiyle çalışıyor.
public struct HashiMove: PuzzleMove, Codable {
    public typealias Board = HashiBoard

    public let edge: Int
    public let previous: Int
    public let next: Int

    public init(edge: Int, previous: Int, next: Int) {
        self.edge = edge
        self.previous = previous
        self.next = next
    }

    public func apply(to board: inout HashiBoard) {
        board[edge] = next
    }

    public func undo(on board: inout HashiBoard) {
        board[edge] = previous
    }

    /// Brief b.7'deki giriş modeli: "tekrar dokunmak köprüyü ikiye çıkarır, üçüncüsü siler".
    ///
    /// Kapasitesi 1 olan kenarda döngü 0 → 1 → 0 oluyor; derecesi 1 olan adaya ikinci köprü
    /// çekilemediği için kullanıcıyı asla geçersiz bir ara duruma sokmuyor.
    public static func cycling(edge: Int, on board: HashiBoard, in puzzle: HashiPuzzle) -> HashiMove {
        let current = board[edge]
        let capacity = puzzle.edges[edge].capacity
        let next = current >= capacity ? 0 : current + 1
        return HashiMove(edge: edge, previous: current, next: next)
    }
}
