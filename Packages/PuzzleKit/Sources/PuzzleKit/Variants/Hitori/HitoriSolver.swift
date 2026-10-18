/// Hitori çözücüsü: kısıt yayılımı + geri izleme.
///
/// Hashi'nin çözücüsüyle aynı iskelet (bkz. `HashiSolver`): aynı iki iş — benzersizlik
/// kontrolü (brief b.11) ve zorluk derecelendirmesi (b.6) — aynı seviye sıralamasıyla.
///
/// Teknik seviyeleri (Hitori'ye özel liste, ADR 0011):
///
/// | Seviye | Teknik | Ne yapıyor |
/// |---|---|---|
/// | `basic` | komşuluk | Karalı hücrenin bütün komşuları beyaz |
/// | `basic` | grup | Beyaz kalan hücrenin grubundaki diğer bütün hücreler karalı |
/// | `basic` | komşu ikili | Aynı gruptaki iki hücre komşuysa biri beyaz kalmak zorunda,
///   dolayısıyla gruptaki geri kalan hücreler karalı. Klasik "üçlü" kuralı bunun sonucu:
///   yan yana üç aynı sayıda ortadaki beyaz, dıştakiler karalı |
/// | `intermediate` | beyaz bölge bağlı mı | Kesinleşmiş beyazlar mümkün beyazlar üzerinden
///   birbirine ulaşamıyorsa çelişki |
/// | `intermediate` | kopuk beyaz adacığı | Kesinleşmiş beyaz içermeyen bir mümkün-beyaz
///   bölgesinin tamamı karalı olmak zorunda |
/// | `advanced` | tek adım varsayım | Bir hücreye bir durum varsayılıp çelişki aranıyor |
/// | `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor |
public struct HitoriSolver: PuzzleSolver {
    public typealias Definition = HitoriPuzzle
    public typealias Solution = HitoriSolution

    /// Tek adım varsayımın deneyeceği en fazla hücre sayısı (bkz. `HashiSolver`).
    public let hypothesisBudget: Int

    private let rules = HitoriRules()

    public init(hypothesisBudget: Int = 64) {
        self.hypothesisBudget = hypothesisBudget
    }

    // MARK: - Benzersizlik

    public func findSolutions(of puzzle: HitoriPuzzle, upTo limit: Int) throws -> [HitoriSolution] {
        guard limit > 0 else { return [] }
        var domains = Domains(puzzle: puzzle)
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return [] }

        var found: [HitoriSolution] = []
        search(domains, in: puzzle, limit: limit, into: &found)
        return found
    }

    // MARK: - Derecelendirme

    public func trace(of puzzle: HitoriPuzzle) throws -> SolveTrace {
        var trace = SolveTrace()
        var domains = Domains(puzzle: puzzle)

        while true {
            let basic = enforceBasic(&domains, in: puzzle)
            if basic == .contradiction { return trace }
            if basic == .changed {
                trace.record("basic", tier: .basic)
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
            trace.record("search", tier: .guessing)
        }
        return trace
    }

    // MARK: - Arama

    private func search(
        _ domains: Domains,
        in puzzle: HitoriPuzzle,
        limit: Int,
        into found: inout [HitoriSolution]
    ) {
        guard found.count < limit else { return }

        guard let cell = domains.firstUndecided() else {
            if rules.isSolved(domains.board(for: puzzle), in: puzzle) {
                found.append(domains.solution(for: puzzle))
            }
            return
        }

        // Sıra deterministik: önce beyaz, sonra karalı.
        for white in [true, false] {
            var branch = domains
            if white {
                branch.forceWhite(cell)
            } else {
                branch.forceShaded(cell)
            }
            guard propagate(&branch, in: puzzle, upTo: .intermediate) else { continue }
            search(branch, in: puzzle, limit: limit, into: &found)
            if found.count >= limit { return }
        }
    }

    // MARK: - Yayılım

    /// `false` dönerse çelişki var.
    func propagate(
        _ domains: inout Domains,
        in puzzle: HitoriPuzzle,
        upTo tier: TechniqueTier
    ) -> Bool {
        while true {
            switch enforceBasic(&domains, in: puzzle) {
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

    /// Komşuluk ve grup kısıtları. Klasik Hitori başlangıç kurallarının tamamı buradan çıkıyor.
    private func enforceBasic(_ domains: inout Domains, in puzzle: HitoriPuzzle) -> Step {
        var changed = false

        for cell in 0..<puzzle.cellCount where domains.isShaded(cell) {
            for neighbor in puzzle.neighbors[cell] where domains.allowsShaded(neighbor) {
                domains.forceWhite(neighbor)
                changed = true
            }
        }

        for group in puzzle.groups {
            var whites = 0
            for cell in group where domains.isWhite(cell) {
                whites += 1
            }
            // Bir grupta iki beyaz olamaz: aynı satır/sütunda aynı sayı tekrar etmiş olurdu.
            if whites > 1 { return .contradiction }

            if whites == 1 {
                for cell in group where !domains.isWhite(cell) && domains.allowsWhite(cell) {
                    domains.forceShaded(cell)
                    changed = true
                }
                continue
            }

            // Komşu ikili: gruptaki iki hücre komşuysa ikisi birden karalanamaz (komşuluk)
            // ve ikisi birden beyaz kalamaz (grup) — yani biri beyaz. O zaman gruptaki geri
            // kalan hücrelerin hepsi karalı.
            guard let pair = adjacentPair(in: group, of: puzzle, domains: domains) else { continue }
            for cell in group where cell != pair.0 && cell != pair.1 && domains.allowsWhite(cell) {
                domains.forceShaded(cell)
                changed = true
            }
        }

        if domains.hasEmptyDomain { return .contradiction }
        return changed ? .changed : .unchanged
    }

    private func adjacentPair(
        in group: [Int],
        of puzzle: HitoriPuzzle,
        domains: Domains
    ) -> (Int, Int)? {
        for cell in group where domains.allowsWhite(cell) {
            for neighbor in puzzle.neighbors[cell]
            where group.contains(neighbor) && domains.allowsWhite(neighbor) {
                return (cell, neighbor)
            }
        }
        return nil
    }

    /// Tek adım varsayım: bir hücreye bir durum varsay, temel ve orta tekniklerle çelişki
    /// çıkarsa o durumu ele. Dallanmadan farkı çelişkinin kanıtlanması (bkz. `HashiSolver`).
    private func enforceHypothesis(_ domains: inout Domains, in puzzle: HitoriPuzzle) -> Step {
        var tried = 0

        for cell in 0..<puzzle.cellCount where domains.isUndecided(cell) {
            if tried >= hypothesisBudget { break }
            tried += 1

            for white in [true, false] {
                var hypothetical = domains
                if white {
                    hypothetical.forceWhite(cell)
                } else {
                    hypothetical.forceShaded(cell)
                }
                guard !propagate(&hypothetical, in: puzzle, upTo: .intermediate) else { continue }
                if white {
                    domains.forceShaded(cell)
                } else {
                    domains.forceWhite(cell)
                }
                return .changed
            }
        }

        return .unchanged
    }
}
