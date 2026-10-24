/// Bir zorluk seviyesinin Slitherlink parametreleri.
public struct SlitherlinkLayout: Hashable, Sendable {
    public let size: GridSize
    /// Döngünün içinde hedeflenen hücre oranı (yüzde).
    ///
    /// Çok küçük döngü bulmacayı boşaltıyor, çok büyük döngü ızgaranın kenarına yapışıp
    /// ipuçlarını tek biçimli yapıyor; ikisi de benzersizliği zorlaştırıyor.
    public let insidePercent: Int
    /// Kabul etmeden önce silinmesi gereken en az ipucu oranı (yüzde).
    ///
    /// Bütün ipuçlar verilmiş bir bulmaca kurallara uygun ve benzersiz ama oynanacak bir şey
    /// bırakmıyor: her hücre kendi kenarlarını söylüyor. Yayınlanmış Slitherlink hücrelerin
    /// yarısına yakınını boş bırakıyor.
    public let minimumRemovalPercent: Int
    public init(
        size: GridSize,
        insidePercent: Int,
        minimumRemovalPercent: Int = 35
    ) {
        self.size = size
        self.insidePercent = insidePercent
        self.minimumRemovalPercent = minimumRemovalPercent
    }

    public static func standard(for difficulty: Difficulty) -> SlitherlinkLayout {
        switch difficulty {
        // Silme eşiği zorlukla yükseliyor. Kabul, hedef zorluğa ulaşılan **ilk** noktada
        // olduğu için eşik aynı zamanda ipucu yoğunluğunu belirliyor: eşik düşükse bulmaca
        // doğru seviyede ama gereğinden kalabalık çıkıyor.
        case .easy:
            SlitherlinkLayout(size: GridSize(square: 6), insidePercent: 45, minimumRemovalPercent: 35)
        case .medium:
            SlitherlinkLayout(size: GridSize(square: 8), insidePercent: 45, minimumRemovalPercent: 45)
        case .hard:
            SlitherlinkLayout(size: GridSize(square: 10), insidePercent: 45, minimumRemovalPercent: 52)
        case .expert:
            SlitherlinkLayout(size: GridSize(square: 12), insidePercent: 45, minimumRemovalPercent: 58)
        }
    }

    /// Kabul etmeden önce silinmesi gereken en az ipucu sayısı.
    public var minimumRemoved: Int {
        size.cellCount * minimumRemovalPercent / 100
    }

    /// Döngünün içinde hedeflenen hücre sayısı.
    public var insideTarget: Int {
        max(4, size.cellCount * insidePercent / 100)
    }
}

/// Slitherlink üreticisi.
///
/// Diğer dört varyanttan yapısal bir farkı var: **hangi ipuçların verileceği üreticinin
/// kararı.** Kakuro'da toplamlar çözümden zorunlu olarak türüyordu, burada her hücrenin
/// ipucu türetilebilir ama verilmek zorunda değil.
///
/// Bu, yayınlanmış Slitherlink üreticilerinin yolunu açıyor ve zorluk kolunu kendiliğinden
/// veriyor:
///
/// 1. Rastgele tek kapalı döngü kur (`SlitherlinkLoopBuilder`).
/// 2. Bütün hücrelerin ipucunu döngüden türet — bu bulmaca kesin benzersiz, çünkü ipuçlar
///    döngüyü fazlasıyla belirliyor.
/// 3. **Yayılımın bulmacayı kapatması bozulmadığı sürece** ipucu sil.
/// 4. Hedef zorluğa ulaşıldığında dur.
///
/// Üçüncü adım iki işi birden yapıyor. Yayılım sağlam, yani bulmacayı kapatıyorsa çözüm
/// tektir — benzersizlik aramaya hiç gerek kalmadan garanti. Ve her ara durum geçerli bir
/// bulmaca, çünkü silme ancak kapanış korunduğunda kabul ediliyor.
///
/// Aramayla doğrulanan daha agresif bir silme fazı denendi ve bırakıldı (ADR 0014): üretimi
/// saniyelere çıkarıyor ve ulaştığı bulmacaların çoğu `guessing` çıkıyor.
public struct SlitherlinkGenerator: PuzzleGenerator {
    public typealias Definition = SlitherlinkPuzzle
    public typealias Solution = SlitherlinkSolution

    public let variant: PuzzleVariantID = .slitherlink
    public let solver: SlitherlinkSolver
    public let layouts: [Difficulty: SlitherlinkLayout]

    public init(
        // Üreticinin çözücüsü dar bütçeli: tek ihtiyacı "benzersiz mi" sorusunun hızlı
        // cevabı, ve kanıtlanamayan aday zaten eleniyor. Hattın bağımsız kontrolü geniş
        // bütçeli çözücüyle yapılıyor.
        solver: SlitherlinkSolver = SlitherlinkSolver(searchNodeBudget: 800),
        layouts: [Difficulty: SlitherlinkLayout]? = nil
    ) {
        self.solver = solver
        self.layouts = layouts ?? Dictionary(
            uniqueKeysWithValues: Difficulty.allCases.map { ($0, SlitherlinkLayout.standard(for: $0)) }
        )
    }

    public func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> SlitherlinkPuzzle {
        try candidate(difficulty: difficulty, using: &rng).puzzle
    }

    /// Kurulan çözümü de döndüren üretim.
    public func candidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> (puzzle: SlitherlinkPuzzle, solution: SlitherlinkSolution) {
        guard let layout = layouts[difficulty] else {
            throw GenerationError.invalidCandidate(reason: "\(difficulty) için yerleşim yok")
        }
        guard let inside = SlitherlinkLoopBuilder.inside(
            size: layout.size, target: layout.insideTarget, using: &rng
        ) else {
            throw GenerationError.attemptFailed(reason: "Döngü kurulamadı")
        }

        let lines = SlitherlinkLoopBuilder.boundary(of: inside, in: layout.size)
        let solution = SlitherlinkSolution(lines: lines)
        var clues = Self.fullClues(from: lines, size: layout.size)
        let positions = clues.size.allPositions
        let order = (0..<layout.size.cellCount).shuffled(using: &rng)

        // Yayılımın bulmacayı kapatmasını koruyarak sil: silme bulmacayı yayılımla
        // çözülemez hale getiriyorsa ipucu geri konuyor. Burada hiç arama yok — yayılım
        // kapatıyorsa bulmaca benzersiz. Kabul, hedef zorluğa ulaşılan ilk noktada
        // olduğu için bu döngü aynı zamanda ipucu yoğunluğunu belirliyor.
        var removed = 0
        for cell in order {
            guard let saved = clues.elements[cell] else { continue }
            clues[positions[cell]] = nil

            guard solver.propagationTier(of: SlitherlinkPuzzle(clues: clues)) != nil else {
                clues[positions[cell]] = saved
                continue
            }
            removed += 1
            guard removed >= layout.minimumRemoved else { continue }
            if let ready = accept(clues: clues, difficulty: difficulty, solution: solution) {
                return ready
            }
        }

        throw GenerationError.attemptFailed(
            reason: "\(difficulty) zorluğunda bulmaca bulunamadı"
        )
    }

    /// Teknik seviyesini Slitherlink'in zorluk ölçeğine çeviriyor.
    ///
    /// İki yerde diğer varyantlardan ayrılıyor ve ikisi de ölçümün sonucu (ADR 0014):
    ///
    /// - **`advanced` de reddediliyor**, yalnız `guessing` değil. Slitherlink'te "orta
    ///   teknik yetiyor" ile "tahmin gerekiyor" arasındaki pencere çok dar: yayılımın
    ///   kapatmadığı ilk bulmacada ölçüm %60-80 çok çözümlü, kalanın da çoğu `guessing`
    ///   çıkıyor. O pencereyi hedeflemek üretimi saniyelere çıkarıyor ve kazancı, ileri
    ///   teknik gerektiren nadir bir bulmaca. Karşılığında kesin bir güvence veriliyor:
    ///   **gönderilen her Slitherlink temel ve orta tekniklerle çözülebilir.** Rakip
    ///   analizinde (PR #10) bu kategorinin en can alıcı şikâyeti tam olarak buydu.
    /// - **Medium, Hard ve Expert aynı teknik seviyesini paylaşıyor** ve boyutla ayrılıyor.
    ///   Zorluk boyuttan ve ipucu seyrekliğinden geliyor: 8×8'de hücrelerin %52'si
    ///   ipuçlu, 12×12'de %42'si.
    ///   ADR 0012 ve 0013'te Hard/Expert için alınan kararın aynısı, bir seviye genişi.
    public func rate(_ trace: SolveTrace, of definition: SlitherlinkPuzzle) -> Difficulty? {
        switch trace.highestTier {
        case .basic:
            return .easy
        case .intermediate:
            switch definition.size.rows {
            case ...8: return .medium
            case 9...10: return .hard
            default: return .expert
            }
        case .advanced, .guessing:
            return nil
        }
    }

    /// Bulmaca bu haliyle hedef zorlukta mı — yalnız yayılımla, varsayıma inmeden.
    ///
    /// `trace` çağrılmıyor: teknik merdiveninin varsayım adımı 12×12'de saniyeler alıyor ve
    /// temel ile orta seviyeyi ayırmak için ona inmek gerekmiyor (ADR 0014).
    private func accept(
        clues: Grid<Int?>,
        difficulty: Difficulty,
        solution: SlitherlinkSolution
    ) -> (puzzle: SlitherlinkPuzzle, solution: SlitherlinkSolution)? {
        let puzzle = SlitherlinkPuzzle(clues: clues)
        guard let tier = solver.propagationTier(of: puzzle) else { return nil }
        var trace = SolveTrace()
        trace.record("propagation", tier: tier)
        guard rate(trace, of: puzzle) == difficulty else { return nil }
        return (puzzle, solution)
    }
}

extension SlitherlinkGenerator {
    /// Döngüden bütün hücrelerin ipucunu türetiyor.
    public static func fullClues(from lines: [Bool], size: GridSize) -> Grid<Int?> {
        let horizontalCount = (size.rows + 1) * size.columns
        var clues = Grid<Int?>(size: size, repeating: nil)

        for row in 0..<size.rows {
            for column in 0..<size.columns {
                var count = 0
                if lines[row * size.columns + column] { count += 1 }
                if lines[(row + 1) * size.columns + column] { count += 1 }
                if lines[horizontalCount + row * (size.columns + 1) + column] { count += 1 }
                if lines[horizontalCount + row * (size.columns + 1) + column + 1] { count += 1 }
                clues[row, column] = count
            }
        }
        return clues
    }

    /// Ölçülen elenme oranlarına göre ayarlanmış üretim hattı (ADR 0014).
    public static func pipeline(
        _ generator: SlitherlinkGenerator = SlitherlinkGenerator()
    ) -> GenerationPipeline<SlitherlinkGenerator> {
        GenerationPipeline(generator: generator, maxAttempts: 2500)
    }
}
