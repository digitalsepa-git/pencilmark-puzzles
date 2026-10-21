// Kesit toplamı bileşimlerinin yayılımı — Kakuro'nun asıl tekniği.
//
// Ayrı dosyada, çünkü iki iş birlikte duruyor: hangi rakam kümelerinin mümkün olduğunu
// bulmak (bileşim tablosu) ve bir kümenin gerçekten yerleştirilebilir olup olmadığını
// doğrulamak (hücre-rakam eşleştirmesi).

extension KakuroSolver {
    /// Her kesit için mümkün rakam kümelerini tarayıp, hiçbirinde görünmeyen adayları eliyor.
    func enforceCombinations(_ domains: inout Domains, in puzzle: KakuroPuzzle) -> Step {
        var changed = false

        for run in puzzle.runs {
            var allowed = [DigitSet](repeating: .empty, count: run.length)
            var anyFeasible = false

            // Kesidin hücrelerinin alanlarının birleşimi: bir rakam kümesi bunun dışına
            // çıkıyorsa yerleştirilemez. Eşleştirme çalıştırmadan önceki ucuz elek —
            // eşleştirme O(uzunluk²) ve kesit başına yirmi küme denenebiliyor, bu elek
            // çoğunu O(uzunluk)'ta reddediyor.
            var union = DigitSet.empty
            for cell in run.cells {
                union = union.union(domains.sets[cell])
            }

            for candidate in KakuroCombinations.sets(length: run.length, sum: run.sum) {
                guard candidate.subtracting(union).isEmpty else { continue }
                guard run.cells.allSatisfy({ !domains.sets[$0].isDisjoint(with: candidate) })
                else { continue }
                // Küme gerçekten yerleştirilebilir mi: her hücreye bir rakam, her rakama bir
                // hücre. Yalnız "rakam bu hücrenin alanında var mı" bakmak yetmez — üç
                // hücrenin üçü de aynı tek rakamı kabul ediyorsa küme imkânsız olur.
                guard canPlace(candidate, in: run, domains: domains) else { continue }
                anyFeasible = true
                for (slot, cell) in run.cells.enumerated() {
                    allowed[slot] = allowed[slot].union(candidate.intersection(domains.sets[cell]))
                }
            }

            guard anyFeasible else { return .contradiction }

            for (slot, cell) in run.cells.enumerated() where domains.restrict(cell, to: allowed[slot]) {
                changed = true
            }
            if domains.hasEmptyDomain { return .contradiction }
        }

        return changed ? .changed : .unchanged
    }

    /// Her mümkün kümede bulunan bir rakam, kesitte yalnız bir hücreye yazılabiliyorsa
    /// oraya yazılıyor.
    ///
    /// Sudoku'nun "gizli tek"inin Kakuro karşılığı, bir farkla: Kakuro'da kesitte hangi
    /// rakamların geçeceği baştan belli değil, bileşimlerden türüyor. Bütün bileşimlerin
    /// kesişimi "bu kesitte kesinlikle var" demek olan rakamları veriyor.
    func enforceRequiredDigits(_ domains: inout Domains, in puzzle: KakuroPuzzle) -> Step {
        var changed = false

        for run in puzzle.runs {
            var required = DigitSet.all
            var anyFeasible = false
            for candidate in KakuroCombinations.sets(length: run.length, sum: run.sum)
            where canPlace(candidate, in: run, domains: domains) {
                required = required.intersection(candidate)
                anyFeasible = true
            }
            guard anyFeasible else { return .contradiction }

            for digit in required {
                var holder: Int?
                var count = 0
                for cell in run.cells where domains.sets[cell].contains(digit) {
                    holder = cell
                    count += 1
                    if count > 1 { break }
                }
                if count == 0 { return .contradiction }
                guard count == 1, let cell = holder, !domains.isDecided(cell) else { continue }
                domains.sets[cell] = DigitSet([digit])
                changed = true
            }
        }

        return changed ? .changed : .unchanged
    }

    /// Verilen rakam kümesi bu kesite yerleştirilebilir mi: her hücreye bir rakam, her
    /// rakama bir hücre.
    ///
    /// Yalnız "rakam bu hücrenin alanında var mı" bakmak yetmez: üç hücrenin üçü de aynı tek
    /// rakamı kabul ediyorsa küme imkânsızdır ama hücre bazlı kontrol bunu görmez.
    private func canPlace(_ candidate: DigitSet, in run: KakuroRun, domains: Domains) -> Bool {
        var matching = RunMatching(candidate: candidate, run: run, domains: domains)
        return matching.isComplete()
    }
}

/// Kesit hücreleri ile bir rakam kümesi arasında tam eşleştirme arayan gezinme.
///
/// İki taraflı eşleştirme (Kuhn). Kesit en fazla dokuz hücre olduğu için basit artırma yolu
/// araması yeterli; daha iyi bir algoritmanın getirisi ölçülebilir değil. Durum ayrı tipte,
/// çünkü özyinelemeli çağrıya altı parametre taşımak hem okunmuyor hem her çağrıda
/// kopyalanıyordu.
private struct RunMatching {
    let digits: [Int]
    let cells: [Int]
    let domains: KakuroSolver.Domains
    /// Rakam yuvası → eşleştiği hücre yuvası; `-1` eşleşmemiş.
    var digitToCell: [Int]

    init(candidate: DigitSet, run: KakuroRun, domains: KakuroSolver.Domains) {
        self.digits = Array(candidate)
        self.cells = run.cells
        self.domains = domains
        self.digitToCell = [Int](repeating: -1, count: digits.count)
    }

    mutating func isComplete() -> Bool {
        guard digits.count == cells.count else { return false }
        for cellSlot in cells.indices {
            var visited = [Bool](repeating: false, count: digits.count)
            guard augment(cellSlot: cellSlot, visited: &visited) else { return false }
        }
        return true
    }

    private mutating func augment(cellSlot: Int, visited: inout [Bool]) -> Bool {
        let cell = cells[cellSlot]
        for (digitSlot, digit) in digits.enumerated() {
            guard !visited[digitSlot], domains.sets[cell].contains(digit) else { continue }
            visited[digitSlot] = true
            let occupant = digitToCell[digitSlot]
            if occupant < 0 || augment(cellSlot: occupant, visited: &visited) {
                digitToCell[digitSlot] = cellSlot
                return true
            }
        }
        return false
    }
}
