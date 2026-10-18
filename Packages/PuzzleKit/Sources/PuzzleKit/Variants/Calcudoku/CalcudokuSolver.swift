/// Calcudoku çözücüsü: kısıt yayılımı + geri izleme.
///
/// Hashi ve Hitori'nin çözücüleriyle aynı iskelet: aynı iki iş (benzersizlik kontrolü ve
/// zorluk derecelendirmesi), aynı seviye sıralaması.
///
/// Teknik seviyeleri (Calcudoku'ya özel liste, ADR 0012):
///
/// | Seviye | Teknik | Ne yapıyor |
/// |---|---|---|
/// | `basic` | Latin elemesi | Kesinleşmiş bir rakam, satır ve sütunundaki adaylardan
///   siliniyor |
/// | `basic` | küçük kafes | Bir ve iki hücreli kafeslerin aritmetiği; en fazla dokuz
///   değer deniyor |
/// | `intermediate` | gizli tek | Bir satır veya sütunda bir rakamın girebileceği tek
///   hücre kaldıysa oraya yazılıyor |
/// | `intermediate` | büyük kafes | Üç ve daha fazla hücreli kafeslerde hedefi tutturan
///   bileşimler aranıyor |
/// | `advanced` | tek adım varsayım | Bir hücreye bir rakam varsayılıp çelişki aranıyor |
/// | `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor |
public struct CalcudokuSolver: PuzzleSolver {
    public typealias Definition = CalcudokuPuzzle
    public typealias Solution = CalcudokuSolution

    /// Tek bir kafes aramasının deneyebileceği en fazla bileşim sayısı.
    static let cageSearchLimit = 4096

    /// Tek adım varsayımın deneyeceği en fazla hücre sayısı (bkz. `HashiSolver`).
    public let hypothesisBudget: Int

    private let rules = CalcudokuRules()

    public init(hypothesisBudget: Int = 48) {
        self.hypothesisBudget = hypothesisBudget
    }

    // MARK: - Benzersizlik

    public func findSolutions(
        of puzzle: CalcudokuPuzzle,
        upTo limit: Int
    ) throws -> [CalcudokuSolution] {
        guard limit > 0 else { return [] }
        var domains = Domains(puzzle: puzzle)
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return [] }

        var found: [CalcudokuSolution] = []
        search(domains, in: puzzle, limit: limit, into: &found)
        return found
    }

    // MARK: - Derecelendirme

    public func trace(of puzzle: CalcudokuPuzzle) throws -> SolveTrace {
        var trace = SolveTrace()
        var domains = Domains(puzzle: puzzle)

        while true {
            let latin = enforceLatin(&domains, in: puzzle)
            if latin == .contradiction { return trace }
            if latin == .changed {
                trace.record("latin", tier: .basic)
                continue
            }

            let small = enforceCages(&domains, in: puzzle, maxSize: 2)
            if small == .contradiction { return trace }
            if small == .changed {
                trace.record("smallCage", tier: .basic)
                continue
            }

            let hidden = enforceHiddenSingles(&domains, in: puzzle)
            if hidden == .contradiction { return trace }
            if hidden == .changed {
                trace.record("hiddenSingle", tier: .intermediate)
                continue
            }

            let large = enforceCages(&domains, in: puzzle, maxSize: Int.max)
            if large == .contradiction { return trace }
            if large == .changed {
                trace.record("largeCage", tier: .intermediate)
                continue
            }

            let hypothesis = enforceHypothesis(&domains, in: puzzle)
            if hypothesis.step == .contradiction { return trace }
            if hypothesis.step == .changed {
                // Eleme sayısı tek tek kaydediliyor ama tek geçişte bulunuyor: sayaç
                // bulmacanın gerçekten kaç çıkarım gerektirdiğini ölçüyor, maliyet ise
                // geçiş sayısı kadar kalıyor (ADR 0012).
                trace.record("hypothesis", tier: .advanced, times: hypothesis.eliminations)
                continue
            }

            break
        }

        if !domains.isDecided {
            trace.record("search", tier: .guessing)
        }
        return trace
    }

    /// Temel ve orta teknikler tek başına bulmacanın ne kadarını açıyor.
    ///
    /// Sonuç 0 ile 1 arasında: kesinleşen hücre oranı. Hard ile Expert ayrımı buna
    /// dayanıyor (ADR 0012). Varsayım sayısı yerine bunun kullanılmasının sebebi, sayının
    /// ızgara boyutundan bağımsız ve açıklanabilir olması: Hard'da mantık bulmacanın çoğunu
    /// açıyor ve sonu varsayım gerektiriyor, Expert'te mantık erken tıkanıyor.
    public func logicalProgress(of puzzle: CalcudokuPuzzle) -> Double {
        var domains = Domains(puzzle: puzzle)
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return 0 }
        let decided = (0..<puzzle.cellCount).count { domains.isDecided($0) }
        return Double(decided) / Double(puzzle.cellCount)
    }

    // MARK: - Arama

    private func search(
        _ domains: Domains,
        in puzzle: CalcudokuPuzzle,
        limit: Int,
        into found: inout [CalcudokuSolution]
    ) {
        guard found.count < limit else { return }

        guard let cell = domains.mostConstrainedUndecided() else {
            if rules.isSolved(domains.board(for: puzzle), in: puzzle) {
                found.append(domains.solution(for: puzzle))
            }
            return
        }

        // Rakamlar artan sırada: arama deterministik olmak zorunda (ADR 0006).
        for digit in domains.sets[cell] {
            var branch = domains
            branch.sets[cell] = DigitSet([digit])
            guard propagate(&branch, in: puzzle, upTo: .intermediate) else { continue }
            search(branch, in: puzzle, limit: limit, into: &found)
            if found.count >= limit { return }
        }
    }

    // MARK: - Yayılım

    /// `false` dönerse çelişki var.
    func propagate(
        _ domains: inout Domains,
        in puzzle: CalcudokuPuzzle,
        upTo tier: TechniqueTier
    ) -> Bool {
        while true {
            switch enforceLatin(&domains, in: puzzle) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            switch enforceCages(&domains, in: puzzle, maxSize: 2) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            if tier >= .intermediate {
                switch enforceIntermediate(&domains, in: puzzle) {
                case .contradiction: return false
                case .changed: continue
                case .unchanged: break
                }
            }

            if tier >= .advanced {
                switch enforceHypothesis(&domains, in: puzzle).step {
                case .contradiction: return false
                case .changed: continue
                case .unchanged: break
                }
            }

            return true
        }
    }

    /// Orta seviye teknikler: gizli tek ve büyük kafes araması.
    private func enforceIntermediate(
        _ domains: inout Domains,
        in puzzle: CalcudokuPuzzle
    ) -> Step {
        switch enforceHiddenSingles(&domains, in: puzzle) {
        case .contradiction: return .contradiction
        case .changed: return .changed
        case .unchanged: break
        }
        return enforceCages(&domains, in: puzzle, maxSize: Int.max)
    }

    /// Kesinleşmiş bir rakam, satır ve sütunundaki adaylardan siliniyor.
    private func enforceLatin(_ domains: inout Domains, in puzzle: CalcudokuPuzzle) -> Step {
        var changed = false

        for cell in 0..<puzzle.cellCount {
            guard let value = domains.value(of: cell) else { continue }
            for peer in puzzle.peers[cell] where domains.remove(value, from: peer) {
                changed = true
            }
        }

        if domains.hasEmptyDomain { return .contradiction }
        return changed ? .changed : .unchanged
    }

    /// Bir satır veya sütunda bir rakamın girebileceği tek hücre kaldıysa oraya yazılıyor.
    private func enforceHiddenSingles(
        _ domains: inout Domains,
        in puzzle: CalcudokuPuzzle
    ) -> Step {
        var changed = false

        for line in 0..<puzzle.side {
            let row = (0..<puzzle.side).map { line * puzzle.side + $0 }
            let column = (0..<puzzle.side).map { $0 * puzzle.side + line }
            for cells in [row, column] {
                switch placeHiddenSingles(in: cells, &domains, side: puzzle.side) {
                case .contradiction: return .contradiction
                case .changed: changed = true
                case .unchanged: break
                }
            }
        }

        return changed ? .changed : .unchanged
    }

    private func placeHiddenSingles(
        in cells: [Int],
        _ domains: inout Domains,
        side: Int
    ) -> Step {
        var changed = false

        for digit in 1...side {
            var holder: Int?
            var count = 0
            for cell in cells where domains.sets[cell].contains(digit) {
                holder = cell
                count += 1
                if count > 1 { break }
            }
            // Rakamın girebileceği hiç hücre yoksa satır tamamlanamaz.
            if count == 0 { return .contradiction }
            guard count == 1, let cell = holder, !domains.isDecided(cell) else { continue }
            domains.sets[cell] = DigitSet([digit])
            changed = true
        }

        return changed ? .changed : .unchanged
    }

    /// Verilen boyuta kadar olan kafeslerin aritmetiğini yayıyor.
    private func enforceCages(
        _ domains: inout Domains,
        in puzzle: CalcudokuPuzzle,
        maxSize: Int
    ) -> Step {
        var changed = false

        for cage in puzzle.cages where cage.size <= maxSize {
            switch enforceCage(cage, &domains, in: puzzle) {
            case .contradiction: return .contradiction
            case .changed: changed = true
            case .unchanged: break
            }
        }

        return changed ? .changed : .unchanged
    }

    /// Tek adım varsayım: bir hücreye bir rakam varsay, temel ve orta tekniklerle çelişki
    /// çıkarsa o rakamı ele. Dallanmadan farkı çelişkinin kanıtlanması (bkz. `HashiSolver`).
    ///
    /// Hashi ve Hitori'den bir farkı var: ilk elemede durup dönmüyor, **bir geçişte
    /// bulduğu bütün elemeleri uyguluyor.** Sebebi ölçüm (ADR 0012): 8×8'de bir bulmaca 68
    /// eleme gerektirebiliyor ve her elemeden sonra taramayı baştan başlatmak tek bir
    /// bulmacanın derecelendirmesini 1.100 ms'ye çıkarıyordu — 2.000 ms bütçenin yarısı.
    ///
    /// Sayaç yine *eleme* sayısını tutuyor (geçiş sayısını değil): `SolveTrace.record`
    /// bir geçişte bulunan elemelerin sayısını bir kerede alıyor. Yani derecelendirme
    /// bulmacanın gerçekten kaç çıkarım gerektirdiğini ölçmeye devam ediyor, maliyet ise
    /// geçiş sayısı kadar kalıyor.
    private func enforceHypothesis(
        _ domains: inout Domains,
        in puzzle: CalcudokuPuzzle
    ) -> (step: Step, eliminations: Int) {
        var tried = 0
        var eliminations = 0

        for cell in 0..<puzzle.cellCount where !domains.isDecided(cell) {
            if tried >= hypothesisBudget { break }
            tried += 1

            for digit in domains.sets[cell] {
                var hypothetical = domains
                hypothetical.sets[cell] = DigitSet([digit])
                guard !propagate(&hypothetical, in: puzzle, upTo: .intermediate) else { continue }
                _ = domains.remove(digit, from: cell)
                if domains.sets[cell].isEmpty { return (.contradiction, eliminations) }
                eliminations += 1
            }
        }

        return (eliminations > 0 ? .changed : .unchanged, eliminations)
    }
}
