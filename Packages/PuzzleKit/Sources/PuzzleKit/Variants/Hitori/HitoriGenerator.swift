/// Bir zorluk seviyesinin Hitori parametreleri.
///
/// Boyutlar ADR 0005'teki tablodan. `adjacentDuplicatePercent` Faz 2'de ölçümle ayarlandı;
/// gerekçesi ve ölçülen dağılım ADR 0011'de.
public struct HitoriLayout: Hashable, Sendable {
    public let size: GridSize
    /// `# b #` deseninde iki karalı komşuya ortadaki beyazın değerini verme olasılığı (yüzde).
    ///
    /// Zorluğun asıl kolu bu ve neden olduğu ölçümle anlaşıldı (ADR 0011). İki üyeli bir grup
    /// hiçbir çıkarım vermiyor: "biri beyaz kalmak zorunda" demek, hangisi olduğunu
    /// söylemiyor. Çıkarım ancak grup üç üyeye çıktığında başlıyor — ve bu desen tam olarak
    /// klasik "üçlü": yan yana üç aynı sayıda ortadaki beyaz, dıştakiler karalı.
    public let triplePercent: Int
    /// Kalan karalı hücrelerin değerini komşu bir beyazdan kopyalama olasılığı (yüzde).
    public let adjacentDuplicatePercent: Int
    /// Her beyaz hücrenin karalı bir komşusu olması şartı.
    ///
    /// Şart sağlanmazsa bazı beyazlar yalnız bağlılıkla tutturulmuş olur ("karalasam bölge
    /// kopar") ve bulmaca en az orta seviye olur. Temel tekniklerle açılan bir bulmaca
    /// istiyorsak desen bütün beyazları komşulukla tutturmak zorunda.
    public let requireDominatedWhites: Bool

    public init(
        size: GridSize,
        triplePercent: Int,
        adjacentDuplicatePercent: Int,
        requireDominatedWhites: Bool = false
    ) {
        precondition(size.isSquare, "Hitori ızgarası kare olmalı")
        self.size = size
        self.triplePercent = triplePercent
        self.adjacentDuplicatePercent = adjacentDuplicatePercent
        self.requireDominatedWhites = requireDominatedWhites
    }

    public static func standard(for difficulty: Difficulty) -> HitoriLayout {
        switch difficulty {
        case .easy:
            HitoriLayout(
                size: GridSize(square: 5), triplePercent: 100,
                adjacentDuplicatePercent: 90, requireDominatedWhites: true
            )
        case .medium:
            HitoriLayout(size: GridSize(square: 7), triplePercent: 70, adjacentDuplicatePercent: 60)
        case .hard:
            HitoriLayout(size: GridSize(square: 9), triplePercent: 30, adjacentDuplicatePercent: 30)
        case .expert:
            HitoriLayout(size: GridSize(square: 11), triplePercent: 0, adjacentDuplicatePercent: 10)
        }
    }
}

/// Hitori üreticisi.
///
/// Hashi'de olduğu gibi bulmacayı değil **çözümü** kuruyor: önce karalama desenini, sonra
/// sayı ızgarasını. Ama kritik fark burada ve çözücüyü yazarken ortaya çıktı (PR #19):
///
/// Hitori'nin kuralları yalnız **beyazlarda** tekrarı yasaklıyor; karalı hücrenin tekrar
/// olması zorunlu değil. Yani hiçbir gruba girmeyen bir hücre, komşuluk ve bağlılık izin
/// verdiği sürece serbestçe karalanabilir. Benzersizlik bu yüzden değerlerden değil
/// **karalama deseninin sıkılığından** geliyor: her beyaz hücrenin ya karalı bir komşusu
/// olmalı (karalanırsa komşuluk ihlali) ya da beyaz bölgenin kesme noktası olmalı
/// (karalanırsa bölge kopar).
///
/// Bu yüzden desen **maksimal** kuruluyor: artık hiçbir hücre eklenemeyene kadar karalanıyor.
/// Maksimallik iki işi birden yapıyor — fazladan karalamayı imkânsız kılıyor, ve bir karalıyı
/// beyaza çevirip onun yerine bir beyazı karalama takasını da engelliyor.
public struct HitoriGenerator: PuzzleGenerator {
    public typealias Definition = HitoriPuzzle
    public typealias Solution = HitoriSolution

    public let variant: PuzzleVariantID = .hitori
    public let solver: HitoriSolver
    public let layouts: [Difficulty: HitoriLayout]
    /// `advanced` seviyedeki bulmacayı Expert saymak için gereken en az varsayım sayısı
    /// (ADR 0010'daki gerekçeyle aynı).
    public let expertHypothesisThreshold: Int

    public init(
        solver: HitoriSolver = HitoriSolver(),
        layouts: [Difficulty: HitoriLayout]? = nil,
        expertHypothesisThreshold: Int = 2
    ) {
        self.solver = solver
        self.layouts = layouts ?? Dictionary(
            uniqueKeysWithValues: Difficulty.allCases.map { ($0, HitoriLayout.standard(for: $0)) }
        )
        self.expertHypothesisThreshold = expertHypothesisThreshold
    }

    public func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> HitoriPuzzle {
        try candidate(difficulty: difficulty, using: &rng).puzzle
    }

    /// Kurulan çözümü de döndüren üretim.
    public func candidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> (puzzle: HitoriPuzzle, solution: HitoriSolution) {
        guard let layout = layouts[difficulty] else {
            throw GenerationError.invalidCandidate(reason: "\(difficulty) için yerleşim yok")
        }

        let latin = LatinSquare.random(side: layout.size.rows, using: &rng)
        let mask = Self.shading(for: layout, using: &rng)
        let values = Self.assignValues(latin: latin, mask: mask, layout: layout, using: &rng)

        return (HitoriPuzzle(values: values), HitoriSolution(shaded: mask))
    }

    /// `guessing` reddediliyor, Expert `advanced` içinden varsayım sayısıyla ayrılıyor —
    /// gerekçeler ADR 0010'da, Hashi'yle aynı.
    public func rate(_ trace: SolveTrace, of definition: HitoriPuzzle) -> Difficulty? {
        switch trace.highestTier {
        case .basic: .easy
        case .intermediate: .medium
        case .advanced:
            trace.count(of: "hypothesis") >= expertHypothesisThreshold ? .expert : .hard
        case .guessing: nil
        }
    }
}

// MARK: - Kurulum

extension HitoriGenerator {
    /// Yerleşimin istediği karalama deseni.
    ///
    /// `requireDominatedWhites` açıksa, bütün beyazların karalı bir komşusu olana kadar
    /// yeniden deniyor. Deneme sınırı var: bazı ızgara boyutlarında böyle bir desen hiç
    /// bulunamayabilir ve o zaman elde olanla devam ediliyor — hat zaten zorluk eşleşmesine
    /// bakıyor, yanlış zorlukta bir aday sessizce geçmiyor.
    static func shading(for layout: HitoriLayout, using rng: inout SeededGenerator) -> Grid<Bool> {
        var fallback = maximalShading(size: layout.size, using: &rng)
        guard layout.requireDominatedWhites else { return fallback }

        for _ in 0..<40 {
            if allWhitesHaveShadedNeighbor(fallback) { return fallback }
            fallback = maximalShading(size: layout.size, using: &rng)
        }
        return fallback
    }

    /// Her beyaz hücrenin karalı bir komşusu var mı.
    static func allWhitesHaveShadedNeighbor(_ mask: Grid<Bool>) -> Bool {
        for position in mask.allPositions where !mask[position] {
            let dominated = position.orthogonalNeighbors.contains { mask.element(at: $0) == true }
            guard dominated else { return false }
        }
        return true
    }

    /// Maksimal karalama deseni: beyazlar bağlı kalacak şekilde, artık hiçbir hücre
    /// eklenemeyene kadar karalanıyor.
    ///
    /// Geçiş bittiğinde her beyaz hücre ya karalı bir komşuya sahip ya da beyaz bölgenin
    /// kesme noktası — ikisi de o hücrenin karalanmasını imkânsız kılıyor. Benzersizliğin
    /// dayanağı bu.
    static func maximalShading(size: GridSize, using rng: inout SeededGenerator) -> Grid<Bool> {
        var mask = Grid(size: size, repeating: false)
        var order = size.allPositions
        order.shuffle(using: &rng)

        for position in order {
            let hasShadedNeighbor = position.orthogonalNeighbors.contains { neighbor in
                mask.element(at: neighbor) == true
            }
            guard !hasShadedNeighbor else { continue }

            mask[position] = true
            if !whitesStayConnected(mask) {
                mask[position] = false
            }
        }
        return mask
    }

    /// Karalama deseninde beyazlar tek bölgede mi. Testler de bunu kullanıyor: deseninin
    /// maksimal olduğunu doğrulamak için "bu hücre karalanırsa kopar mı" sorusu gerekiyor.
    static func whitesStayConnected(_ mask: Grid<Bool>) -> Bool {
        guard let start = mask.allPositions.first(where: { !mask[$0] }) else { return false }

        var seen = Grid(size: mask.size, repeating: false)
        var stack = [start]
        seen[start] = true
        var visited = 1
        while let position = stack.popLast() {
            for neighbor in mask.neighbors(of: position) where !mask[neighbor] && !seen[neighbor] {
                seen[neighbor] = true
                visited += 1
                stack.append(neighbor)
            }
        }

        let whiteCount = mask.elements.count { !$0 }
        return visited == whiteCount
    }

    /// Karalı hücrelere, satır veya sütunlarındaki bir beyazın değerini veriyor.
    ///
    /// Sebebi: karalı hücre hiçbir tekrarın parçası olmazsa onu karalamak için sebep kalmıyor
    /// ve bulmaca çok çözümlü çıkıyor. Komşu bir beyazdan kopyalamak çıkarımı kolaylaştırıyor,
    /// uzaktan kopyalamak zorlaştırıyor — zorluğun kolu bu (`adjacentDuplicatePercent`).
    static func assignValues(
        latin: Grid<Int>,
        mask: Grid<Bool>,
        layout: HitoriLayout,
        using rng: inout SeededGenerator
    ) -> Grid<Int> {
        let seeded = seedTriples(latin: latin, mask: mask, layout: layout, using: &rng)
        var values = seeded.values
        let assigned = seeded.assigned

        for position in mask.allPositions where mask[position] && !assigned[position] {
            let partners = whitePartners(of: position, mask: mask)
            guard !partners.isEmpty else { continue }

            let preferAdjacent = Int.random(in: 0..<100, using: &rng) < layout.adjacentDuplicatePercent
            let adjacent = partners.filter { $0.isOrthogonalNeighbor(of: position) }
            let pool = preferAdjacent && !adjacent.isEmpty ? adjacent : partners
            let chosen = pool[Int.random(in: 0..<pool.count, using: &rng)]
            values[position] = latin[chosen]
        }
        return values
    }

    /// `karalı · beyaz · karalı` dizilimine ortadaki beyazın değerini vererek klasik üçlüyü
    /// kuruyor. Çözücünün ilk hamlesini buradan buluyor: üçlünün ortası beyaz, dıştakiler
    /// karalı — ve o karalılar komşularını beyaz yapıp çıkarım zincirini başlatıyor.
    private static func seedTriples(
        latin: Grid<Int>,
        mask: Grid<Bool>,
        layout: HitoriLayout,
        using rng: inout SeededGenerator
    ) -> (values: Grid<Int>, assigned: Grid<Bool>) {
        var values = latin
        var assigned = Grid(size: mask.size, repeating: false)
        guard layout.triplePercent > 0 else { return (values, assigned) }
        var whites = mask.allPositions.filter { !mask[$0] }
        whites.shuffle(using: &rng)

        for white in whites {
            for axis in [(rows: 0, columns: 1), (rows: 1, columns: 0)] {
                let before = white.offset(byRows: -axis.rows, columns: -axis.columns)
                let after = white.offset(byRows: axis.rows, columns: axis.columns)
                guard
                    mask.element(at: before) == true,
                    mask.element(at: after) == true,
                    !assigned[before], !assigned[after]
                else { continue }
                guard Int.random(in: 0..<100, using: &rng) < layout.triplePercent else { continue }

                values[before] = latin[white]
                values[after] = latin[white]
                assigned[before] = true
                assigned[after] = true
            }
        }
        return (values, assigned)
    }

    /// Aynı satır veya sütundaki beyaz hücreler.
    private static func whitePartners(of position: Position, mask: Grid<Bool>) -> [Position] {
        var result: [Position] = []
        for column in 0..<mask.size.columns where column != position.column {
            let candidate = Position(row: position.row, column: column)
            if !mask[candidate] { result.append(candidate) }
        }
        for row in 0..<mask.size.rows where row != position.row {
            let candidate = Position(row: row, column: position.column)
            if !mask[candidate] { result.append(candidate) }
        }
        return result
    }
}

extension HitoriGenerator {
    /// Ölçülen elenme oranlarına göre ayarlanmış üretim hattı (ADR 0011).
    public static func pipeline(
        _ generator: HitoriGenerator = HitoriGenerator()
    ) -> GenerationPipeline<HitoriGenerator> {
        GenerationPipeline(generator: generator, maxAttempts: 2500)
    }
}

extension Position {
    func isOrthogonalNeighbor(of other: Position) -> Bool {
        let rowDelta = abs(row - other.row)
        let columnDelta = abs(column - other.column)
        return rowDelta + columnDelta == 1
    }
}
