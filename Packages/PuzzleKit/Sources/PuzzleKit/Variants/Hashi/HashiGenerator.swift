/// Bir zorluk seviyesinin ızgara ve yoğunluk parametreleri.
///
/// Boyutlar ADR 0005'teki tablodan. Diğer parametreler Faz 1'de ölçümle ayarlandı;
/// gerekçeleri ve ölçülen dağılım ADR 0010'da.
public struct HashiLayout: Hashable, Sendable {
    public let size: GridSize
    /// Hedeflenen ada sayısı. Yerleşim sıkışırsa daha az adayla da bitebilir.
    public let islandTarget: Int
    /// Bir köprünün en fazla kaç hücre uzanabileceği.
    public let maxSpan: Int
    /// Yeni köprünün çifte olma olasılığı, yüzde.
    public let doubleBridgePercent: Int
    /// Mevcut adalar arasına ek köprü deneme sayısı. Döngü yaratıyor, bulmacayı zorlaştırıyor.
    public let extraLinkAttempts: Int

    public init(
        size: GridSize,
        islandTarget: Int,
        maxSpan: Int,
        doubleBridgePercent: Int,
        extraLinkAttempts: Int
    ) {
        self.size = size
        self.islandTarget = islandTarget
        self.maxSpan = maxSpan
        self.doubleBridgePercent = doubleBridgePercent
        self.extraLinkAttempts = extraLinkAttempts
    }

    /// Faz 1'de ölçümle seçilen yerleşimler. Izgara boyutları ADR 0005'ten, diğer
    /// parametreler ölçülen teknik seviyesi dağılımından (ADR 0010).
    public static func standard(for difficulty: Difficulty) -> HashiLayout {
        switch difficulty {
        case .easy:
            HashiLayout(
                size: GridSize(square: 7), islandTarget: 10, maxSpan: 4,
                doubleBridgePercent: 30, extraLinkAttempts: 4
            )
        case .medium:
            HashiLayout(
                size: GridSize(square: 9), islandTarget: 13, maxSpan: 6,
                doubleBridgePercent: 45, extraLinkAttempts: 6
            )
        case .hard:
            HashiLayout(
                size: GridSize(square: 11), islandTarget: 24, maxSpan: 9,
                doubleBridgePercent: 45, extraLinkAttempts: 6
            )
        case .expert:
            HashiLayout(
                size: GridSize(square: 13), islandTarget: 30, maxSpan: 6,
                doubleBridgePercent: 45, extraLinkAttempts: 6
            )
        }
    }
}

/// Hashi üreticisi.
///
/// Bulmacayı değil **çözümü** kuruyor: bir adadan başlayıp köprü çekerek ağı büyütüyor,
/// sonra her adanın derecesini ipucu olarak yazıyor. Tersi — önce ipuçlarını atıp sonra
/// çözüm aramak — çoğu denemede çözümsüz bulmaca üretir ve elenme oranını kullanılamaz
/// hale getirir.
///
/// Kurulum gereği çıkan üç garanti: ağ bağlı, köprüler kesişmiyor, dereceler çözümle
/// tutarlı. Kalan tek soru benzersizlik ve ona hat karar veriyor (`GenerationPipeline`).
public struct HashiGenerator: PuzzleGenerator {
    public typealias Definition = HashiPuzzle
    public typealias Solution = HashiSolution

    public let variant: PuzzleVariantID = .hashi
    public let solver: HashiSolver
    /// Zorluk → yerleşim eşlemesi. Testlerde ve ölçümde değiştirilebilir olsun diye dışarıda.
    public let layouts: [Difficulty: HashiLayout]
    /// `advanced` seviyedeki bulmacayı Expert saymak için gereken en az varsayım sayısı.
    ///
    /// Hard ve Expert'in ikisi de ileri teknik gerektiriyor; aralarındaki fark o tekniğin
    /// kaç kez gerektiği. Toplam adım sayısı kullanılmıyor: o büyük ölçüde ızgara boyutunu
    /// yansıtıyor, zorluğu değil. Değer ADR 0010'da ölçümle belirlendi.
    public let expertHypothesisThreshold: Int

    public init(
        solver: HashiSolver = HashiSolver(),
        layouts: [Difficulty: HashiLayout]? = nil,
        expertHypothesisThreshold: Int = 2
    ) {
        self.solver = solver
        self.layouts = layouts ?? Dictionary(
            uniqueKeysWithValues: Difficulty.allCases.map { ($0, HashiLayout.standard(for: $0)) }
        )
        self.expertHypothesisThreshold = expertHypothesisThreshold
    }

    public func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> HashiPuzzle {
        try candidate(difficulty: difficulty, using: &rng).puzzle
    }

    /// Kurulan çözümü de döndüren üretim. Testler kurulan çözümle çözücünün bulduğunu
    /// karşılaştırabilsin diye ayrı.
    public func candidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> (puzzle: HashiPuzzle, solution: HashiSolution) {
        guard let layout = layouts[difficulty] else {
            throw GenerationError.invalidCandidate(reason: "\(difficulty) için yerleşim yok")
        }

        var builder = Builder(size: layout.size)
        builder.seedFirstIsland(using: &rng)
        builder.grow(to: layout.islandTarget, layout: layout, using: &rng)
        builder.addExtraLinks(layout: layout, using: &rng)

        guard builder.islands.count >= 4 else {
            throw GenerationError.invalidCandidate(
                reason: "Yerleşim sıkıştı, yalnız \(builder.islands.count) ada kuruldu"
            )
        }
        return builder.finish()
    }

    /// Teknik seviyesini Hashi'nin zorluk ölçeğine çeviriyor.
    ///
    /// İki yerde varsayılandan ayrılıyor, gerekçeler ADR 0010'da:
    ///
    /// - `guessing` reddediliyor. Tek çözümü olan bir bulmaca da mantıkla çözülemeyebilir
    ///   ve rakip analizinde (PR #10) en can alıcı şikâyet buydu: zor seviyelerde mantığın
    ///   bitip tahmin gerekmesi. Böyle bir bulmaca hiçbir zorluğa ait değil, atılıyor.
    /// - Hard ile Expert ikisi de ileri teknik gerektiriyor; aralarındaki ayrım o tekniğin
    ///   kaç kez gerektiği.
    public func rate(_ trace: SolveTrace, of definition: HashiPuzzle) -> Difficulty? {
        switch trace.highestTier {
        case .basic: .easy
        case .intermediate: .medium
        case .advanced:
            trace.count(of: "hypothesis") >= expertHypothesisThreshold ? .expert : .hard
        case .guessing: nil
        }
    }
}

// MARK: - Kurucu

extension HashiGenerator {
    /// Çözümü adım adım kuran yardımcı. Hücre doluluk tablosu tutuyor, böylece köprülerin
    /// kesişmesi ve adaların yan yana düşmesi kurulum sırasında imkânsız.
    struct Builder {
        enum Occupancy: Equatable {
            case empty
            case island(Int)
            case bridge
        }

        enum Terminator: Equatable {
            case island(Int, distance: Int)
            case blocked
        }

        let size: GridSize
        var occupancy: Grid<Occupancy>
        var islands: [Position] = []
        var degrees: [Int] = []
        /// Ada çifti → köprü sayısı. Anahtar her zaman (küçük, büyük).
        var bridges: [Pair: Int] = [:]

        struct Pair: Hashable {
            let a: Int
            let b: Int

            init(_ first: Int, _ second: Int) {
                a = min(first, second)
                b = max(first, second)
            }
        }

        static let directions: [(rows: Int, columns: Int)] = [
            (-1, 0), (1, 0), (0, -1), (0, 1)
        ]

        init(size: GridSize) {
            self.size = size
            self.occupancy = Grid(size: size, repeating: .empty)
        }

        mutating func seedFirstIsland(using rng: inout SeededGenerator) {
            let row = Int.random(in: 0..<size.rows, using: &rng)
            let column = Int.random(in: 0..<size.columns, using: &rng)
            place(at: Position(row: row, column: column))
        }

        /// Var olan bir adadan köprü çekerek yeni ada ekler.
        mutating func grow(to target: Int, layout: HashiLayout, using rng: inout SeededGenerator) {
            // Deneme üst sınırı: yerleşim sıkıştığında sonsuz döngüye girmesin. Çarpan
            // ölçümle seçildi; büyütülmesi süreyi artırıyor, ada sayısını artırmıyor.
            var attempts = 0
            let limit = target * 40

            while islands.count < target && attempts < limit {
                attempts += 1
                let from = Int.random(in: 0..<islands.count, using: &rng)
                guard degrees[from] < 8 else { continue }
                let direction = Self.directions[Int.random(in: 0..<4, using: &rng)]

                let run = emptyRun(from: islands[from], direction: direction, limit: layout.maxSpan)
                guard run >= 2 else { continue }
                let distance = Int.random(in: 2...run, using: &rng)
                let position = islands[from].offset(
                    byRows: direction.rows * distance,
                    columns: direction.columns * distance
                )
                guard canPlaceIsland(at: position) else { continue }

                let count = bridgeCount(from: from, to: nil, layout: layout, using: &rng)
                let new = place(at: position)
                connect(from, new, count: count, direction: direction, distance: distance)
            }
        }

        /// Var olan adalar arasına ek köprü ekler. Döngü yaratıyor; bulmacayı zorlaştıran
        /// ve ileri teknik gerektiren şey bu.
        mutating func addExtraLinks(layout: HashiLayout, using rng: inout SeededGenerator) {
            var attempts = 0
            let limit = layout.extraLinkAttempts * 8
            var added = 0

            while added < layout.extraLinkAttempts && attempts < limit {
                attempts += 1
                let from = Int.random(in: 0..<islands.count, using: &rng)
                guard degrees[from] < 8 else { continue }
                let direction = Self.directions[Int.random(in: 0..<4, using: &rng)]

                guard case .island(let to, let distance) = scan(
                    from: islands[from],
                    direction: direction,
                    limit: size.rows + size.columns
                ) else { continue }
                guard distance >= 2, degrees[to] < 8 else { continue }
                guard bridges[Pair(from, to)] == nil else { continue }

                let count = bridgeCount(from: from, to: to, layout: layout, using: &rng)
                connect(from, to, count: count, direction: direction, distance: distance)
                added += 1
            }
        }

        func finish() -> (puzzle: HashiPuzzle, solution: HashiSolution) {
            let puzzle = HashiPuzzle(
                size: size,
                islands: islands.indices.map {
                    HashiIsland(position: islands[$0], required: degrees[$0])
                }
            )
            // Kurulan köprüleri bulmacanın kenar indekslemesine taşı. Kurulumda köprü
            // yalnız boş hücrelerden geçtiği için bağladığı iki ada o satır/sütunda komşu;
            // yani her köprünün karşılığı bir kenar var.
            let counts = puzzle.edges.map { bridges[Pair($0.a, $0.b)] ?? 0 }
            return (puzzle, HashiSolution(counts: counts))
        }

        // MARK: - Yardımcılar

        private mutating func bridgeCount(
            from: Int,
            to: Int?,
            layout: HashiLayout,
            using rng: inout SeededGenerator
        ) -> Int {
            let headroom = min(8 - degrees[from], to.map { 8 - degrees[$0] } ?? 8)
            guard headroom >= 2 else { return 1 }
            return Int.random(in: 0..<100, using: &rng) < layout.doubleBridgePercent ? 2 : 1
        }

        @discardableResult
        private mutating func place(at position: Position) -> Int {
            islands.append(position)
            degrees.append(0)
            occupancy[position] = .island(islands.count - 1)
            return islands.count - 1
        }

        private mutating func connect(
            _ from: Int,
            _ to: Int,
            count: Int,
            direction: (rows: Int, columns: Int),
            distance: Int
        ) {
            for step in 1..<distance {
                let cell = islands[from].offset(
                    byRows: direction.rows * step,
                    columns: direction.columns * step
                )
                occupancy[cell] = .bridge
            }
            bridges[Pair(from, to), default: 0] += count
            degrees[from] += count
            degrees[to] += count
        }

        /// Adadan verilen yönde kaç boş hücre var.
        private func emptyRun(
            from origin: Position,
            direction: (rows: Int, columns: Int),
            limit: Int
        ) -> Int {
            var run = 0
            for step in 1...limit {
                let cell = origin.offset(byRows: direction.rows * step, columns: direction.columns * step)
                guard occupancy.element(at: cell) == .empty else { break }
                run += 1
            }
            return run
        }

        /// Adadan verilen yönde ilk karşılaşılan şey: başka bir ada mı, engel mi.
        private func scan(
            from origin: Position,
            direction: (rows: Int, columns: Int),
            limit: Int
        ) -> Terminator {
            for step in 1...limit {
                let cell = origin.offset(byRows: direction.rows * step, columns: direction.columns * step)
                switch occupancy.element(at: cell) {
                case .empty:
                    continue
                case .island(let index):
                    return .island(index, distance: step)
                case .bridge, .none:
                    return .blocked
                }
            }
            return .blocked
        }

        /// Yeni ada konabilir mi: hücre boş ve komşularında ada yok.
        ///
        /// Komşuluk yasağı `HashiPuzzle`'ın da ön koşulu; burada ihlal edilirse bulmaca
        /// kurulurken çöker.
        private func canPlaceIsland(at position: Position) -> Bool {
            guard occupancy.element(at: position) == .empty else { return false }
            for neighbor in position.orthogonalNeighbors {
                if case .island = occupancy.element(at: neighbor) { return false }
            }
            return true
        }
    }
}

extension HashiGenerator {
    /// Ölçülen elenme oranlarına göre ayarlanmış üretim hattı.
    ///
    /// Deneme sınırı hattın varsayılanından (500) yüksek. Sebebi hız değil varyans: Expert'te
    /// kabul oranı ölçümde %5 civarında ve 500 denemede tükenme olasılığı ihmal edilebilir
    /// olsa da, bir aday başına ~0,2 ms maliyetle 2500 deneme hâlâ yarım saniyenin altında —
    /// yani payı almanın bedeli yok. Ayrıntı ADR 0010'da.
    public static func pipeline(
        _ generator: HashiGenerator = HashiGenerator()
    ) -> GenerationPipeline<HashiGenerator> {
        GenerationPipeline(generator: generator, maxAttempts: 2500)
    }
}
