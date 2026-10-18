/// Hitori bulmacasının tanımı: sayı ızgarası.
///
/// Kurallar (brief b.6): tekrar eden sayılar karalanır, karalı hücreler komşu olamaz,
/// beyaz hücreler bağlı kalır. İpucu diye ayrı bir şey yok — bütün bilgi ızgaranın
/// kendisinde, oyuncunun kararı hangi hücrelerin karalanacağı.
///
/// Çözücünün ihtiyaç duyduğu iki türetilmiş yapı kurucuda bir kez hesaplanıyor: aynı
/// satır/sütunda aynı değeri paylaşan hücre grupları ve komşuluk listesi. Hücreler düz
/// indeksle anılıyor (`satır * sütunSayısı + sütun`); çözücü bunlar üzerinde milyonlarca
/// kez dolaşacak ve `Position` aritmetiği orada ölçülebilir maliyet.
public struct HitoriPuzzle: Sendable {
    public let values: Grid<Int>

    /// Aynı satır veya sütunda aynı değeri paylaşan hücre indeksleri.
    ///
    /// Her grubun en fazla bir üyesi beyaz kalabilir. Tek üyeli gruplar tutulmuyor:
    /// kısıt getirmiyorlar.
    public let groups: [[Int]]
    /// Hücre indeksi → üyesi olduğu grup indeksleri. En fazla ikisi var (satır ve sütun).
    public let groupsOfCell: [[Int]]
    /// Hücre indeksi → dört yönlü komşu indeksleri.
    public let neighbors: [[Int]]

    public init(values: Grid<Int>) {
        self.values = values
        let (groups, membership) = Self.buildGroups(values: values)
        self.groups = groups
        self.groupsOfCell = membership
        self.neighbors = Self.buildNeighbors(size: values.size)
    }

    public var size: GridSize { values.size }
    public var cellCount: Int { values.size.cellCount }

    public func index(of position: Position) -> Int {
        position.row * size.columns + position.column
    }

    public func position(of index: Int) -> Position {
        Position(row: index / size.columns, column: index % size.columns)
    }

    public func value(at index: Int) -> Int {
        values.elements[index]
    }

    // MARK: - Türetme

    private static func buildGroups(values: Grid<Int>) -> (groups: [[Int]], membership: [[Int]]) {
        var groups: [[Int]] = []
        let size = values.size

        for row in 0..<size.rows {
            appendGroups(
                from: (0..<size.columns).map { (row * size.columns + $0, values[row, $0]) },
                into: &groups
            )
        }
        for column in 0..<size.columns {
            appendGroups(
                from: (0..<size.rows).map { ($0 * size.columns + column, values[$0, column]) },
                into: &groups
            )
        }

        var membership = [[Int]](repeating: [], count: size.cellCount)
        for (groupIndex, group) in groups.enumerated() {
            for cell in group {
                membership[cell].append(groupIndex)
            }
        }
        return (groups, membership)
    }

    private static func appendGroups(from line: [(Int, Int)], into groups: inout [[Int]]) {
        var byValue: [Int: [Int]] = [:]
        for (cell, value) in line {
            byValue[value, default: []].append(cell)
        }
        // Kanonik sıra: grup indeksleri tanımdan deterministik türemeli, yoksa aynı tohum
        // farklı çözüm dizisi verir (bkz. ADR 0006).
        for value in byValue.keys.sorted() {
            guard let cells = byValue[value], cells.count > 1 else { continue }
            groups.append(cells)
        }
    }

    private static func buildNeighbors(size: GridSize) -> [[Int]] {
        var result = [[Int]](repeating: [], count: size.cellCount)
        for position in size.allPositions {
            let index = position.row * size.columns + position.column
            for neighbor in position.orthogonalNeighbors where size.contains(neighbor) {
                result[index].append(neighbor.row * size.columns + neighbor.column)
            }
        }
        return result
    }
}

extension HitoriPuzzle: Hashable {
    // Türetilmiş alanlar karşılaştırmaya girmiyor: değerler aynıysa gruplar da aynı.
    public static func == (lhs: HitoriPuzzle, rhs: HitoriPuzzle) -> Bool {
        lhs.values == rhs.values
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(values)
    }
}
