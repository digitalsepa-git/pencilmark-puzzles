// Döngü kısıtının yayılımı — Slitherlink'i diğer dört varyanttan ayıran şey.
//
// Diğerlerinde kısıtlar yereldi: ada derecesi, karalama komşuluğu, kafes aritmetiği, kesit
// toplamı. Burada kısıt küresel — çizgiler tek bir kapalı döngü oluşturmak zorunda — ve bu
// yayılıma iki ayrı yoldan giriyor: nokta paritesi (yerel) ve erken kapanma (küresel).

extension SlitherlinkSolver {
    /// Nokta paritesi: her noktanın derecesi 0 ya da 2.
    ///
    /// Döngünün yerel yüzü. Dört çıkarım buradan geliyor ve klasik Slitherlink açılış
    /// hamlelerinin çoğu bunların birleşimi.
    func enforceDotParity(_ domains: inout Domains, in puzzle: SlitherlinkPuzzle) -> Step {
        var changed = false

        for dot in 0..<puzzle.dotCount {
            let incident = puzzle.edgesOfDot[dot]
            var lines = 0
            var undecided = 0
            for edge in incident {
                if domains.isLine(edge) { lines += 1 } else if domains.isUndecided(edge) { undecided += 1 }
            }

            // Üç çizgi bir noktada birleşemez: döngü dallanmaz.
            if lines > 2 { return .contradiction }

            if lines == 2 {
                for edge in incident where domains.isUndecided(edge) {
                    domains.forceCross(edge)
                    changed = true
                }
                continue
            }

            if lines == 1 {
                // Derece 2'ye tamamlanmak zorunda: tek bir aday kaldıysa o çizgidir.
                if undecided == 0 { return .contradiction }
                if undecided == 1 {
                    for edge in incident where domains.isUndecided(edge) {
                        domains.forceLine(edge)
                        changed = true
                    }
                }
                continue
            }

            // lines == 0: derece 0 ya da 2. Tek aday kalmışsa çizgi olamaz, çünkü derece
            // 1 mümkün değil.
            if undecided == 1 {
                for edge in incident where domains.isUndecided(edge) {
                    domains.forceCross(edge)
                    changed = true
                }
            }
        }

        if domains.hasEmptyDomain { return .contradiction }
        return changed ? .changed : .unchanged
    }

    /// Erken kapanma: bir kenarı çizgi yapmak döngüyü kapatacaksa ve dışarıda başka çizgi
    /// varsa o kenar çarpıdır.
    ///
    /// Döngünün küresel yüzü. Kapanan parça başka çizgilerle birleşemeyeceği için sonuç iki
    /// ayrı döngü olurdu, ve çözüm tek döngü olmak zorunda.
    ///
    /// Kural bilerek muhafazakâr: "dışarıda başka çizgi var" koşulu sağlamdır ama tam
    /// değildir — kapanma, dışarıda çizgi olmasa da henüz tutturulmamış bir ipucu yüzünden
    /// yasak olabilir. O durumu varsayım tekniği yakalıyor.
    func enforcePrematureClosure(
        _ domains: inout Domains,
        in puzzle: SlitherlinkPuzzle
    ) -> Step {
        var parent = Array(0..<puzzle.dotCount)
        var definiteLines = 0
        for edge in 0..<puzzle.edgeCount where domains.isLine(edge) {
            definiteLines += 1
            let ends = puzzle.endpointsOfEdge[edge]
            union(&parent, ends.first, ends.second)
        }
        guard definiteLines > 0 else { return .unchanged }

        // Bileşen başına kaç çizgi var: kapanacak parçanın dışarıda çizgi bırakıp
        // bırakmadığını buradan okuyoruz.
        var linesInComponent = [Int: Int]()
        for edge in 0..<puzzle.edgeCount where domains.isLine(edge) {
            let root = find(&parent, puzzle.endpointsOfEdge[edge].first)
            linesInComponent[root, default: 0] += 1
        }

        var changed = false
        for edge in 0..<puzzle.edgeCount where domains.isUndecided(edge) {
            let ends = puzzle.endpointsOfEdge[edge]
            let rootA = find(&parent, ends.first)
            let rootB = find(&parent, ends.second)
            guard rootA == rootB else { continue }

            // İki uç aynı bileşende: bu kenar çizgi olursa o bileşen kapanıyor.
            let inside = linesInComponent[rootA] ?? 0
            guard inside < definiteLines else { continue }

            domains.forceCross(edge)
            changed = true
        }

        if domains.hasEmptyDomain { return .contradiction }
        return changed ? .changed : .unchanged
    }

    // MARK: - Birleştirme-bulma

    func find(_ parent: inout [Int], _ node: Int) -> Int {
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

    func union(_ parent: inout [Int], _ first: Int, _ second: Int) {
        let rootA = find(&parent, first)
        let rootB = find(&parent, second)
        if rootA != rootB {
            parent[max(rootA, rootB)] = min(rootA, rootB)
        }
    }
}
