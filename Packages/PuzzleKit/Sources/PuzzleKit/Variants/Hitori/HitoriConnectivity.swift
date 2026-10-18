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
        return changed ? .changed : .unchanged
    }

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
