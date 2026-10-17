/// Satır öncelikli düz dizide tutulan iki boyutlu ızgara.
///
/// Düz dizi bilinçli: çözücüler hücreler üzerinde milyonlarca kez dolaşıyor ve iç içe
/// dizilerde her satır erişimi ayrı bir referans atlaması demek. Ayrıca `Grid` bir değer
/// tipi olduğu için geri alma yığınında anlık görüntü almak ucuz.
public struct Grid<Element> {
    public let size: GridSize
    private var storage: [Element]

    public init(size: GridSize, repeating element: Element) {
        self.size = size
        self.storage = Array(repeating: element, count: size.cellCount)
    }

    /// Satır öncelikli sırada verilen elemanlarla kurar.
    public init(size: GridSize, elements: [Element]) {
        precondition(
            elements.count == size.cellCount,
            "Eleman sayısı ızgara boyutuyla uyuşmuyor: \(elements.count) != \(size.cellCount)"
        )
        self.size = size
        self.storage = elements
    }

    public subscript(position: Position) -> Element {
        get {
            precondition(size.contains(position), "Izgara dışı konum: \(position)")
            return storage[index(of: position)]
        }
        set {
            precondition(size.contains(position), "Izgara dışı konum: \(position)")
            storage[index(of: position)] = newValue
        }
    }

    public subscript(row: Int, column: Int) -> Element {
        get { self[Position(row: row, column: column)] }
        set { self[Position(row: row, column: column)] = newValue }
    }

    /// Sınır dışı konumlar için `nil` döner. Komşu taramalarında sınır kontrolünü
    /// çağıranın tekrar tekrar yazmasını engelliyor.
    public func element(at position: Position) -> Element? {
        guard size.contains(position) else { return nil }
        return storage[index(of: position)]
    }

    public var elements: [Element] { storage }

    public var allPositions: [Position] { size.allPositions }

    public func row(_ r: Int) -> [Element] {
        precondition(r >= 0 && r < size.rows, "Satır dışı: \(r)")
        let start = r * size.columns
        return Array(storage[start..<(start + size.columns)])
    }

    public func column(_ c: Int) -> [Element] {
        precondition(c >= 0 && c < size.columns, "Sütun dışı: \(c)")
        return (0..<size.rows).map { storage[$0 * size.columns + c] }
    }

    public func map<T>(_ transform: (Element) throws -> T) rethrows -> Grid<T> {
        Grid<T>(size: size, elements: try storage.map(transform))
    }

    /// Izgara sınırları içinde kalan dört yönlü komşular.
    public func neighbors(of position: Position) -> [Position] {
        position.orthogonalNeighbors.filter { size.contains($0) }
    }

    private func index(of position: Position) -> Int {
        position.row * size.columns + position.column
    }
}

extension Grid: Equatable where Element: Equatable {}
extension Grid: Hashable where Element: Hashable {}
extension Grid: Sendable where Element: Sendable {}
