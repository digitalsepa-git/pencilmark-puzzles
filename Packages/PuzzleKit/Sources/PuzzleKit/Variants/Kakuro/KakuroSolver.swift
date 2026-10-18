/// Kakuro çözücüsü: kısıt yayılımı + geri izleme.
///
/// Diğer üç varyantla aynı iskelet. Kakuro'ya özel olan, kesit toplamı bileşimlerinin
/// yayılımı: "üç hücrede 24" demek {7,8,9} demek ve bu tek başına bulmacanın büyük kısmını
/// açıyor.
///
/// Teknik seviyeleri (ADR 0013):
///
/// | Seviye | Teknik | Ne yapıyor |
/// |---|---|---|
/// | `basic` | kesit elemesi | Kesinleşmiş rakam, kesitteki diğer hücrelerin adaylarından
///   siliniyor |
/// | `basic` | bileşim | Kesit uzunluğu ve toplamı için mümkün rakam kümeleri taranıyor;
///   hiçbirinde görünmeyen aday eleniyor |
/// | `intermediate` | zorunlu rakam | Her mümkün kümede bulunan bir rakam, kesitte yalnız
///   bir hücreye yazılabiliyorsa oraya yazılıyor |
/// | `advanced` | tek adım varsayım | Bir hücreye rakam varsayılıp çelişki aranıyor |
/// | `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor |
public struct KakuroSolver: PuzzleSolver {
    public typealias Definition = KakuroPuzzle
    public typealias Solution = KakuroSolution

    /// Tek adım varsayımın deneyeceği en fazla hücre sayısı.
    public let hypothesisBudget: Int

    private let rules = KakuroRules()

    public init(hypothesisBudget: Int = 48) {
        self.hypothesisBudget = hypothesisBudget
    }

    // MARK: - Benzersizlik

    public func findSolutions(of puzzle: KakuroPuzzle, upTo limit: Int) throws -> [KakuroSolution] {
        guard limit > 0 else { return [] }
        var domains = Domains(puzzle: puzzle)
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return [] }

        var found: [KakuroSolution] = []
        search(domains, in: puzzle, limit: limit, into: &found)
        return found
    }

    // MARK: - Derecelendirme

    public func trace(of puzzle: KakuroPuzzle) throws -> SolveTrace {
        var trace = SolveTrace()
        var domains = Domains(puzzle: puzzle)

        while true {
            let elimination = enforceRunElimination(&domains, in: puzzle)
            if elimination == .contradiction { return trace }
            if elimination == .changed {
                trace.record("runElimination", tier: .basic)
                continue
            }

            let combinations = enforceCombinations(&domains, in: puzzle)
            if combinations == .contradiction { return trace }
            if combinations == .changed {
                trace.record("combination", tier: .basic)
                continue
            }

            let required = enforceRequiredDigits(&domains, in: puzzle)
            if required == .contradiction { return trace }
            if required == .changed {
                trace.record("requiredDigit", tier: .intermediate)
                continue
            }

            let hypothesis = enforceHypothesis(&domains, in: puzzle)
            if hypothesis.step == .contradiction { return trace }
            if hypothesis.step == .changed {
                // Eleme sayısı tek tek kaydediliyor ama tek geçişte bulunuyor — ADR 0012'de
                // Calcudoku için alınan karar, aynı gerekçeyle burada da.
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

    /// Temel ve orta tekniklerin tek başına açtığı giriş hücresi oranı.
    ///
    /// Calcudoku'da Hard/Expert ayrımı için eklenmişti (ADR 0012); Kakuro'da da ölçülüp
    /// gerekip gerekmediğine bakılacak.
    public func logicalProgress(of puzzle: KakuroPuzzle) -> Double {
        var domains = Domains(puzzle: puzzle)
        guard propagate(&domains, in: puzzle, upTo: .intermediate) else { return 0 }
        let decided = puzzle.entryCells.count { domains.isDecided($0) }
        return Double(decided) / Double(max(1, puzzle.entryCount))
    }

    // MARK: - Arama

    private func search(
        _ domains: Domains,
        in puzzle: KakuroPuzzle,
        limit: Int,
        into found: inout [KakuroSolution]
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
        in puzzle: KakuroPuzzle,
        upTo tier: TechniqueTier
    ) -> Bool {
        while true {
            switch enforceRunElimination(&domains, in: puzzle) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            switch enforceCombinations(&domains, in: puzzle) {
            case .contradiction: return false
            case .changed: continue
            case .unchanged: break
            }

            if tier >= .intermediate {
                switch enforceRequiredDigits(&domains, in: puzzle) {
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

    /// Kesinleşmiş rakam, aynı kesitteki diğer hücrelerin adaylarından siliniyor.
    private func enforceRunElimination(
        _ domains: inout Domains,
        in puzzle: KakuroPuzzle
    ) -> Step {
        var changed = false

        for run in puzzle.runs {
            for cell in run.cells {
                guard let value = domains.value(of: cell) else { continue }
                for other in run.cells where other != cell && domains.remove(value, from: other) {
                    changed = true
                }
            }
        }

        if domains.hasEmptyDomain { return .contradiction }
        return changed ? .changed : .unchanged
    }

    /// Tek adım varsayım. Tek geçişte bulduğu bütün elemeleri uyguluyor (ADR 0012).
    private func enforceHypothesis(
        _ domains: inout Domains,
        in puzzle: KakuroPuzzle
    ) -> (step: Step, eliminations: Int) {
        var tried = 0
        var eliminations = 0

        for cell in puzzle.entryCells where !domains.isDecided(cell) {
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
