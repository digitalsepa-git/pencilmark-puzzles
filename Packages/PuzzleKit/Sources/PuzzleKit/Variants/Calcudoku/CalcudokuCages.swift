// Kafes kısıtının yayılımı.
//
// Ayrı dosyada, çünkü Calcudoku'nun asıl zorluğu burada: Latin kısıtı Sudoku'dan bilinen
// standart iş, kafes aritmetiği ise her kafes için küçük bir arama gerektiriyor.

extension CalcudokuSolver {
    /// Kafesin hedefini tutturabilen değer bileşimlerini arayıp, hiçbir bileşimde
    /// görünmeyen adayları eliyor.
    ///
    /// Hayatta kalan her bileşim, içindeki değerleri "mümkün" olarak işaretliyor;
    /// işaretlenmeyen adaylar eleniyor. Bu, kafes düzeyinde tam tutarlılık (GAC) demek.
    func enforceCage(
        _ cage: CalcudokuCage,
        _ domains: inout Domains,
        in puzzle: CalcudokuPuzzle
    ) -> Step {
        // Alanların çarpımı çok büyükse bu geçişte atlıyoruz: alanlar daraldıkça aynı kafes
        // ucuzlayacak ve sıra ona yine gelecek. Sınır olmadan 5 hücreli bir kafes tek başına
        // 59.049 bileşim deniyor ve üretim süresini bütçenin üstüne çıkarıyor.
        var combinations = 1
        for cell in cage.cells {
            combinations *= domains.sets[cell].count
            if combinations > Self.cageSearchLimit { return .unchanged }
        }

        var search = CageSearch(cage: cage, puzzle: puzzle, domains: domains)
        search.run(from: 0)

        var changed = false
        for (slot, cell) in cage.cells.enumerated() {
            if search.feasible[slot].isEmpty { return .contradiction }
            if domains.restrict(cell, to: search.feasible[slot]) { changed = true }
        }
        return changed ? .changed : .unchanged
    }
}

/// Tek bir kafesin mümkün değer bileşimlerini arayan derinlik-öncelikli gezinme.
///
/// Kafes, bulmaca ve alanlar durum olarak tutuluyor; özyinelemeli çağrıya yalnız derinlik
/// geçiyor. Hepsini parametre olarak taşımak imza sınırını aşıyordu ve her çağrıda
/// kopyalanıyordu.
private struct CageSearch {
    let cage: CalcudokuCage
    let puzzle: CalcudokuPuzzle
    let domains: CalcudokuSolver.Domains

    var chosen: [Int]
    /// Kafes yuvası → o yuvada en az bir geçerli bileşimde görülen değerler.
    var feasible: [DigitSet]

    init(cage: CalcudokuCage, puzzle: CalcudokuPuzzle, domains: CalcudokuSolver.Domains) {
        self.cage = cage
        self.puzzle = puzzle
        self.domains = domains
        self.chosen = [Int](repeating: 0, count: cage.size)
        self.feasible = [DigitSet](repeating: .empty, count: cage.size)
    }

    mutating func run(from index: Int) {
        guard index < cage.size else {
            guard cage.isSatisfied(by: chosen) else { return }
            for slot in 0..<cage.size {
                feasible[slot].insert(chosen[slot])
            }
            return
        }

        for digit in domains.sets[cage.cells[index]] {
            guard isDistinctFromPeers(digit, slot: index) else { continue }
            chosen[index] = digit
            guard canStillReachTarget(prefix: index + 1) else { continue }
            run(from: index + 1)
        }
    }

    /// Kafes içindeki iki hücre aynı satır veya sütunu paylaşıyorsa aynı değeri alamaz.
    ///
    /// Latin kısıtının kafes aramasına taşınması. Olmasa arama, satırda tekrar eden
    /// bileşimleri de "mümkün" sayar ve eleme gücünü kaybeder.
    private func isDistinctFromPeers(_ digit: Int, slot: Int) -> Bool {
        let cell = cage.cells[slot]
        for earlier in 0..<slot where chosen[earlier] == digit {
            if puzzle.peers[cell].contains(cage.cells[earlier]) { return false }
        }
        return true
    }

    /// Kısmi bileşim hedefe hâlâ ulaşabilir mi.
    private func canStillReachTarget(prefix: Int) -> Bool {
        let remaining = cage.size - prefix
        guard remaining > 0 else { return true }

        switch cage.operation {
        case .add:
            let sum = chosen[0..<prefix].reduce(0, +)
            return sum + remaining <= cage.target
                && sum + remaining * puzzle.side >= cage.target
        case .multiply:
            let product = chosen[0..<prefix].reduce(1, *)
            return product != 0 && cage.target % product == 0
        case .given, .subtract, .divide:
            // Tek ve iki hücreli kafeslerde kesilecek dal yok: arama zaten en fazla
            // dokuz değer deniyor.
            return true
        }
    }
}
