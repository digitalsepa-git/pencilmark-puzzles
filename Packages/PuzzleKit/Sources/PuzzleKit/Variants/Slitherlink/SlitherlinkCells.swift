// Hücre ve köşelerinin birlikte yayılımı.
//
// İlk sürümde ipucu kısıtı ile nokta paritesi ayrı ayrı yayılıyordu ve ikisi de yalnız uç
// durumlarda ateşliyordu: "çizgi sayısı ipucuna eşit" ya da "tek aday kaldı". Sonucu
// ölçümde görüldü — en küçük bulmaca bile varsayım tekniği gerektiriyor, yani Easy ve
// Medium hiç üretilemezdi (ADR 0011'in dersi: dağılım tek seviyede yığılıyorsa önce
// çözücüye bakılacak).
//
// Yayınlanmış Slitherlink'in klasik açılış desenleri — köşedeki 3, yan yana iki 3, köşedeki
// 1 — ipucu ile köşe noktalarının paritesinin *birleşiminden* çıkıyor. Tek tek yazmak
// yerine birleşimi doğrudan sayıyoruz: hücrenin dört kenarı için 16 olasılığın hangileri
// hem ipucuna hem dört köşesinin paritesine uyuyor. Uymayan her olasılık eleniyor.

extension SlitherlinkSolver {
    /// Hücrenin dört kenarı için mümkün dizilimleri sayıp, hiçbirinde görünmeyen durumu
    /// eliyor.
    ///
    /// İpucu olmayan hücreler de taranıyor: köşe noktalarının paritesi tek başına kenar
    /// zorlayabiliyor.
    func enforceCells(_ domains: inout Domains, in puzzle: SlitherlinkPuzzle) -> Step {
        var changed = false

        for cell in 0..<puzzle.cellCount {
            let edges = puzzle.edgesOfCell[cell]
            let clue = puzzle.clue(at: cell)
            let corners = cornerDots(of: cell, in: puzzle)

            var canBeLine = [Bool](repeating: false, count: 4)
            var canBeCross = [Bool](repeating: false, count: 4)
            var anyFeasible = false

            for mask in 0..<16 {
                if let clue, mask.nonzeroBitCount != clue { continue }

                var allowed = true
                for slot in 0..<4 {
                    let wantsLine = mask & (1 << slot) != 0
                    if wantsLine ? !domains.allowsLine(edges[slot]) : !domains.allowsCross(edges[slot]) {
                        allowed = false
                        break
                    }
                }
                guard allowed else { continue }
                guard corners.allSatisfy({
                    isDotFeasible($0, cell: cell, mask: mask, domains: domains, in: puzzle)
                }) else { continue }

                anyFeasible = true
                for slot in 0..<4 {
                    if mask & (1 << slot) != 0 { canBeLine[slot] = true } else { canBeCross[slot] = true }
                }
            }

            guard anyFeasible else { return .contradiction }

            for slot in 0..<4 {
                let edge = edges[slot]
                if !canBeLine[slot], domains.allowsLine(edge) {
                    domains.forceCross(edge)
                    changed = true
                }
                if !canBeCross[slot], domains.allowsCross(edge) {
                    domains.forceLine(edge)
                    changed = true
                }
            }
        }

        if domains.hasEmptyDomain { return .contradiction }
        return changed ? .changed : .unchanged
    }

    /// Hücrenin verilen dizilimi, bu köşe noktasının derecesini 0 ya da 2 yapabilir mi.
    ///
    /// Noktanın derecesi iki kaynaktan geliyor: bu hücrenin katkısı (dizilimden belli) ve
    /// noktaya değen diğer kenarların alabileceği en küçük/en büyük değer. Derece 0 yalnız
    /// her iki kaynak da sıfırken mümkün; 2 ise aralığa düşüyorsa mümkün.
    private func isDotFeasible(
        _ dot: Int,
        cell: Int,
        mask: Int,
        domains: Domains,
        in puzzle: SlitherlinkPuzzle
    ) -> Bool {
        let cellEdges = puzzle.edgesOfCell[cell]
        var contributed = 0
        var otherMinimum = 0
        var otherMaximum = 0

        for edge in puzzle.edgesOfDot[dot] {
            if let slot = cellEdges.firstIndex(of: edge) {
                if mask & (1 << slot) != 0 { contributed += 1 }
                continue
            }
            if domains.isLine(edge) {
                otherMinimum += 1
                otherMaximum += 1
            } else if domains.allowsLine(edge) {
                otherMaximum += 1
            }
        }

        if contributed == 0 && otherMinimum == 0 { return true }
        return contributed + otherMinimum <= 2 && contributed + otherMaximum >= 2
    }

    /// Hücrenin dört köşe noktası.
    private func cornerDots(of cell: Int, in puzzle: SlitherlinkPuzzle) -> [Int] {
        let position = puzzle.position(of: cell)
        let stride = puzzle.size.columns + 1
        let topLeft = position.row * stride + position.column
        return [topLeft, topLeft + 1, topLeft + stride, topLeft + stride + 1]
    }
}
