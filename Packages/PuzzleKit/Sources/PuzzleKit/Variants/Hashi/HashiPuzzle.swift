/// Hashi adası: konum ve o adadan çıkması gereken köprü sayısı.
public struct HashiIsland: Hashable, Sendable {
    public let position: Position
    /// Adadan çıkması gereken toplam köprü sayısı. En fazla 8: dört yön × en fazla 2 köprü.
    public let required: Int

    public init(position: Position, required: Int) {
        precondition((1...8).contains(required), "Ada derecesi 1...8 olmalı, gelen: \(required)")
        self.position = position
        self.required = required
    }
}

/// İki ada arasındaki olası köprü yeri.
///
/// Kenar, bulmaca tanımından türetilir ve oyun boyunca değişmez: değişen tek şey o kenarda
/// kaç köprü olduğu. Köprü sayısı tahtada, kenarla aynı indekste tutuluyor.
public struct HashiEdge: Hashable, Sendable {
    /// Ada indeksleri; her zaman `a < b`. Kanonik sıra, çözümlerin karşılaştırılabilir olması için.
    public let a: Int
    public let b: Int
    public let isHorizontal: Bool
    /// En fazla kaç köprü konabilir: `min(2, derece_a, derece_b)`.
    ///
    /// Derecesi 1 olan bir adaya iki köprü çekilemez; bunu kapasiteye yazmak çözücüde
    /// bütün bir yayılım adımını gereksiz kılıyor.
    public let capacity: Int
}

/// Hashi bulmacasının tanımı: ada yerleşimi ve dereceler.
///
/// Kenar ve kesişim listeleri kurucuda bir kez türetiliyor. Çözücü bunları milyonlarca kez
/// okuyacak; her çağrıda yeniden hesaplamak üretimi kullanılamaz hale getirir.
public struct HashiPuzzle: Sendable {
    public let size: GridSize
    public let islands: [HashiIsland]

    /// Olası köprü yerleri. Yalnızca aynı satır veya sütunda *komşu* ada çiftleri arasında
    /// kenar var: aralarında başka ada olan iki ada köprüyle bağlanamaz.
    public let edges: [HashiEdge]
    /// Ada indeksi → o adaya değen kenar indeksleri.
    public let incidentEdges: [[Int]]
    /// Kenar indeksi → o kenarla kesişen kenar indeksleri.
    public let crossingEdges: [[Int]]

    public init(size: GridSize, islands: [HashiIsland]) {
        precondition(!islands.isEmpty, "Bulmacada en az bir ada olmalı")
        for island in islands {
            precondition(size.contains(island.position), "Ada ızgara dışında: \(island.position)")
        }
        precondition(
            Set(islands.map(\.position)).count == islands.count,
            "Aynı konumda iki ada var"
        )
        // Komşu hücrelerde iki ada olamaz: aralarındaki köprünün uzunluğu sıfır olurdu ve
        // ekranda iki adanın yan yana durmasından ayırt edilemezdi.
        let occupied = Set(islands.map(\.position))
        for island in islands {
            for neighbor in island.position.orthogonalNeighbors where occupied.contains(neighbor) {
                preconditionFailure("Komşu hücrelerde iki ada: \(island.position) ve \(neighbor)")
            }
        }

        self.size = size
        self.islands = islands
        self.edges = Self.buildEdges(islands: islands)
        self.incidentEdges = Self.buildIncidence(edges: edges, islandCount: islands.count)
        self.crossingEdges = Self.buildCrossings(edges: edges, islands: islands)
    }

    public var islandCount: Int { islands.count }

    public func island(at position: Position) -> Int? {
        islands.firstIndex { $0.position == position }
    }

    /// Kenarın diğer ucundaki ada.
    public func otherIsland(of edge: Int, than island: Int) -> Int {
        let candidate = edges[edge]
        return candidate.a == island ? candidate.b : candidate.a
    }

    // MARK: - Türetme

    private static func buildEdges(islands: [HashiIsland]) -> [HashiEdge] {
        var result: [HashiEdge] = []
        let indices = islands.indices

        // Satır bazında: aynı satırdaki adalar sütuna göre sıralanır, komşu çiftler kenar olur.
        let byRow = Dictionary(grouping: indices) { islands[$0].position.row }
        for row in byRow.keys.sorted() {
            let sorted = byRow[row]!.sorted { islands[$0].position.column < islands[$1].position.column }
            for pair in zip(sorted, sorted.dropFirst()) {
                result.append(makeEdge(pair.0, pair.1, horizontal: true, islands: islands))
            }
        }

        let byColumn = Dictionary(grouping: indices) { islands[$0].position.column }
        for column in byColumn.keys.sorted() {
            let sorted = byColumn[column]!.sorted { islands[$0].position.row < islands[$1].position.row }
            for pair in zip(sorted, sorted.dropFirst()) {
                result.append(makeEdge(pair.0, pair.1, horizontal: false, islands: islands))
            }
        }

        // Kanonik sıra: kenar indeksleri tanımdan deterministik olarak türemeli, yoksa aynı
        // tohum farklı çözüm dizisi verir ve günlük bulmaca determinizmi bozulur.
        return result.sorted {
            ($0.isHorizontal ? 0 : 1, $0.a, $0.b) < ($1.isHorizontal ? 0 : 1, $1.a, $1.b)
        }
    }

    private static func makeEdge(
        _ first: Int,
        _ second: Int,
        horizontal: Bool,
        islands: [HashiIsland]
    ) -> HashiEdge {
        let a = min(first, second)
        let b = max(first, second)
        let capacity = min(2, islands[a].required, islands[b].required)
        return HashiEdge(a: a, b: b, isHorizontal: horizontal, capacity: capacity)
    }

    private static func buildIncidence(edges: [HashiEdge], islandCount: Int) -> [[Int]] {
        var result = Array(repeating: [Int](), count: islandCount)
        for (index, edge) in edges.enumerated() {
            result[edge.a].append(index)
            result[edge.b].append(index)
        }
        return result
    }

    private static func buildCrossings(edges: [HashiEdge], islands: [HashiIsland]) -> [[Int]] {
        var result = Array(repeating: [Int](), count: edges.count)
        let horizontal = edges.indices.filter { edges[$0].isHorizontal }
        let vertical = edges.indices.filter { !edges[$0].isHorizontal }

        for h in horizontal {
            let row = islands[edges[h].a].position.row
            let columns = [islands[edges[h].a].position.column, islands[edges[h].b].position.column]
            let left = columns.min()!
            let right = columns.max()!

            for v in vertical {
                let column = islands[edges[v].a].position.column
                let rows = [islands[edges[v].a].position.row, islands[edges[v].b].position.row]
                let top = rows.min()!
                let bottom = rows.max()!

                // Kesişim yalnızca kesin iç noktada olur. Uçlar ada olduğu için eşitlik
                // durumu kesişim değil; komşu ada yasağı sayesinde böyle bir durum da yok.
                if left < column && column < right && top < row && row < bottom {
                    result[h].append(v)
                    result[v].append(h)
                }
            }
        }
        return result
    }
}

extension HashiPuzzle: Hashable {
    // Türetilmiş alanlar karşılaştırmaya girmiyor: boyut ve adalar aynıysa kenarlar da aynı.
    public static func == (lhs: HashiPuzzle, rhs: HashiPuzzle) -> Bool {
        lhs.size == rhs.size && lhs.islands == rhs.islands
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(size)
        hasher.combine(islands)
    }
}
