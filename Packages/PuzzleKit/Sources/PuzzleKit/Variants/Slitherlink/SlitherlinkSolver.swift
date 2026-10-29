/// Slitherlink çözücüsü: kısıt yayılımı + geri izleme.
///
/// Diğer dört varyantla aynı iskelet, ama kısıtların doğası farklı: orada kısıtlar yereldi
/// (ada derecesi, karalama komşuluğu, kafes aritmetiği, kesit toplamı), burada küresel —
/// çizgiler **tek bir kapalı döngü** oluşturmak zorunda. Brief b.6 Slitherlink'i bu yüzden
/// en sona bırakıyor.
///
/// Teknik seviyeleri (ADR 0014):
///
/// | Seviye | Teknik | Ne yapıyor |
/// |---|---|---|
/// | `basic` | hücre + köşe | Hücrenin dört kenarı için 16 dizilimden hangileri hem
///   ipucuna hem dört köşesinin paritesine uyuyor; uymayan eleniyor. Klasik açılış
///   desenleri (köşedeki 3, yan yana iki 3, köşedeki 1) bunun sonucu |
/// | `basic` | nokta paritesi | Her noktanın derecesi 0 ya da 2 — döngü dallanmaz ve
///   serbest uç bırakmaz |
/// | `intermediate` | erken kapanma | Bir kenarı çizgi yapmak döngüyü kapatacaksa ve
///   dışarıda başka çizgi varsa o kenar çarpı |
/// | `advanced` | tek adım varsayım | Bir kenara bir durum varsayılıp çelişki aranıyor |
/// | `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor |
public struct SlitherlinkSolver: PuzzleSolver {
    public typealias Definition = SlitherlinkPuzzle
    public typealias Solution = SlitherlinkSolution

    /// Tek adım varsayımın deneyeceği en fazla kenar sayısı.
    public let hypothesisBudget: Int
    /// Aramanın dallanabileceği en fazla düğüm sayısı.
    ///
    /// Kakuro'da gerekti (ADR 0013) ve Slitherlink'te daha da gerekli: döngü kısıtı yerel
    /// kısıtlardan pahalı ve benzersizliği aramayla kanıtlamak ağacın tamamını tüketmek
    /// demek. Bütçe tükenirse sonuç `.indeterminate` ve aday eleniyor.
    public let searchNodeBudget: Int

    private let rules = SlitherlinkRules()

    public init(hypothesisBudget: Int = 64, searchNodeBudget: Int = 20_000) {
        self.hypothesisBudget = hypothesisBudget
        self.searchNodeBudget = searchNodeBudget
    }

    // MARK: - Benzersizlik

    public func findSolutions(
        of puzzle: SlitherlinkPuzzle,
        upTo limit: Int
    ) throws -> [SlitherlinkSolution] {
        guard limit > 0 else { return [] }
        var domains = Domains(puzzle: puzzle)

        // Önce mantık: yayılım sağlam olduğu için bütün kenarları kesinleştirdiyse o tek
        // çözüm demektir ve aramaya gerek yok (ADR 0013'teki Kakuro kestirmesiyle aynı).
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return [] }
        if domains.isDecided {
            let board = domains.board(for: puzzle)
            return rules.isSolved(board, in: puzzle) ? [domains.solution()] : []
        }

        var found: [SlitherlinkSolution] = []
        var budget = searchNodeBudget
        search(domains, in: puzzle, limit: limit, budget: &budget, into: &found)
        guard budget > 0 else { throw SolverError.searchBudgetExhausted }
        return found
    }

    // MARK: - Derecelendirme

    public func trace(of puzzle: SlitherlinkPuzzle) throws -> SolveTrace {
        var trace = SolveTrace()
        var domains = Domains(puzzle: puzzle)

        while true {
            let cells = enforceCells(&domains, in: puzzle)
            if cells == .contradiction { return trace }
            if cells == .changed {
                trace.record("cell", tier: .basic)
                continue
            }

            let parity = enforceDotParity(&domains, in: puzzle)
            if parity == .contradiction { return trace }
            if parity == .changed {
                trace.record("dotParity", tier: .basic)
                continue
            }

            let closure = enforcePrematureClosure(&domains, in: puzzle)
            if closure == .contradiction { return trace }
            if closure == .changed {
                trace.record("prematureClosure", tier: .intermediate)
                continue
            }

            let hypothesis = enforceHypothesis(&domains, in: puzzle)
            if hypothesis.step == .contradiction { return trace }
            if hypothesis.step == .changed {
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

    /// Yayılım tek başına bulmacayı kapatıyor mu, kapatıyorsa hangi seviyede.
    ///
    /// `nil` dönmesi "mantık yetmiyor" demek — varsayım ya da arama gerekiyor.
    ///
    /// Üretici bunu `trace` yerine kullanıyor ve sebebi maliyet (ADR 0014): `trace` teknik
    /// merdiveninin tamamını çıkıyor, varsayım adımı dahil, ve 12×12'de 312 kenarla o adım
    /// tek başına saniyeler alıyor. Temel ve orta seviyeyi ayırmak için varsayıma hiç
    /// inmek gerekmiyor.
    public func propagationTier(of puzzle: SlitherlinkPuzzle) -> TechniqueTier? {
        var domains = Domains(puzzle: puzzle)

        // Çelişki temel seviyede çıktıysa orta seviye de çıkaracak: kurallar birikimli,
        // eklenen kural çelişkiyi ortadan kaldırmıyor.
        guard propagate(&domains, in: puzzle, upTo: .basic) else { return nil }
        if domains.isDecided, rules.isSolved(domains.board(for: puzzle), in: puzzle) {
            return .basic
        }

        // Orta seviye **aynı alanların üstünden** devam ediyor, sıfırdan değil. Yayılım
        // monoton (kurallar yalnız daraltıyor) ve birikimli, yani ulaşılan sabit nokta
        // kuralların uygulanma sırasından bağımsız; temel seviyenin bıraktığı yerden
        // devam etmek sıfırdan başlamakla aynı sonucu veriyor.
        //
        // Sebebi maliyet: üretici bu çağrıyı ipucu başına bir kez yapıyor ve çağrıların
        // çoğu `nil` dönüyor, yani eski kod temel seviyenin işini her seferinde iki kez
        // yapıyordu (#78 ölçümü).
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return nil }
        guard domains.isDecided, rules.isSolved(domains.board(for: puzzle), in: puzzle) else {
            return nil
        }
        return .intermediate
    }

    /// Temel ve orta tekniklerin tek başına kesinleştirdiği kenar oranı.
    public func logicalProgress(of puzzle: SlitherlinkPuzzle) -> Double {
        var domains = Domains(puzzle: puzzle)
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return 0 }
        let decided = (0..<puzzle.edgeCount).count { !domains.isUndecided($0) }
        return Double(decided) / Double(max(1, puzzle.edgeCount))
    }

    // MARK: - Arama

    private func search(
        _ domains: Domains,
        in puzzle: SlitherlinkPuzzle,
        limit: Int,
        budget: inout Int,
        into found: inout [SlitherlinkSolution]
    ) {
        guard found.count < limit, budget > 0 else { return }

        guard let edge = branchEdge(domains, in: puzzle) else {
            if rules.isSolved(domains.board(for: puzzle), in: puzzle) {
                found.append(domains.solution())
            }
            return
        }

        // Sıra deterministik: önce çizgi, sonra çarpı (ADR 0006).
        for line in [true, false] {
            budget -= 1
            guard budget > 0 else { return }
            var branch = domains
            if line { branch.forceLine(edge) } else { branch.forceCross(edge) }
            guard propagate(&branch, in: puzzle, upTo: .intermediate) else { continue }
            search(branch, in: puzzle, limit: limit, budget: &budget, into: &found)
            if found.count >= limit { return }
        }
    }

    /// Dallanılacak kenar.
    ///
    /// Alanlar hep iki değerli, yani "en az seçenekli" sıralama bir şey söylemiyor. Yerine
    /// döngüyü takip ediyoruz: derecesi 1 olan bir noktaya değen kenar, döngünün devam
    /// etmek zorunda olduğu yer — oradan dallanmak ağacı en hızlı daraltıyor.
    private func branchEdge(_ domains: Domains, in puzzle: SlitherlinkPuzzle) -> Int? {
        for dot in 0..<puzzle.dotCount {
            var lines = 0
            for edge in puzzle.edgesOfDot[dot] where domains.isLine(edge) { lines += 1 }
            guard lines == 1 else { continue }
            if let edge = puzzle.edgesOfDot[dot].first(where: { domains.isUndecided($0) }) {
                return edge
            }
        }
        return (0..<puzzle.edgeCount).first { domains.isUndecided($0) }
    }

    // MARK: - Yayılım

    /// `false` dönerse çelişki var.
    func propagate(
        _ domains: inout Domains,
        in puzzle: SlitherlinkPuzzle,
        upTo tier: TechniqueTier
    ) -> Bool {
        while true {
            switch enforceCells(&domains, in: puzzle) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            switch enforceDotParity(&domains, in: puzzle) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            if tier >= .intermediate {
                switch enforcePrematureClosure(&domains, in: puzzle) {
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

    /// Tek adım varsayım. Tek geçişte bulduğu bütün elemeleri uyguluyor (ADR 0012).
    private func enforceHypothesis(
        _ domains: inout Domains,
        in puzzle: SlitherlinkPuzzle
    ) -> (step: Step, eliminations: Int) {
        var tried = 0
        var eliminations = 0

        for edge in 0..<puzzle.edgeCount where domains.isUndecided(edge) {
            if tried >= hypothesisBudget { break }
            tried += 1

            for line in [true, false] {
                var hypothetical = domains
                if line { hypothetical.forceLine(edge) } else { hypothetical.forceCross(edge) }
                guard !propagate(&hypothetical, in: puzzle, upTo: .intermediate) else { continue }
                if line { domains.forceCross(edge) } else { domains.forceLine(edge) }
                if domains.bits[edge] == 0 { return (.contradiction, eliminations) }
                eliminations += 1
                break
            }
        }

        return (eliminations > 0 ? .changed : .unchanged, eliminations)
    }
}
