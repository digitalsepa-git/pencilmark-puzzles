// Hitori çözücüsünün bağlılık kuralları.
//
// Ayrı dosyada, Hashi'deki `HashiConnectivity` ile aynı gerekçeyle: beyaz bölgenin bağlı
// kalması kuralı hem en uzun parça hem de asıl eleme gücü. Yalnız komşuluk ve grup
// kısıtlarına bakan bir çözücü, beyazları ikiye ayıran dizilimleri geçerli sayardı.

extension HitoriSolver {
    /// Beyaz hücreler tek bölgede olmak zorunda. İki çıkarım buradan geliyor.
    func enforceConnectivity(_ domains: inout Domains, in puzzle: HitoriPuzzle) -> Step {
        let components = whiteComponents(of: domains, in: puzzle)

        // Kesinleşmiş beyaz yoksa bağlılık henüz bir şey söylemiyor: bütün hücreler
        // mümkün beyaz ve hangi bölgenin kalacağı belli değil.
        var componentsWithDefiniteWhite = Set<Int>()
        for cell in 0..<puzzle.cellCount where domains.isWhite(cell) {
            guard components[cell] >= 0 else { return .contradiction }
            componentsWithDefiniteWhite.insert(components[cell])
        }
        guard !componentsWithDefiniteWhite.isEmpty else { return .unchanged }

        // 1) Kesinleşmiş beyazlar mümkün beyazlar üzerinden birbirine ulaşamıyorsa çelişki.
        if componentsWithDefiniteWhite.count > 1 { return .contradiction }

        // 2) Kesinleşmiş beyaz içermeyen bir bölgenin tamamı karalı olmak zorunda: oradaki
        //    bir hücre beyaz kalsa, kesinleşmiş beyazlardan kopuk kalırdı.
        var changed = false
        guard let keeper = componentsWithDefiniteWhite.first else { return .unchanged }
        for cell in 0..<puzzle.cellCount
        where components[cell] >= 0 && components[cell] != keeper && domains.allowsWhite(cell) {
            domains.forceShaded(cell)
            changed = true
        }

        if domains.hasEmptyDomain { return .contradiction }
        if changed { return .changed }

        return enforceArticulation(&domains, in: puzzle, anchor: keeper, components: components)
    }

    /// Karalanması beyaz bölgeyi koparacak hücre beyaz kalmak zorunda.
    ///
    /// Hitori'nin asıl çalışan tekniği bu ve ilk sürümde eksikti: yalnız bölge düzeyindeki
    /// kurallar vardı, "şu hücreyi karalasam ayrılır" çıkarımı varsayım tekniğine kalıyordu.
    /// Sonucu ölçümde görüldü — üretilen her bulmaca ileri seviye çıkıyor, yani Easy, Medium
    /// ve Hard hiç üretilemiyordu (ADR 0011).
    ///
    /// Kesme noktaları tek geçişte bulunuyor (Tarjan). İlk uygulama her karar verilmemiş
    /// hücre için ayrı bir gezinme yapıyordu ve bu, Hard'da en kötü üretim süresini 280 ms'ye
    /// çıkarıyordu — bütçeye göre rahatsız edici bir pay. Tek geçiş o maliyeti hücre sayısının
    /// karesinden doğrusala indiriyor.
    private func enforceArticulation(
        _ domains: inout Domains,
        in puzzle: HitoriPuzzle,
        anchor: Int,
        components: [Int]
    ) -> Step {
        var totalAnchors = 0
        for cell in 0..<puzzle.cellCount where domains.isWhite(cell) {
            totalAnchors += 1
        }
        // Tek bir kesinleşmiş beyaz varsa "ayrılma" diye bir şey yok.
        guard totalAnchors > 1 else { return .unchanged }

        var search = ArticulationSearch(puzzle: puzzle, domains: domains, totalAnchors: totalAnchors)
        search.run(from: anchorRoot(anchor, components: components, in: puzzle))

        guard let cut = search.firstCut else { return .unchanged }
        domains.forceWhite(cut)
        return .changed
    }

    private func anchorRoot(_ anchor: Int, components: [Int], in puzzle: HitoriPuzzle) -> Int {
        for cell in 0..<puzzle.cellCount where components[cell] == anchor {
            return cell
        }
        return 0
    }
}

/// Mümkün beyaz hücrelerin grafiğinde kesme noktası arayan tek geçişli gezinme.
///
/// Klasik Tarjan kesme noktası algoritması, bir ekle: her alt ağaçta kaç *kesinleşmiş*
/// beyaz olduğunu da sayıyor. Bir hücre ancak ayırdığı parçanın ve geri kalanın ikisinde de
/// kesinleşmiş beyaz varsa beyaz kalmak zorunda — yoksa ayrılma zararsız olabilir.
private struct ArticulationSearch {
    let puzzle: HitoriPuzzle
    let domains: HitoriSolver.Domains
    let totalAnchors: Int

    var discovery: [Int]
    var low: [Int]
    var anchorsBelow: [Int]
    var counter = 0
    var firstCut: Int?

    init(puzzle: HitoriPuzzle, domains: HitoriSolver.Domains, totalAnchors: Int) {
        self.puzzle = puzzle
        self.domains = domains
        self.totalAnchors = totalAnchors
        self.discovery = [Int](repeating: -1, count: puzzle.cellCount)
        self.low = [Int](repeating: 0, count: puzzle.cellCount)
        self.anchorsBelow = [Int](repeating: 0, count: puzzle.cellCount)
    }

    mutating func run(from root: Int) {
        guard domains.allowsWhite(root) else { return }
        visit(root, parent: -1)
    }

    private mutating func visit(_ cell: Int, parent: Int) {
        discovery[cell] = counter
        low[cell] = counter
        counter += 1
        anchorsBelow[cell] = domains.isWhite(cell) ? 1 : 0

        for neighbor in puzzle.neighbors[cell]
        where neighbor != parent && domains.allowsWhite(neighbor) {
            if discovery[neighbor] < 0 {
                visit(neighbor, parent: cell)
                anchorsBelow[cell] += anchorsBelow[neighbor]
                low[cell] = min(low[cell], low[neighbor])

                // Alt ağaç geri bağlanmıyorsa bu hücre onu ayırıyor.
                guard firstCut == nil, low[neighbor] >= discovery[cell] else { continue }
                guard domains.isUndecided(cell) else { continue }
                let inside = anchorsBelow[neighbor]
                if inside > 0 && inside < totalAnchors {
                    firstCut = cell
                }
            } else {
                low[cell] = min(low[cell], discovery[neighbor])
            }
        }
    }
}

extension HitoriSolver {
    /// Mümkün beyaz hücrelerin oluşturduğu bölgeler. Karalı hücreler `-1`.
    private func whiteComponents(of domains: Domains, in puzzle: HitoriPuzzle) -> [Int] {
        var component = [Int](repeating: -1, count: puzzle.cellCount)
        var next = 0

        for start in 0..<puzzle.cellCount
        where component[start] < 0 && domains.allowsWhite(start) {
            var stack = [start]
            component[start] = next
            while let cell = stack.popLast() {
                for neighbor in puzzle.neighbors[cell]
                where component[neighbor] < 0 && domains.allowsWhite(neighbor) {
                    component[neighbor] = next
                    stack.append(neighbor)
                }
            }
            next += 1
        }
        return component
    }
}
