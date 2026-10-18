/// Bir zorluk seviyesinin Kakuro parametreleri.
public struct KakuroLayout: Hashable, Sendable {
    /// Izgara kenarı, ipucu hücreleri dahil (ADR 0005).
    public let side: Int
    /// Desen geçerli hale geldikten sonra eklenecek fazladan siyah hücre oranı (yüzde).
    ///
    /// Zorluğun asıl kolu bu. Fazladan siyah hücre kesitleri kısaltıyor, kısa kesidin
    /// bileşim sayısı az ve bulmaca temel tekniklerle açılıyor. Uzun kesitler belirsiz.
    public let extraBlackPercent: Int

    public init(side: Int, extraBlackPercent: Int) {
        precondition(side >= 4, "Izgara en az 4×4 olmalı")
        self.side = side
        self.extraBlackPercent = extraBlackPercent
    }

    public static func standard(for difficulty: Difficulty) -> KakuroLayout {
        switch difficulty {
        case .easy: KakuroLayout(side: 8, extraBlackPercent: 45)
        case .medium: KakuroLayout(side: 10, extraBlackPercent: 30)
        case .hard: KakuroLayout(side: 12, extraBlackPercent: 15)
        case .expert: KakuroLayout(side: 14, extraBlackPercent: 5)
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

    /// Onarım döngüsünün en fazla tur sayısı (bkz. `candidate`).
    public let repairLimit: Int

    public init(
        solver: KakuroSolver = KakuroSolver(),
        layouts: [Difficulty: KakuroLayout]? = nil,
        expertMinimumSide: Int = 14,
        expertProgressCeiling: Double = 1.0,
        repairLimit: Int = 40
    ) {
        self.repairLimit = repairLimit
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
            throw GenerationError.invalidCandidate(
                reason: "\(layout.side)×\(layout.side) için geçerli desen bulunamadı"
            )
        }
        guard var digits = Self.fill(pattern: pattern, using: &rng) else {
            throw GenerationError.invalidCandidate(reason: "Desen kesit içi tekrarsız doldurulamadı")
        }

        // Onarım döngüsü. Rastgele bir doldurma neredeyse hiçbir zaman benzersiz bulmaca
        // vermiyor (ADR 0013: 480 adayda sıfır), çünkü Kakuro'da benzersizlik geçerli bir
        // doldurmanın yan ürünü değil — kurulması gerekiyor.
        //
        // Yöntem: iki çözüm bul, aralarında ayrışan hücrelerden birini seç, o hücreye
        // kesitlerinde kullanılmayan başka bir rakam yaz. Hücrenin iki kesidinin toplamı
        // değişiyor ve eski alternatif artık o toplamları tutmuyor. Her tur bir alternatifi
        // öldürüyor.
        for _ in 0..<repairLimit {
            let assembled = Self.assemble(pattern: pattern, digits: digits)
            let solutions: [KakuroSolution]
            do {
                solutions = try solver.findSolutions(of: assembled.puzzle, upTo: 2)
            } catch {
                // Arama bütçesi tükendi: bu doldurma kanıtlanamıyor, hat adayı elesin.
                return assembled
            }

            if solutions.count == 1 { return assembled }
            guard solutions.count == 2 else { return assembled }

            let differing = pattern.allPositions.filter {
                !pattern[$0] && solutions[0].values[$0] != solutions[1].values[$0]
            }
            guard let target = differing.randomElement(using: &rng) else { return assembled }
            guard Self.perturb(&digits, pattern: pattern, at: target, using: &rng) else {
                return assembled
            }
        }

        return Self.assemble(pattern: pattern, digits: digits)
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

// MARK: - Desen

extension KakuroGenerator {
    /// Siyah hücre deseni: `true` ipucu hücresi.
    ///
    /// Üst satır ve sol sütun her zaman ipucu hücresi — toplamları onlar taşıyor. İç hücreler
    /// giriş olarak başlıyor ve geçerli hale gelene kadar siyahlanıyor.
    ///
    /// Geçerlilik tek bir koşul: her yatay ve dikey kesit 2-9 uzunluğunda. Tek hücreli kesit
    /// rakamı ipucunda açık ediyor, dokuzdan uzun kesit tekrarsız doldurulamıyor.
    static func pattern(for layout: KakuroLayout, using rng: inout SeededGenerator) -> Grid<Bool>? {
        let size = GridSize(square: layout.side)
        var black = Grid(size: size, repeating: false)
        for index in 0..<layout.side {
            black[0, index] = true
            black[index, 0] = true
        }

        // Tek tek siyahlayıp kabul etmek işe yaramıyor: başlangıç durumu zaten geçersiz
        // (iç kesitler dokuzdan uzun) ve "geçerliyse kabul et" kuralı hiçbir hamleyi kabul
        // etmezdi. Bunun yerine ihlal miktarını ölçüp azaltan hamleleri kabul ediyoruz.
        var penalty = violationPenalty(black)
        var attempts = 0
        let limit = layout.side * layout.side * 60

        while penalty > 0 && attempts < limit {
            attempts += 1
            let row = Int.random(in: 1..<layout.side, using: &rng)
            let column = Int.random(in: 1..<layout.side, using: &rng)
            black[row, column].toggle()
            let candidate = violationPenalty(black)
            if candidate <= penalty {
                penalty = candidate
            } else {
                black[row, column].toggle()
            }
        }
        guard penalty == 0 else { return nil }

        addExtraBlackCells(&black, layout: layout, using: &rng)
        return black
    }

    /// Geçerliliği koruyarak fazladan siyah hücre ekliyor; kesitleri kısaltmanın yolu bu.
    private static func addExtraBlackCells(
        _ black: inout Grid<Bool>,
        layout: KakuroLayout,
        using rng: inout SeededGenerator
    ) {
        var candidates = (1..<layout.side).flatMap { row in
            (1..<layout.side).map { Position(row: row, column: $0) }
        }.filter { !black[$0] }
        candidates.shuffle(using: &rng)

        let target = candidates.count * layout.extraBlackPercent / 100
        var added = 0
        for position in candidates where added < target {
            black[position] = true
            if violationPenalty(black) == 0 {
                added += 1
            } else {
                black[position] = false
            }
        }
    }

    /// Desenin kural ihlali miktarı. Sıfır ise desen geçerli.
    ///
    /// Dışa açık: desen kurallarını ölçen tek yer burası ve Faz 3'teki öğreticide elle
    /// kurulmuş bulmacalar olacak (ADR 0009) — onların desenleri de bu kontrolden geçmeli.
    public static func violationPenalty(_ black: Grid<Bool>) -> Int {
        var penalty = 0
        for segment in segments(of: black) {
            if segment.count == 1 {
                penalty += 1
            } else if segment.count > 9 {
                penalty += segment.count - 9
            }
        }
        return penalty
    }

    /// Desendeki bütün yatay ve dikey kesitler (kesintisiz giriş hücresi dizileri).
    static func segments(of black: Grid<Bool>) -> [[Int]] {
        let size = black.size
        var result: [[Int]] = []

        for row in 0..<size.rows {
            var current: [Int] = []
            for column in 0..<size.columns {
                if black[row, column] {
                    if !current.isEmpty { result.append(current) }
                    current = []
                } else {
                    current.append(row * size.columns + column)
                }
            }
            if !current.isEmpty { result.append(current) }
        }

        for column in 0..<size.columns {
            var current: [Int] = []
            for row in 0..<size.rows {
                if black[row, column] {
                    if !current.isEmpty { result.append(current) }
                    current = []
                } else {
                    current.append(row * size.columns + column)
                }
            }
            if !current.isEmpty { result.append(current) }
        }

        return result
    }
}

// MARK: - Doldurma ve toplamlar

extension KakuroGenerator {
    /// Giriş hücrelerine kesit içi tekrarsız rakamlar yazıyor.
    ///
    /// Dokuz renkli bir çizge boyama: her hücrenin kısıtı kendi yatay ve dikey kesidinde
    /// kullanılmış rakamlar. Kesitler en fazla dokuz hücre olduğu için çözüm hep var, ama
    /// geri izleme gerekiyor — açgözlü doldurma bazı yerleşimlerde tıkanıyor.
    static func fill(pattern: Grid<Bool>, using rng: inout SeededGenerator) -> Grid<Int>? {
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

        var context = FillContext(pattern: pattern, cells: cells, orders: orders)
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
