/// Hashi çözücüsü: kısıt yayılımı + geri izleme.
///
/// İki işi var ve ikisi de brief'ten geliyor. Birincisi benzersizlik kontrolü (b.11):
/// `findSolutions(of:upTo:)` en fazla iki çözüm bulup duruyor, hat da bununla karar veriyor.
/// İkincisi zorluk derecelendirmesi (b.6): `trace(of:)` bulmacayı insan gibi, teknik
/// seviyelerini sırayla deneyerek çözüyor ve kullanılan en ileri seviyeyi döndürüyor.
///
/// Teknik seviyeleri (ADR 0005'in çerçevesi, Hashi'ye özel liste):
///
/// | Seviye | Teknik | Ne yapıyor |
/// |---|---|---|
/// | `basic` | ada derecesi toplamı | Adanın gereken derecesi, komşu kenarların alabileceği
///   en küçük/en büyük toplamla sınırlı; sınırın dışında kalan köprü sayıları eleniyor |
/// | `basic` | kesişim | Bir kenarda köprü kesinleşmişse kesiştiği kenarlar sıfırlanıyor |
/// | `intermediate` | bileşen bağlanmak zorunda | Kesinleşmiş köprülerle oluşan bir ada
///   grubunun dışarıya tek çıkışı kaldıysa o kenarda köprü olmak zorunda |
/// | `intermediate` | olası ağ bağlı mı | Mümkün kenarlarla bile bütün adalar tek ağda
///   olamıyorsa bulmaca çelişkili |
/// | `advanced` | tek adım varsayım | Bir kenara bir değer varsayılıyor; temel ve orta
///   tekniklerle çelişki çıkıyorsa o değer eleniyor |
/// | `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor; ilerlemek için
///   dallanma gerekiyor |
public struct HashiSolver: PuzzleSolver {
    public typealias Definition = HashiPuzzle
    public typealias Solution = HashiSolution

    /// Tek adım varsayımın (advanced) deneyeceği en fazla kenar sayısı.
    ///
    /// Sınır olmadan bu teknik, büyük ızgaralarda üretim süresini tek başına bütçenin
    /// üstüne çıkarıyor. Derecelendirme için tamamını taramak gerekmiyor: amaç bulmacanın
    /// o seviyede çözülüp çözülmediğini anlamak.
    public let hypothesisBudget: Int

    private let rules = HashiRules()

    public init(hypothesisBudget: Int = 48) {
        self.hypothesisBudget = hypothesisBudget
    }

    // MARK: - Benzersizlik

    public func findSolutions(of puzzle: HashiPuzzle, upTo limit: Int) throws -> [HashiSolution] {
        guard limit > 0 else { return [] }
        var domains = Domains(puzzle: puzzle)
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return [] }

        var found: [HashiSolution] = []
        search(domains, in: puzzle, limit: limit, into: &found)
        return found
    }

    // MARK: - Derecelendirme

    public func trace(of puzzle: HashiPuzzle) throws -> SolveTrace {
        var trace = SolveTrace()
        var domains = Domains(puzzle: puzzle)

        while true {
            let sums = enforceIslandSums(&domains, in: puzzle)
            if sums == .contradiction { return trace }
            if sums == .changed {
                trace.record("islandSum", tier: .basic)
                continue
            }

            let crossings = enforceCrossings(&domains, in: puzzle)
            if crossings == .contradiction { return trace }
            if crossings == .changed {
                trace.record("crossing", tier: .basic)
                continue
            }

            let connectivity = enforceConnectivity(&domains, in: puzzle)
            if connectivity == .contradiction { return trace }
            if connectivity == .changed {
                trace.record("connectivity", tier: .intermediate)
                continue
            }

            let hypothesis = enforceHypothesis(&domains, in: puzzle)
            if hypothesis == .contradiction { return trace }
            if hypothesis == .changed {
                trace.record("hypothesis", tier: .advanced)
                continue
            }

            break
        }

        if !domains.isDecided {
            // Mantıkla ilerlenemiyor. Rakip analizinde Slitherlink liderine gelen şikâyet
            // tam olarak bu durum: tek çözümü olan bulmaca da mantıkla çözülemeyebilir.
            trace.record("search", tier: .guessing)
        }
        return trace
    }

    // MARK: - Arama

    private func search(
        _ domains: Domains,
        in puzzle: HashiPuzzle,
        limit: Int,
        into found: inout [HashiSolution]
    ) {
        guard found.count < limit else { return }

        guard let edge = domains.mostConstrainedUndecided() else {
            let counts = domains.decidedValues()
            let board = HashiBoard(counts: counts)
            if rules.isSolved(board, in: puzzle) {
                found.append(HashiSolution(counts: counts))
            }
            return
        }

        // Değerler artan sırada: arama deterministik olmak zorunda, yoksa aynı tohum
        // farklı çözüm döndürür.
        for value in 0...2 where domains.allows(edge, value) {
            var branch = domains
            branch.restrict(edge, to: value)
            guard propagate(&branch, in: puzzle, upTo: .intermediate) else { continue }
            search(branch, in: puzzle, limit: limit, into: &found)
            if found.count >= limit { return }
        }
    }

    // MARK: - Yayılım

    /// `false` dönerse çelişki var.
    private func propagate(
        _ domains: inout Domains,
        in puzzle: HashiPuzzle,
        upTo tier: TechniqueTier
    ) -> Bool {
        while true {
            switch enforceIslandSums(&domains, in: puzzle) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            switch enforceCrossings(&domains, in: puzzle) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            if tier >= .intermediate {
                switch enforceConnectivity(&domains, in: puzzle) {
                case .contradiction: return false
                case .changed: continue
                case .unchanged: break
                }
            }

            if tier >= .advanced {
                switch enforceHypothesis(&domains, in: puzzle) {
                case .contradiction: return false
                case .changed: continue
                case .unchanged: break
                }
            }

            return true
        }
    }

    /// Ada derecesi toplamı kısıtı.
    ///
    /// Klasik Hashi başlangıç kurallarının hepsi bunun özel hali: derecesi komşu sayısının
    /// iki katı olan ada (hepsi çifte köprü), bir eksiği olan ada (hepsi en az bir), derecesi
    /// dolmuş ada (kalanlar sıfır), tek komşulu ada. Ayrı ayrı yazmak yerine toplam kısıtını
    /// yaymak hem daha kısa hem daha güçlü.
    private func enforceIslandSums(_ domains: inout Domains, in puzzle: HashiPuzzle) -> Step {
        var changed = false

        for island in puzzle.islands.indices {
            let incident = puzzle.incidentEdges[island]
            let required = puzzle.islands[island].required

            var minimum = 0
            var maximum = 0
            for edge in incident {
                guard domains.bits[edge] != 0 else { return .contradiction }
                minimum += domains.lowest(edge)
                maximum += domains.highest(edge)
            }
            if required < minimum || required > maximum { return .contradiction }

            for edge in incident {
                let othersMin = minimum - domains.lowest(edge)
                let othersMax = maximum - domains.highest(edge)
                for value in 0...2 where domains.allows(edge, value) {
                    let rest = required - value
                    if rest < othersMin || rest > othersMax {
                        domains.forbid(edge, value)
                        changed = true
                    }
                }
                guard domains.bits[edge] != 0 else { return .contradiction }
            }
        }

        return changed ? .changed : .unchanged
    }

    /// İki köprü aynı hücreden geçemez.
    private func enforceCrossings(_ domains: inout Domains, in puzzle: HashiPuzzle) -> Step {
        var changed = false

        for edge in puzzle.edges.indices where domains.lowest(edge) > 0 {
            for crossing in puzzle.crossingEdges[edge] {
                guard domains.allows(crossing, 0) else { return .contradiction }
                if domains.highest(crossing) > 0 {
                    domains.restrict(crossing, to: 0)
                    changed = true
                }
            }
        }

        return changed ? .changed : .unchanged
    }

    /// Bütün adalar tek ağda olmak zorunda; bundan iki çıkarım geliyor.
    private func enforceConnectivity(_ domains: inout Domains, in puzzle: HashiPuzzle) -> Step {
        let count = puzzle.islandCount
        guard count > 1 else { return .unchanged }

        // 1) Mümkün kenarlarla bile bütün adalar tek ağda olamıyorsa çelişki.
        var reachable = [Bool](repeating: false, count: count)
        reachable[0] = true
        var stack = [0]
        var seen = 1
        while let island = stack.popLast() {
            for edge in puzzle.incidentEdges[island] where domains.highest(edge) > 0 {
                let other = puzzle.otherIsland(of: edge, than: island)
                if !reachable[other] {
                    reachable[other] = true
                    seen += 1
                    stack.append(other)
                }
            }
        }
        if seen < count { return .contradiction }

        // 2) Kesinleşmiş köprülerle oluşan bir bileşenin dışarıya tek çıkışı kaldıysa
        //    o kenarda köprü olmak zorunda; hiç çıkışı kalmadıysa çelişki.
        var parent = Array(0..<count)
        for edge in puzzle.edges.indices where domains.lowest(edge) > 0 {
            union(&parent, puzzle.edges[edge].a, puzzle.edges[edge].b)
        }

        var size = [Int](repeating: 0, count: count)
        for island in 0..<count {
            size[find(&parent, island)] += 1
        }

        var exits = [Int: [Int]]()
        for edge in puzzle.edges.indices where domains.highest(edge) > 0 {
            let rootA = find(&parent, puzzle.edges[edge].a)
            let rootB = find(&parent, puzzle.edges[edge].b)
            guard rootA != rootB else { continue }
            exits[rootA, default: []].append(edge)
            exits[rootB, default: []].append(edge)
        }

        var changed = false
        for root in 0..<count where find(&parent, root) == root && size[root] < count {
            let outgoing = exits[root] ?? []
            if outgoing.isEmpty { return .contradiction }
            if outgoing.count == 1, domains.allows(outgoing[0], 0) {
                domains.forbid(outgoing[0], 0)
                guard domains.bits[outgoing[0]] != 0 else { return .contradiction }
                changed = true
            }
        }

        return changed ? .changed : .unchanged
    }

    /// Tek adım varsayım: bir kenara bir değer varsay, temel ve orta tekniklerle çelişki
    /// çıkarsa o değeri ele.
    ///
    /// Dallanmadan farkı, çelişkinin *kanıtlanması*: oyuncu da aynı akıl yürütmeyi yapıyor
    /// ("buraya köprü koyarsam şu ada kapanır, demek ki koyamam"). Dallanma ise tahmin.
    private func enforceHypothesis(_ domains: inout Domains, in puzzle: HashiPuzzle) -> Step {
        var tried = 0

        for edge in puzzle.edges.indices where domains.bits[edge].nonzeroBitCount > 1 {
            if tried >= hypothesisBudget { break }
            tried += 1

            for value in 0...2 where domains.allows(edge, value) {
                var hypothetical = domains
                hypothetical.restrict(edge, to: value)
                if !propagate(&hypothetical, in: puzzle, upTo: .intermediate) {
                    domains.forbid(edge, value)
                    guard domains.bits[edge] != 0 else { return .contradiction }
                    return .changed
                }
            }
        }

        return .unchanged
    }

    // MARK: - Birleştirme-bulma

    private func find(_ parent: inout [Int], _ node: Int) -> Int {
        var root = node
        while parent[root] != root {
            root = parent[root]
        }
        var walker = node
        while parent[walker] != root {
            let next = parent[walker]
            parent[walker] = root
            walker = next
        }
        return root
    }

    private func union(_ parent: inout [Int], _ first: Int, _ second: Int) {
        let rootA = find(&parent, first)
        let rootB = find(&parent, second)
        if rootA != rootB {
            parent[max(rootA, rootB)] = min(rootA, rootB)
        }
    }
}

extension HashiSolver {
    enum Step {
        case unchanged
        case changed
        case contradiction
    }

    /// Kenar başına hâlâ mümkün köprü sayıları, bit maskesi olarak. Bit v → v köprü mümkün.
    struct Domains {
        var bits: [UInt8]

        init(puzzle: HashiPuzzle) {
            bits = puzzle.edges.map { edge in
                var mask: UInt8 = 0
                for value in 0...edge.capacity {
                    mask |= 1 << UInt8(value)
                }
                return mask
            }
        }

        func allows(_ edge: Int, _ value: Int) -> Bool {
            bits[edge] & (1 << UInt8(value)) != 0
        }

        func lowest(_ edge: Int) -> Int {
            Int(bits[edge].trailingZeroBitCount)
        }

        func highest(_ edge: Int) -> Int {
            7 - Int(bits[edge].leadingZeroBitCount)
        }

        mutating func forbid(_ edge: Int, _ value: Int) {
            bits[edge] &= ~(1 << UInt8(value))
        }

        mutating func restrict(_ edge: Int, to value: Int) {
            bits[edge] &= 1 << UInt8(value)
        }

        var isDecided: Bool {
            bits.allSatisfy { $0.nonzeroBitCount == 1 }
        }

        /// En az seçeneği kalan karar verilmemiş kenar. Arama önce buradan dallanıyor;
        /// dallanma çarpanını en küçük tutan sıralama bu.
        func mostConstrainedUndecided() -> Int? {
            var best: Int?
            var bestCount = Int.max
            for edge in bits.indices {
                let count = bits[edge].nonzeroBitCount
                if count > 1 && count < bestCount {
                    best = edge
                    bestCount = count
                    if count == 2 { break }
                }
            }
            return best
        }

        func decidedValues() -> [Int] {
            bits.map { Int($0.trailingZeroBitCount) }
        }
    }
}
