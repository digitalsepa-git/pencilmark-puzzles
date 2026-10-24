/// Slitherlink bulmacasının tanımı: hücre ipuçları.
///
/// Diğer dört varyanttan yapısal olarak farklı: oyuncu hücrelere değil **kenarlara**
/// dokunuyor. Izgara `rows × columns` hücre, ama oynanan şey `(rows+1) × (columns+1)`
/// noktanın arasındaki kenarlar.
///
/// Kenar indekslemesi iki blok: önce yatay kenarlar (nokta satırları boyunca), sonra dikey
/// kenarlar. Tek bir düz indeks uzayı, çünkü çözücünün alanı kenar başına bir bit maskesi
/// ve iki ayrı dizi tutmak her erişimde dal demek.
public struct SlitherlinkPuzzle: Sendable {
    /// Hücre ızgarasının boyutu.
    public let size: GridSize
    /// Hücre ipuçları; ipucu olmayan hücre `nil`.
    ///
    /// İpucu, o hücrenin dört kenarından kaçının döngüye dahil olduğunu söylüyor. 0-3
    /// aralığında: 4 yalnız döngünün tek bir hücrenin kenarı olduğu dejenere durumda
    /// mümkün, çünkü o hücrenin dört köşesi de derece 2'ye dolar ve başka kenar kalmaz.
    public let clues: Grid<Int?>

    /// Yatay kenar sayısı: `(satır + 1) × sütun`.
    public let horizontalCount: Int
    /// Toplam kenar sayısı.
    public let edgeCount: Int
    /// Nokta sayısı: `(satır + 1) × (sütun + 1)`.
    public let dotCount: Int

    /// Hücre indeksi → dört kenarı (üst, alt, sol, sağ).
    public let edgesOfCell: [[Int]]
    /// Nokta indeksi → ona değen kenarlar (köşelerde 2, kenarlarda 3, içte 4).
    public let edgesOfDot: [[Int]]
    /// Kenar indeksi → iki uç noktası.
    public let endpointsOfEdge: [(first: Int, second: Int)]
    /// İpucu olan hücrelerin indeksleri.
    public let cluedCells: [Int]

    public init(clues: Grid<Int?>) {
        self.size = clues.size
        self.clues = clues

        let rows = clues.size.rows
        let columns = clues.size.columns
        self.horizontalCount = (rows + 1) * columns
        self.edgeCount = horizontalCount + rows * (columns + 1)
        self.dotCount = (rows + 1) * (columns + 1)

        for position in clues.allPositions {
            if let clue = clues[position] {
                precondition((0...3).contains(clue), "İpucu 0-3 aralığında olmalı: \(clue)")
            }
        }

        var cellEdges = [[Int]]()
        cellEdges.reserveCapacity(rows * columns)
        for row in 0..<rows {
            for column in 0..<columns {
                cellEdges.append([
                    row * columns + column,                                  // üst
                    (row + 1) * columns + column,                            // alt
                    horizontalCount + row * (columns + 1) + column,          // sol
                    horizontalCount + row * (columns + 1) + column + 1       // sağ
                ])
            }
        }
        self.edgesOfCell = cellEdges

        var dotEdges = [[Int]](repeating: [], count: dotCount)
        var endpoints = [(first: Int, second: Int)]()
        endpoints.reserveCapacity(edgeCount)

        for row in 0...rows {
            for column in 0..<columns {
                let left = row * (columns + 1) + column
                let right = left + 1
                endpoints.append((left, right))
                dotEdges[left].append(endpoints.count - 1)
                dotEdges[right].append(endpoints.count - 1)
            }
        }
        for row in 0..<rows {
            for column in 0...columns {
                let top = row * (columns + 1) + column
                let bottom = top + (columns + 1)
                endpoints.append((top, bottom))
                dotEdges[top].append(endpoints.count - 1)
                dotEdges[bottom].append(endpoints.count - 1)
            }
        }
        self.edgesOfDot = dotEdges
        self.endpointsOfEdge = endpoints
        self.cluedCells = (0..<(rows * columns)).filter { clues.elements[$0] != nil }
    }

    public var cellCount: Int { size.cellCount }

    public func index(of position: Position) -> Int {
        position.row * size.columns + position.column
    }

    public func position(of index: Int) -> Position {
        Position(row: index / size.columns, column: index % size.columns)
    }

    public func clue(at cell: Int) -> Int? {
        clues.elements[cell]
    }

    /// Kenar yatay mı.
    public func isHorizontal(_ edge: Int) -> Bool {
        edge < horizontalCount
    }

    /// Noktanın ızgaradaki konumu. Nokta ızgarası hücre ızgarasından bir büyük.
    public func dotPosition(of dot: Int) -> Position {
        Position(row: dot / (size.columns + 1), column: dot % (size.columns + 1))
    }
}

extension SlitherlinkPuzzle: Hashable {
    // Türetilmiş alanlar karşılaştırmaya girmiyor: ipuçları aynıysa kenarlar da aynı.
    public static func == (lhs: SlitherlinkPuzzle, rhs: SlitherlinkPuzzle) -> Bool {
        lhs.clues == rhs.clues
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(clues)
    }
}
