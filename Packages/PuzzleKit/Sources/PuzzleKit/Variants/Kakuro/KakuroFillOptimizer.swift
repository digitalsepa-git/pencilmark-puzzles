// Doldurmanın kısıt gücüne göre eniyilenmesi.
//
// ADR 0013'ün ilk teşhisi eksikti: kapalı 2×2 blokları eledikten sonra da benzersizlik
// sıfırda kaldı. Asıl sorun desende değil **toplamlarda**: rastgele bir doldurma orta
// değerli toplamlar üretiyor ve orta değerli bir toplamın onlarca rakam bileşimi var,
// yani çözücünün tutunacağı yer yok.
//
// "İki hücrede 17" demek {8,9} demek — tek bileşim. "İki hücrede 9" demek
// {1,8},{2,7},{3,6},{4,5} demek — dört bileşim, iki de sıralama, sekiz seçenek. Bulmacanın
// çözülebilirliği kesitlerin bileşim sayısına bağlı ve doldurmayı o sayıyı küçültecek
// şekilde seçmek gerekiyor. Ölçüm: eniyileme olmadan 1.160 adayda sıfır benzersiz, varken
// Easy'de %85.

extension KakuroGenerator {
    /// Doldurmayı, kesitlerin bileşim sayısı toplamını küçültecek şekilde iyileştiriyor.
    ///
    /// Tepe tırmanma: rastgele bir giriş hücresine, kesitlerinde kullanılmayan başka bir
    /// rakam yazılıyor ve maliyet düşüyorsa kabul ediliyor.
    ///
    /// Maliyet artımlı hesaplanıyor: bir hücreyi değiştirmek yalnız o hücrenin iki kesidinin
    /// toplamını değiştiriyor, geri kalan kesitler aynı kalıyor. İlk sürüm her hamlede
    /// bütün kesitleri yeniden bölütleyip yeniden sayıyordu ve üretim süresinin büyük kısmı
    /// oradaydı.
    public static func optimizeFill(
        _ digits: inout Grid<Int>,
        pattern: Grid<Bool>,
        iterations: Int,
        using rng: inout SeededGenerator
    ) {
        guard iterations > 0 else { return }
        let entries = pattern.allPositions.filter { !pattern[$0] }
        guard !entries.isEmpty else { return }

        let runs = segments(of: pattern)
        var runsOfCell = [[Int]](repeating: [], count: pattern.size.cellCount)
        for (index, run) in runs.enumerated() {
            for cell in run {
                runsOfCell[cell].append(index)
            }
        }

        var runCosts = runs.map { cost(of: $0, digits: digits) }
        var total = runCosts.reduce(0, +)

        for _ in 0..<iterations {
            let position = entries[Int.random(in: 0..<entries.count, using: &rng)]
            let previous = digits[position]
            guard perturb(&digits, pattern: pattern, at: position, using: &rng) else { continue }

            let affected = runsOfCell[position.row * pattern.size.columns + position.column]
            var delta = 0
            var updated: [Int] = []
            updated.reserveCapacity(affected.count)
            for index in affected {
                let fresh = cost(of: runs[index], digits: digits)
                delta += fresh - runCosts[index]
                updated.append(fresh)
            }

            if delta <= 0 {
                total += delta
                for (slot, index) in affected.enumerated() {
                    runCosts[index] = updated[slot]
                }
            } else {
                digits[position] = previous
            }
        }
        _ = total
    }

    /// Bütün kesitlerin bileşim sayılarının toplamı. Küçük olan daha kısıtlı bulmaca demek.
    ///
    /// Kesit başına "bu uzunluk ve toplam için kaç rakam kümesi mümkün" sayısı toplanıyor.
    /// Tek bileşimli kesit 1 getiriyor, belirsiz bir kesit onlarca.
    public static func combinationCost(_ digits: Grid<Int>, pattern: Grid<Bool>) -> Int {
        segments(of: pattern).reduce(0) { $0 + cost(of: $1, digits: digits) }
    }

    private static func cost(of run: [Int], digits: Grid<Int>) -> Int {
        let sum = run.reduce(0) { $0 + digits.elements[$1] }
        return KakuroCombinations.sets(length: run.count, sum: sum).count
    }
}
