/// Hashi'nin kural doğrulayıcısı.
///
/// Üç soru üç ayrı yöntem (bkz. `PuzzleRules`): hamle anında giriş engelleme, kontrol
/// düğmesinde hata gösterme, bitişte tamamlanma.
public struct HashiRules: PuzzleRules {
    public typealias Definition = HashiPuzzle
    public typealias Board = HashiBoard
    public typealias Move = HashiMove

    public init() {}

    /// Hamle *kurallara uygun* mu — doğru olup olmadığını söylemiyor.
    ///
    /// Kesişen köprü burada engelleniyor, çünkü fiziksel imkânsızlık: iki köprü aynı hücreden
    /// geçemez, bu yanlış bir hamle değil olmayan bir hamle. Buna karşılık adaya gereğinden
    /// fazla köprü çekmek engellenmiyor — yanlış ama kurallara uygun, ve oyuncunun deneyip
    /// görmesi oyunun kendisi. O durum `violations` ile gösteriliyor.
    public func isLegal(_ move: HashiMove, on board: HashiBoard, in definition: HashiPuzzle) -> Bool {
        guard definition.edges.indices.contains(move.edge) else { return false }
        guard board[move.edge] == move.previous else { return false }
        guard move.next != move.previous else { return false }
        guard (0...definition.edges[move.edge].capacity).contains(move.next) else { return false }

        if move.next > 0 {
            for crossing in definition.crossingEdges[move.edge] where board[crossing] > 0 {
                return false
            }
        }
        return true
    }

    /// Kesin hatalar. Eksik köprü hata değil, tamamlanmamışlık.
    ///
    /// İki tür hata var: adaya gereğinden fazla köprü, ve bütün dereceler tutmasına rağmen
    /// ağın kopuk olması. İkincisi Hashi'de en sık yapılan hata — oyuncu kendi içinde kapanan
    /// bir ada grubu kuruyor ve nerede yanlış yaptığını göremiyor.
    public func violations(on board: HashiBoard, in definition: HashiPuzzle) -> [Position] {
        var result: [Position] = []

        for island in definition.islands.indices
        where board.degree(ofIsland: island, in: definition) > definition.islands[island].required {
            result.append(definition.islands[island].position)
        }

        for edge in definition.edges.indices where board[edge] > 0 {
            for crossing in definition.crossingEdges[edge] where board[crossing] > 0 {
                result.append(definition.islands[definition.edges[edge].a].position)
                result.append(definition.islands[definition.edges[edge].b].position)
            }
        }

        if result.isEmpty && degreesAreComplete(board, in: definition) {
            let reachable = reachableIslands(from: 0, on: board, in: definition)
            if reachable.count < definition.islandCount {
                for island in definition.islands.indices where !reachable.contains(island) {
                    result.append(definition.islands[island].position)
                }
            }
        }

        return Array(Set(result)).sorted()
    }

    /// Üç şey birlikte: bütün dereceler tam, kesişen köprü yok, bütün adalar tek ağda.
    public func isSolved(_ board: HashiBoard, in definition: HashiPuzzle) -> Bool {
        guard degreesAreComplete(board, in: definition) else { return false }
        guard !hasCrossing(board, in: definition) else { return false }
        return reachableIslands(from: 0, on: board, in: definition).count == definition.islandCount
    }

    // MARK: - Yardımcılar

    public func degreesAreComplete(_ board: HashiBoard, in definition: HashiPuzzle) -> Bool {
        for island in definition.islands.indices
        where board.degree(ofIsland: island, in: definition) != definition.islands[island].required {
            return false
        }
        return true
    }

    public func hasCrossing(_ board: HashiBoard, in definition: HashiPuzzle) -> Bool {
        for edge in definition.edges.indices where board[edge] > 0 {
            for crossing in definition.crossingEdges[edge] where board[crossing] > 0 {
                return true
            }
        }
        return false
    }

    /// Köprüsü çekilmiş kenarlar üzerinden gezilebilen adalar.
    public func reachableIslands(
        from start: Int,
        on board: HashiBoard,
        in definition: HashiPuzzle
    ) -> Set<Int> {
        var seen: Set<Int> = [start]
        var stack = [start]
        while let island = stack.popLast() {
            for edge in definition.incidentEdges[island] where board[edge] > 0 {
                let other = definition.otherIsland(of: edge, than: island)
                if seen.insert(other).inserted {
                    stack.append(other)
                }
            }
        }
        return seen
    }
}
