/// Kafes boyutu ve seçilme ağırlığı.
///
/// Demet yerine ayrı tip: demetler `Hashable` sentezlemiyor ve yerleşimin karşılaştırılabilir
/// olması gerekiyor (testlerde ve ADR'deki ölçümde yerleşimler kimliğiyle anılıyor).
public struct CageSizeWeight: Hashable, Sendable {
    public let size: Int
    public let weight: Int

    public init(size: Int, weight: Int) {
        precondition(size > 0, "Kafes boyutu pozitif olmalı")
        precondition(weight > 0, "Ağırlık pozitif olmalı")
        self.size = size
        self.weight = weight
    }
}

/// Bir zorluk seviyesinin Calcudoku parametreleri.
///
/// ADR 0005 Calcudoku'da zorluğun iki eksenle ayarlanacağını yazıyor: boyut ve kafes yapısı.
/// Easy'de yalnız toplama ve çarpma, küçük kafesler; Expert'te dört işlem ve büyük kafesler.
public struct CalcudokuLayout: Hashable, Sendable {
    public let side: Int
    /// Kafes boyutu dağılımı: her eleman bir boyut ve ağırlığı.
    ///
    /// Tek hücreli kafes verilmiş değer demek, yani zorluğun en güçlü kolu bu. Büyük
    /// kafesler aritmetiği belirsizleştiriyor.
    public let cageSizeWeights: [CageSizeWeight]
    /// Çıkarma ve bölme kullanılsın mı. Easy'de kapalı (ADR 0005).
    public let allowsSubtractAndDivide: Bool
    /// Üç ve daha fazla hücreli kafeslerde çarpma seçme olasılığı (yüzde).
    ///
    /// Çarpma hedefleri büyük kafeslerde hızla büyüyor ve bileşim sayısını daraltıyor —
    /// yani aslında kolaylaştırıcı. Toplama daha belirsiz.
    public let multiplyPercent: Int

    public init(
        side: Int,
        cageSizeWeights: [CageSizeWeight],
        allowsSubtractAndDivide: Bool,
        multiplyPercent: Int
    ) {
        precondition((4...9).contains(side), "Calcudoku kenarı 4...9 aralığında (ADR 0005)")
        precondition(!cageSizeWeights.isEmpty, "Kafes boyutu dağılımı boş olamaz")
        self.side = side
        self.cageSizeWeights = cageSizeWeights
        self.allowsSubtractAndDivide = allowsSubtractAndDivide
        self.multiplyPercent = multiplyPercent
    }

    public static func standard(for difficulty: Difficulty) -> CalcudokuLayout {
        switch difficulty {
        case .easy:
            CalcudokuLayout(
                side: 4,
                cageSizeWeights: [
                    CageSizeWeight(size: 1, weight: 25),
                    CageSizeWeight(size: 2, weight: 75)
                ],
                allowsSubtractAndDivide: false,
                multiplyPercent: 50
            )
        case .medium:
            CalcudokuLayout(
                side: 5,
                cageSizeWeights: [
                    CageSizeWeight(size: 1, weight: 10),
                    CageSizeWeight(size: 2, weight: 60),
                    CageSizeWeight(size: 3, weight: 30)
                ],
                allowsSubtractAndDivide: true,
                multiplyPercent: 40
            )
        case .hard:
            CalcudokuLayout(
                side: 7,
                cageSizeWeights: [
                    CageSizeWeight(size: 2, weight: 50),
                    CageSizeWeight(size: 3, weight: 35),
                    CageSizeWeight(size: 4, weight: 15)
                ],
                allowsSubtractAndDivide: true,
                multiplyPercent: 30
            )
        case .expert:
            CalcudokuLayout(
                side: 8,
                cageSizeWeights: [
                    CageSizeWeight(size: 2, weight: 35),
                    CageSizeWeight(size: 3, weight: 40),
                    CageSizeWeight(size: 4, weight: 25)
                ],
                allowsSubtractAndDivide: true,
                multiplyPercent: 20
            )
        }
    }

    /// Dağılımdan bir kafes boyutu seçiyor.
    func sampleCageSize(using rng: inout SeededGenerator) -> Int {
        let total = cageSizeWeights.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total, using: &rng)
        for entry in cageSizeWeights {
            roll -= entry.weight
            if roll < 0 { return entry.size }
        }
        return cageSizeWeights[0].size
    }

    var maxCageSize: Int {
        cageSizeWeights.map(\.size).max() ?? 1
    }
}

/// Calcudoku üreticisi.
///
/// Hashi ve Hitori'de olduğu gibi bulmacayı değil çözümü kuruyor: Latin karesi önce, kafes
/// bölüntüsü sonra, hedefler çözümden türetiliyor. Kurulum gereği çıkan garanti: çözüm hem
/// Latin kısıtını hem bütün kafes hedeflerini tutuyor. Kalan tek soru benzersizlik ve ona
/// hat karar veriyor.
public struct CalcudokuGenerator: PuzzleGenerator {
    public typealias Definition = CalcudokuPuzzle
    public typealias Solution = CalcudokuSolution

    public let variant: PuzzleVariantID = .calcudoku
    public let solver: CalcudokuSolver
    public let layouts: [Difficulty: CalcudokuLayout]
    /// Expert sayılmak için gereken en küçük ızgara kenarı.
    ///
    /// Calcudoku'da Hard ile Expert'i teknik seviyesiyle ayırmak mümkün olmadı: ölçümde iki
    /// yerleşim de bol bol `advanced` üretiyor ve ne varsayım sayısı ne mantıksal ilerleme
    /// ikisini güvenilir biçimde ayırıyor (ADR 0012). Bu yüzden `advanced` içindeki ayrım
    /// boyuta bakıyor — ADR 0005'in "boyut, zorluğun çerçevesi" kuralıyla uyumlu olarak.
    ///
    /// Teknik seviyesi yine birincil: 8×8 bir bulmaca yalnız temel tekniklerle çözülüyorsa
    /// Easy sayılıyor ve Expert hedefinde eleniyor. Brief b.6'nın engellemek istediği şey
    /// buydu — "Expert diye açtığı bulmaca kolay çıkarsa yorumda yazar".
    public let expertMinimumSide: Int
    /// Expert sayılmak için mantıksal ilerlemenin kalması gereken üst sınır.
    ///
    /// Boyut tek başına yetmesin diye: büyük ızgarada olup da mantığın neredeyse bitirdiği
    /// bir bulmaca Expert değil Hard. Ölçümde Expert yerleşiminin tamamı %30'un altında
    /// kalıyor, eşik payla %35'te.
    public let expertProgressCeiling: Double

    public init(
        solver: CalcudokuSolver = CalcudokuSolver(),
        layouts: [Difficulty: CalcudokuLayout]? = nil,
        expertMinimumSide: Int = 8,
        expertProgressCeiling: Double = 0.35
    ) {
        self.solver = solver
        self.layouts = layouts ?? Dictionary(
            uniqueKeysWithValues: Difficulty.allCases.map { ($0, CalcudokuLayout.standard(for: $0)) }
        )
        self.expertMinimumSide = expertMinimumSide
        self.expertProgressCeiling = expertProgressCeiling
    }

    public func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> CalcudokuPuzzle {
        try candidate(difficulty: difficulty, using: &rng).puzzle
    }

    /// Kurulan çözümü de döndüren üretim.
    public func candidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> (puzzle: CalcudokuPuzzle, solution: CalcudokuSolution) {
        guard let layout = layouts[difficulty] else {
            throw GenerationError.invalidCandidate(reason: "\(difficulty) için yerleşim yok")
        }

        let values = LatinSquare.random(side: layout.side, using: &rng)
        let groups = Self.partition(layout: layout, using: &rng)
        let cages = groups.map { Self.makeCage($0, values: values, layout: layout, using: &rng) }

        return (
            CalcudokuPuzzle(side: layout.side, cages: cages),
            CalcudokuSolution(values: values)
        )
    }

    /// `guessing` reddediliyor, Expert `advanced` içinden varsayım sayısıyla ayrılıyor —
    /// gerekçeler ADR 0010'da.
    private func isExpert(_ definition: CalcudokuPuzzle) -> Bool {
        guard definition.side >= expertMinimumSide else { return false }
        return solver.logicalProgress(of: definition) < expertProgressCeiling
    }

    public func rate(_ trace: SolveTrace, of definition: CalcudokuPuzzle) -> Difficulty? {
        switch trace.highestTier {
        case .basic: .easy
        case .intermediate: .medium
        case .advanced:
            isExpert(definition) ? .expert : .hard
        case .guessing: nil
        }
    }
}

// MARK: - Kurulum

extension CalcudokuGenerator {
    /// Izgarayı bağlı kafeslere bölüyor.
    ///
    /// Rastgele bir hücreden başlayıp komşularına doğru büyüyor. Hedef boyuta ulaşamazsa
    /// (etrafı dolmuşsa) elde olanla kalıyor — bu yüzden gerçek boyut dağılımı yerleşimdeki
    /// ağırlıklardan biraz sapıyor ve ölçümde raporlanıyor (ADR 0012).
    static func partition(
        layout: CalcudokuLayout,
        using rng: inout SeededGenerator
    ) -> [[Int]] {
        let cellCount = layout.side * layout.side
        var owner = [Int](repeating: -1, count: cellCount)
        var groups: [[Int]] = []

        var order = Array(0..<cellCount)
        order.shuffle(using: &rng)

        for seed in order where owner[seed] < 0 {
            let target = layout.sampleCageSize(using: &rng)
            var group = [seed]
            owner[seed] = groups.count

            while group.count < target {
                let options = group
                    .flatMap { neighbors(of: $0, side: layout.side) }
                    .filter { owner[$0] < 0 }
                guard !options.isEmpty else { break }
                let pick = options[Int.random(in: 0..<options.count, using: &rng)]
                owner[pick] = groups.count
                group.append(pick)
            }
            groups.append(group)
        }
        return groups
    }

    private static func neighbors(of cell: Int, side: Int) -> [Int] {
        let row = cell / side
        let column = cell % side
        var result: [Int] = []
        if row > 0 { result.append(cell - side) }
        if row < side - 1 { result.append(cell + side) }
        if column > 0 { result.append(cell - 1) }
        if column < side - 1 { result.append(cell + 1) }
        return result
    }

    /// Kafesin hedefini ve işlemini çözümden türetiyor.
    static func makeCage(
        _ cells: [Int],
        values: Grid<Int>,
        layout: CalcudokuLayout,
        using rng: inout SeededGenerator
    ) -> CalcudokuCage {
        let side = layout.side
        let members = cells.map { values[$0 / side, $0 % side] }

        guard cells.count > 1 else {
            return CalcudokuCage(cells: cells, target: members[0], operation: .given)
        }

        if cells.count == 2, layout.allowsSubtractAndDivide {
            let high = max(members[0], members[1])
            let low = min(members[0], members[1])
            // Bölme yalnız tam bölünüyorsa; aksi halde çıkarmaya düşüyor.
            let twoCellOptions: [CageOperation] = high % low == 0
                ? [.add, .multiply, .subtract, .divide]
                : [.add, .multiply, .subtract]
            let operation = twoCellOptions[Int.random(in: 0..<twoCellOptions.count, using: &rng)]
            return CalcudokuCage(cells: cells, target: target(for: operation, members), operation: operation)
        }

        let useMultiply = Int.random(in: 0..<100, using: &rng) < layout.multiplyPercent
        let operation: CageOperation = useMultiply ? .multiply : .add
        return CalcudokuCage(cells: cells, target: target(for: operation, members), operation: operation)
    }

    private static func target(for operation: CageOperation, _ members: [Int]) -> Int {
        switch operation {
        case .given: members[0]
        case .add: members.reduce(0, +)
        case .multiply: members.reduce(1, *)
        case .subtract: abs(members[0] - members[1])
        case .divide: max(members[0], members[1]) / min(members[0], members[1])
        }
    }
}

extension CalcudokuGenerator {
    /// Ölçülen elenme oranlarına göre ayarlanmış üretim hattı (ADR 0012).
    public static func pipeline(
        _ generator: CalcudokuGenerator = CalcudokuGenerator()
    ) -> GenerationPipeline<CalcudokuGenerator> {
        GenerationPipeline(generator: generator, maxAttempts: 2500)
    }
}
