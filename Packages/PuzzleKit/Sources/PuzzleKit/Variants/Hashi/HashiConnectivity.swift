// Hashi çözücüsünün bağlılık kuralları.
//
// Ayrı dosyada, çünkü üç kural birlikte çözücünün en uzun parçası ve asıl eleme gücü
// burada: yalnız derecelere bakan bir çözücü benzersizlik iddiasını yanlış yapar.

extension HashiSolver {
    /// Bütün adalar tek ağda olmak zorunda. Üç ayrı çıkarım buradan geliyor ve üçü de
    /// ayrı yöntemde: tek bir fonksiyona sığdırmak hem okunmuyor hem de hangi kuralın
    /// ilerlettiğini ayıklamayı imkânsız kılıyordu.
    func enforceConnectivity(_ domains: inout Domains, in puzzle: HashiPuzzle) -> Step {
        guard puzzle.islandCount > 1 else { return .unchanged }

        if case .contradiction = enforcePossibleGraphConnected(domains, in: puzzle) {
            return .contradiction
        }

        switch enforceSingleExit(&domains, in: puzzle) {
        case .contradiction: return .contradiction
        case .changed: return .changed
        case .unchanged: break
        }

        return enforcePrematureClosure(&domains, in: puzzle)
    }

    /// Mümkün kenarlarla bile bütün adalar tek ağda olamıyorsa bulmaca çelişkili.
    private func enforcePossibleGraphConnected(
        _ domains: Domains,
        in puzzle: HashiPuzzle
    ) -> Step {
        let count = puzzle.islandCount
        var reachable = [Bool](repeating: false, count: count)
        reachable[0] = true
        var stack = [0]
        var seen = 1

        while let island = stack.popLast() {
            for edge in puzzle.incidentEdges[island] where domains.highest(edge) > 0 {
                let other = puzzle.otherIsland(of: edge, than: island)
                guard !reachable[other] else { continue }
                reachable[other] = true
                seen += 1
                stack.append(other)
            }
        }

        return seen < count ? .contradiction : .unchanged
    }

    /// Kesinleşmiş köprülerle oluşan bir bileşenin dışarıya tek çıkışı kaldıysa o kenarda
    /// köprü olmak zorunda; hiç çıkışı kalmadıysa çelişki.
    private func enforceSingleExit(_ domains: inout Domains, in puzzle: HashiPuzzle) -> Step {
        let count = puzzle.islandCount
        var parent = definiteComponents(of: domains, in: puzzle)

        var size = [Int](repeating: 0, count: count)
        for island in 0..<count {
            size[find(&parent, island)] += 1
        }

        var exits = [[Int]](repeating: [], count: count)
        for edge in puzzle.edges.indices where domains.highest(edge) > 0 {
            let rootA = find(&parent, puzzle.edges[edge].a)
            let rootB = find(&parent, puzzle.edges[edge].b)
            guard rootA != rootB else { continue }
            exits[rootA].append(edge)
            exits[rootB].append(edge)
        }

        var changed = false
        for root in 0..<count where find(&parent, root) == root && size[root] < count {
            if exits[root].isEmpty { return .contradiction }
            guard exits[root].count == 1 else { continue }
            let edge = exits[root][0]
            guard domains.allows(edge, 0) else { continue }
            domains.forbid(edge, 0)
            guard domains.bits[edge] != 0 else { return .contradiction }
            changed = true
        }

        return changed ? .changed : .unchanged
    }

    /// Erken kapanma: bir kenara köprü koymak, birleşen ada grubunu tamamen doyurup
    /// dışarıya kapatıyorsa o değer imkânsız — kapanan grup bütün adaları kapsamıyorsa
    /// ağ bir daha bağlanamaz.
    ///
    /// Klasik Hashi tekniklerinin genel hali. "Derecesi 1 olan iki ada birbirine
    /// bağlanamaz" ve "derecesi 2 olan iki ada çifte köprüyle bağlanamaz" kuralları bunun
    /// en küçük özel durumu; burada tek ada çifti yerine bileşenler için yazılı.
    private func enforcePrematureClosure(_ domains: inout Domains, in puzzle: HashiPuzzle) -> Step {
        let count = puzzle.islandCount
        var parent = definiteComponents(of: domains, in: puzzle)

        var definiteDegree = [Int](repeating: 0, count: count)
        for edge in puzzle.edges.indices {
            let low = domains.lowest(edge)
            guard low > 0 else { continue }
            definiteDegree[puzzle.edges[edge].a] += low
            definiteDegree[puzzle.edges[edge].b] += low
        }

        var members = [[Int]](repeating: [], count: count)
        for island in 0..<count {
            members[find(&parent, island)].append(island)
        }

        var changed = false
        for edge in puzzle.edges.indices {
            let first = puzzle.edges[edge].a
            let second = puzzle.edges[edge].b
            let rootA = find(&parent, first)
            let rootB = find(&parent, second)
            // Aynı bileşendeki kenar için kapanma sorusu anlamsız: grup zaten birleşik.
            guard rootA != rootB else { continue }
            guard members[rootA].count + members[rootB].count < count else { continue }

            for value in 1...2 where domains.allows(edge, value) {
                guard closesGroup(
                    members[rootA] + members[rootB],
                    adding: value,
                    to: (first, second),
                    definiteDegree: definiteDegree,
                    in: puzzle
                ) else { continue }
                domains.forbid(edge, value)
                guard domains.bits[edge] != 0 else { return .contradiction }
                changed = true
            }
        }

        return changed ? .changed : .unchanged
    }

    private func closesGroup(
        _ group: [Int],
        adding value: Int,
        to endpoints: (first: Int, second: Int),
        definiteDegree: [Int],
        in puzzle: HashiPuzzle
    ) -> Bool {
        for island in group {
            let extra = (island == endpoints.first || island == endpoints.second) ? value : 0
            if definiteDegree[island] + extra != puzzle.islands[island].required {
                return false
            }
        }
        return true
    }

    /// Kesinleşmiş köprülerin oluşturduğu bileşenler.
    private func definiteComponents(of domains: Domains, in puzzle: HashiPuzzle) -> [Int] {
        var parent = Array(0..<puzzle.islandCount)
        for edge in puzzle.edges.indices where domains.lowest(edge) > 0 {
            union(&parent, puzzle.edges[edge].a, puzzle.edges[edge].b)
        }
        return parent
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
