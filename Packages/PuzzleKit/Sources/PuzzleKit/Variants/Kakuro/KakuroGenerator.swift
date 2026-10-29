/// Bir zorluk seviyesinin Kakuro parametreleri.
public struct KakuroLayout: Hashable, Sendable {
    /// Izgara kenarı, ipucu hücreleri dahil (ADR 0005).
    public let side: Int
    /// Desen geçerli hale geldikten sonra eklenecek fazladan siyah hücre oranı (yüzde).
    ///
    /// Zorluğun asıl kolu bu. Fazladan siyah hücre kesitleri kısaltıyor, kısa kesidin
    /// bileşim sayısı az ve bulmaca temel tekniklerle açılıyor. Uzun kesitler belirsiz.
    public let extraBlackPercent: Int

    /// Doldurmanın bileşim maliyetini düşürmek için koşulan tepe tırmanma adımı sayısı.
    ///
    /// Zorluğun asıl kolu bu (ADR 0013): maliyet düştükçe kesitler uç toplamlara kayıyor,
    /// uç toplamın tek bileşimi oluyor ve bulmaca temel tekniklerle açılıyor. Az adım,
    /// daha belirsiz toplamlar ve daha ileri teknik gerektiren bulmaca demek.
    public let fillOptimizationSteps: Int
    /// Yönlendirme turlarından sonra koşulan kısa eniyileme adımı sayısı.
    public let repairOptimizationSteps: Int
    /// Yönlendirme döngüsünün en fazla tur sayısı.
    public let steeringLimit: Int

    public init(
        side: Int,
        extraBlackPercent: Int,
        fillOptimizationSteps: Int,
        repairOptimizationSteps: Int = 400,
        steeringLimit: Int = 30
    ) {
        precondition(side >= 4, "Izgara en az 4×4 olmalı")
        self.side = side
        self.extraBlackPercent = extraBlackPercent
        self.fillOptimizationSteps = fillOptimizationSteps
        self.repairOptimizationSteps = repairOptimizationSteps
        self.steeringLimit = steeringLimit
    }

    public static func standard(for difficulty: Difficulty) -> KakuroLayout {
        switch difficulty {
        case .easy:
            KakuroLayout(
                side: 8, extraBlackPercent: 45, fillOptimizationSteps: 4000,
                repairOptimizationSteps: 400, steeringLimit: 40
            )
        case .medium:
            KakuroLayout(
                side: 10, extraBlackPercent: 45, fillOptimizationSteps: 2200,
                repairOptimizationSteps: 150, steeringLimit: 150
            )
        case .hard:
            // Onarım sonrası eniyileme kısa: her tur maliyeti düşürmek, kazanılan zorluğu
            // geri veriyor ve bulmaca temel seviyeye kayıyor.
            KakuroLayout(
                side: 10, extraBlackPercent: 45, fillOptimizationSteps: 1200,
                repairOptimizationSteps: 60, steeringLimit: 150
            )
        case .expert:
            // Yönlendirme sınırı Hard'dan düşük: 12×12'de her tur daha pahalı ve verimsiz
            // bir deseni erken bırakmak, onda ısrar etmekten hızlı. Ölçümde en kötü süre
            // 1.951 ms'den 600 ms'ye indi.
            KakuroLayout(
                side: 11, extraBlackPercent: 45, fillOptimizationSteps: 900,
                repairOptimizationSteps: 40, steeringLimit: 120
            )
        }
    }
}

/// Kakuro üreticisi.
///
/// > **Henüz kabul kriterini karşılamıyor.** Ürettiği bulmacalar geçerli — desen kuralları
/// > tutuyor, doldurma kesit içi tekrarsız, çözüm bütün toplamları tutuyor — ama
/// > **benzersiz değil**. Ölçüm: 480 adayda sıfır benzersiz, dört boyut ve üç yoğunluk
/// > denendi; yerel onarım döngüsü 60 turda da yakınsamıyor. Sebebin teşhisi ve sonraki
/// > adım ADR 0013'te. Bu yüzden üretim hattı (`pipeline()`) henüz yok: kabul kriterini
/// > karşılamayan bir API, onu kullanan kodda sessiz bir tuzak olur.
///
/// Diğer üç varyantta olduğu gibi çözümü kuruyor: önce siyah hücre deseni, sonra giriş
/// hücrelerine kesit içi tekrarsız rakamlar, en sonunda toplamlar çözümden türetiliyor.
///
/// Kakuro'yu zorlaştıran şey desen kurulumu ve brief b.6 bunu "üretim zorluğu yüksek"
/// olarak işaretliyor. Sebebi iki yönlü bir kısıt: her kesit 2-9 uzunluğunda olmak zorunda,
/// yani uzun kesitleri siyah hücreyle kırmak gerekiyor — ama her kırma, dik yöndeki kesidi
/// de ikiye ayırıyor ve orada tek hücreli kesit yaratabiliyor. İki yön birbirini bozuyor.
public struct KakuroGenerator: PuzzleGenerator {
    public typealias Definition = KakuroPuzzle
    public typealias Solution = KakuroSolution

    public let variant: PuzzleVariantID = .kakuro
    public let solver: KakuroSolver
    public let layouts: [Difficulty: KakuroLayout]
    /// Expert sayılmak için mantıksal ilerlemenin kalması gereken üst sınır
    /// (ADR 0012'deki gerekçeyle aynı; değer ADR 0013'te ölçümle belirlendi).
    public let expertProgressCeiling: Double
    /// Expert sayılmak için gereken en küçük ızgara kenarı.
    public let expertMinimumSide: Int

    public init(
        // Üreticinin çözücüsü dar bütçeli, hattın çözücüsü değil. Üreticinin tek ihtiyacı
        // "mantıkla kapanıyor mu" sorusunun cevabı; kapanmayan adayda uzun uzun arama
        // yapmanın karşılığı yok, bozup devam etmek hızlı. Kabul edilen aday zaten mantıkla
        // kapandığı için hattın bağımsız kontrolü aramaya hiç inmiyor.
        solver: KakuroSolver = KakuroSolver(searchNodeBudget: 800),
        layouts: [Difficulty: KakuroLayout]? = nil,
        expertMinimumSide: Int = 11,
        expertProgressCeiling: Double = 1.0
    ) {
        self.solver = solver
        self.layouts = layouts ?? Dictionary(
            uniqueKeysWithValues: Difficulty.allCases.map { ($0, KakuroLayout.standard(for: $0)) }
        )
        self.expertMinimumSide = expertMinimumSide
        self.expertProgressCeiling = expertProgressCeiling
    }

    public func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> KakuroPuzzle {
        try candidate(difficulty: difficulty, using: &rng).puzzle
    }

    /// Kurulan çözümü de döndüren üretim.
    public func candidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> (puzzle: KakuroPuzzle, solution: KakuroSolution) {
        guard let layout = layouts[difficulty] else {
            throw GenerationError.invalidCandidate(reason: "\(difficulty) için yerleşim yok")
        }

        guard let pattern = Self.pattern(for: layout, using: &rng) else {
            throw GenerationError.attemptFailed(
                reason: "\(layout.side)×\(layout.side) için geçerli desen bulunamadı"
            )
        }
        guard var digits = Self.fill(pattern: pattern, using: &rng) else {
            throw GenerationError.attemptFailed(reason: "Desen kesit içi tekrarsız doldurulamadı")
        }
        Self.optimizeFill(
            &digits, pattern: pattern, iterations: layout.fillOptimizationSteps, using: &rng
        )

        // Yönlendirme döngüsü. Üretici hedef zorluğu biliyor, o yüzden her turda deseni
        // baştan kurmak yerine aynı desen üzerinde doldurmayı değiştiriyor: tur başına
        // maliyet bir benzersizlik kontrolü, desen kurulumu değil.
        //
        // Döngü iki şeyi birlikte arıyor — benzersizlik ve hedef zorluk. Benzersizlik
        // sağlandığında hedef tutmuyorsa durmuyor, bozup devam ediyor; aynı desen çok
        // sayıda bulmaca veriyor ve hattın dışarıdan yeniden denemesinden kat kat ucuz.
        for _ in 0..<layout.steeringLimit {
            let assembled = Self.assemble(pattern: pattern, digits: digits)
            // Tek arama, iki dal. Eskiden çok çözümlü dal aynı aramayı ikinci kez
            // yapıyordu; reddedilen her tur benzersizlik kontrolünü iki kez ödüyordu
            // (#78 ölçümü). Çözücü belirlenimci, yani ikinci çağrı yeni bilgi vermiyor.
            let solutions = try? solver.findSolutions(of: assembled.puzzle, upTo: 2)

            if let solutions, solutions.count == 1 {
                let trace = try solver.trace(of: assembled.puzzle)
                if rate(trace, of: assembled.puzzle) == difficulty { return assembled }

                // Benzersiz ama hedef zorlukta değil: bozup devam. Rastgele bir hücre,
                // çünkü ayrışan hücre yok — tek çözüm var.
                let entries = pattern.allPositions.filter { !pattern[$0] }
                guard let target = entries.randomElement(using: &rng),
                      Self.perturb(&digits, pattern: pattern, at: target, using: &rng)
                else { break }
                Self.optimizeFill(
                    &digits, pattern: pattern,
                    iterations: layout.repairOptimizationSteps, using: &rng
                )
                continue
            }

            // Çok çözümlü ya da kanıtlanamadı: iki çözümün ayrıştığı bir hücreyi boz.
            // Hücrenin iki kesidinin toplamı değişiyor ve eski alternatif artık o
            // toplamları tutmuyor; her tur bir alternatifi öldürüyor.
            let target: Position
            if let solutions, solutions.count == 2,
               let differing = pattern.allPositions.filter({
                   !pattern[$0] && solutions[0].values[$0] != solutions[1].values[$0]
               }).randomElement(using: &rng) {
                target = differing
            } else if let any = pattern.allPositions.filter({ !pattern[$0] })
                .randomElement(using: &rng) {
                target = any
            } else {
                break
            }

            guard Self.perturb(&digits, pattern: pattern, at: target, using: &rng) else { break }
            Self.optimizeFill(
                &digits, pattern: pattern,
                iterations: layout.repairOptimizationSteps, using: &rng
            )
        }

        throw GenerationError.attemptFailed(
            reason: "\(layout.steeringLimit) turda \(difficulty) zorluğunda bulmaca bulunamadı"
        )
    }

    public func rate(_ trace: SolveTrace, of definition: KakuroPuzzle) -> Difficulty? {
        switch trace.highestTier {
        case .basic: .easy
        case .intermediate: .medium
        case .advanced: isExpert(definition) ? .expert : .hard
        case .guessing: nil
        }
    }

    private func isExpert(_ definition: KakuroPuzzle) -> Bool {
        guard definition.size.rows >= expertMinimumSide else { return false }
        return solver.logicalProgress(of: definition) < expertProgressCeiling
    }
}

// MARK: - Doldurma ve toplamlar

extension KakuroGenerator {
    /// Giriş hücrelerine kesit içi tekrarsız rakamlar yazıyor.
    ///
    /// Dokuz renkli bir çizge boyama: her hücrenin kısıtı kendi yatay ve dikey kesidinde
    /// kullanılmış rakamlar. Kesitler en fazla dokuz hücre olduğu için çözüm hep var, ama
    /// geri izleme gerekiyor — açgözlü doldurma bazı yerleşimlerde tıkanıyor.
    public static func fill(pattern: Grid<Bool>, using rng: inout SeededGenerator) -> Grid<Int>? {
        let size = pattern.size
        var values = Grid(size: size, repeating: 0)
        let cells = pattern.allPositions.filter { !pattern[$0] }

        var orders: [[Int]] = []
        for _ in cells.indices {
            var digits = Array(1...9)
            digits.shuffle(using: &rng)
            // Uç rakamlar önce denenir. Sebebi ölçüm (ADR 0013): rastgele toplamlar bilgi
            // taşımıyor ve üretilen bulmacaların tamamı çok çözümlü çıkıyor. Uç rakamlar uç
            // toplamlar demek ve uç toplamın tek bir rakam kümesi var — "iki hücrede 17"
            // demek {8,9} demek. Çözücünün tutunacağı yer bu.
            digits.sort { abs($0 - 5) > abs($1 - 5) }
            orders.append(digits)
        }

        let context = FillContext(pattern: pattern, cells: cells, orders: orders)
        guard context.assign(index: 0, into: &values) else { return nil }
        return values
    }

    /// Doldurma gezinmesinin durumu. Özyinelemeli çağrıya dört parametre taşımak yerine
    /// sabit veriyi tipte tutuyoruz.
    private struct FillContext {
        let pattern: Grid<Bool>
        let cells: [Position]
        /// Hücre başına rakam deneme sırası; tohumdan türüyor, yani üretim deterministik.
        let orders: [[Int]]

        func assign(index: Int, into values: inout Grid<Int>) -> Bool {
            guard index < cells.count else { return true }
            let position = cells[index]
            let used = usedDigits(around: position, in: values)

            for digit in orders[index] where !used.contains(digit) {
                values[position] = digit
                if assign(index: index + 1, into: &values) { return true }
                values[position] = 0
            }
            return false
        }

        /// Hücrenin yatay ve dikey kesidinde zaten kullanılmış rakamlar.
        private func usedDigits(around position: Position, in values: Grid<Int>) -> DigitSet {
            var used = DigitSet.empty
            for step in [-1, 1] {
                var scan = position.offset(byRows: 0, columns: step)
                while pattern.element(at: scan) == false {
                    used.insert(values[scan])
                    scan = scan.offset(byRows: 0, columns: step)
                }
                scan = position.offset(byRows: step, columns: 0)
                while pattern.element(at: scan) == false {
                    used.insert(values[scan])
                    scan = scan.offset(byRows: step, columns: 0)
                }
            }
            return used
        }
    }

    /// Verilen hücreye, kesitlerinde kullanılmayan başka bir rakam yazıyor.
    ///
    /// Hücrenin iki kesidinin toplamı değişiyor; onarım döngüsünün tek hamlesi bu.
    static func perturb(
        _ digits: inout Grid<Int>,
        pattern: Grid<Bool>,
        at cell: Position,
        using rng: inout SeededGenerator
    ) -> Bool {
        var used = DigitSet.empty
        for step in [-1, 1] {
            var scan = cell.offset(byRows: 0, columns: step)
            while pattern.element(at: scan) == false {
                used.insert(digits[scan])
                scan = scan.offset(byRows: 0, columns: step)
            }
            scan = cell.offset(byRows: step, columns: 0)
            while pattern.element(at: scan) == false {
                used.insert(digits[scan])
                scan = scan.offset(byRows: step, columns: 0)
            }
        }

        var options = (1...9).filter { !used.contains($0) && $0 != digits[cell] }
        guard !options.isEmpty else { return false }
        options.shuffle(using: &rng)
        digits[cell] = options[0]
        return true
    }

    /// Desen ve rakamlardan bulmacayı ve çözümü kuruyor; toplamlar kesitlerden türüyor.
    static func assemble(
        pattern: Grid<Bool>,
        digits: Grid<Int>
    ) -> (puzzle: KakuroPuzzle, solution: KakuroSolution) {
        let size = pattern.size
        var cells = Grid(size: size, repeating: KakuroCell.entry)

        for position in pattern.allPositions where pattern[position] {
            let right = runSum(from: position, step: (0, 1), pattern: pattern, digits: digits)
            let down = runSum(from: position, step: (1, 0), pattern: pattern, digits: digits)
            cells[position] = .clue(down: down, right: right)
        }

        return (KakuroPuzzle(cells: cells), KakuroSolution(values: digits))
    }

    /// İpucu hücresinden verilen yönde uzanan kesidin toplamı; kesit yoksa `nil`.
    private static func runSum(
        from origin: Position,
        step: (rows: Int, columns: Int),
        pattern: Grid<Bool>,
        digits: Grid<Int>
    ) -> Int? {
        var scan = origin.offset(byRows: step.rows, columns: step.columns)
        var sum = 0
        var length = 0
        while pattern.element(at: scan) == false {
            sum += digits[scan]
            length += 1
            scan = scan.offset(byRows: step.rows, columns: step.columns)
        }
        return length > 0 ? sum : nil
    }
}

extension KakuroGenerator {
    /// Ölçülen elenme oranlarına göre ayarlanmış üretim hattı (ADR 0013).
    ///
    /// Üretici hedef zorluğu kendi yönlendirme döngüsünde arıyor, yani hattın elemesi
    /// nadir. Hat yine de benzersizliği bağımsız olarak kontrol ediyor ve bu bilerek
    /// böyle: brief b.11'in garantisi tek bir yerde değil iki yerde duruyor.
    public static func pipeline(
        _ generator: KakuroGenerator = KakuroGenerator()
    ) -> GenerationPipeline<KakuroGenerator> {
        GenerationPipeline(generator: generator, maxAttempts: 2500)
    }
}
