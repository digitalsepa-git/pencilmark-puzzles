/// Hitori'nin kural doğrulayıcısı.
public struct HitoriRules: PuzzleRules {
    public typealias Definition = HitoriPuzzle
    public typealias Board = HitoriBoard
    public typealias Move = HitoriMove

    public init() {}

    /// Hitori'de her hamle kurallara uygun.
    ///
    /// Hashi'nin tersi: orada kesişen köprü fiziksel imkânsızlıktı ve engellenmesi
    /// gerekiyordu. Burada iki komşu hücreyi karalamak mümkün, yalnız yanlış — oyuncunun
    /// deneyip görmesi oyunun kendisi. Bütün hatalar `violations` ile gösteriliyor.
    public func isLegal(_ move: HitoriMove, on board: HitoriBoard, in definition: HitoriPuzzle) -> Bool {
        guard definition.size.contains(move.position) else { return false }
        guard board[move.position] == move.previous else { return false }
        return move.next != move.previous
    }

    /// Kesin hatalar.
    ///
    /// Üç tür var ve ikisi her zaman kesin: komşu karalı hücreler, ve aynı grupta iki
    /// *işaretli* hücre (oyuncu ikisinin de beyaz kalacağını iddia etmiş). Üçüncüsü —
    /// gruptaki iki beyaz ve kopuk beyaz bölge — ancak tahta tamamlandığında kesin, çünkü
    /// karar verilmemiş bir hücre hâlâ karalanabilir.
    public func violations(on board: HitoriBoard, in definition: HitoriPuzzle) -> [Position] {
        var result: [Position] = []

        for cell in 0..<definition.cellCount {
            let position = definition.position(of: cell)
            guard board[position] == .shaded else { continue }
            for neighbor in definition.neighbors[cell]
            where board[definition.position(of: neighbor)] == .shaded {
                result.append(position)
                result.append(definition.position(of: neighbor))
            }
        }

        let complete = board.isComplete
        for group in definition.groups {
            let suspect = group.filter { cell in
                let state = board[definition.position(of: cell)]
                return state == .marked || (complete && state != .shaded)
            }
            guard suspect.count > 1 else { continue }
            result.append(contentsOf: suspect.map { definition.position(of: $0) })
        }

        if complete, result.isEmpty {
            // En büyük bölge "ana kara" sayılıyor, kopuk olan ondan küçük adacıklar.
            // Tersi — ilk bulunan bölgeyi ana kara saymak — köşede kalan tek beyaz hücre
            // yüzünden ızgaranın tamamını hatalı göstermeye yol açıyordu.
            let components = whiteRegions(on: board, in: definition).sorted { $0.count > $1.count }
            for island in components.dropFirst() {
                result.append(contentsOf: island.map { definition.position(of: $0) })
            }
        }

        return Array(Set(result)).sorted()
    }

    /// Üç şey birlikte: her grupta en fazla bir beyaz, komşu karalı yok, beyazlar tek bölgede.
    ///
    /// Karar verilmemiş hücre beyaz sayılıyor (bkz. `HitoriBoard.isWhite`): oyuncu yalnız
    /// karalayarak bitirebiliyor, her beyazı ayrıca işaretlemek zorunda değil.
    public func isSolved(_ board: HitoriBoard, in definition: HitoriPuzzle) -> Bool {
        guard !hasDuplicateWhite(board, in: definition) else { return false }
        guard !hasAdjacentShaded(board, in: definition) else { return false }
        let regions = whiteRegions(on: board, in: definition)
        return regions.count == 1
    }

    // MARK: - Yardımcılar

    public func hasDuplicateWhite(_ board: HitoriBoard, in definition: HitoriPuzzle) -> Bool {
        for group in definition.groups {
            var whites = 0
            for cell in group where board.isWhite(at: definition.position(of: cell)) {
                whites += 1
                if whites > 1 { return true }
            }
        }
        return false
    }

    public func hasAdjacentShaded(_ board: HitoriBoard, in definition: HitoriPuzzle) -> Bool {
        for cell in 0..<definition.cellCount
        where board[definition.position(of: cell)] == .shaded {
            for neighbor in definition.neighbors[cell]
            where board[definition.position(of: neighbor)] == .shaded {
                return true
            }
        }
        return false
    }

    /// Beyaz hücrelerin oluşturduğu bağlı bölgeler. Çözümde tek bölge olmak zorunda.
    public func whiteRegions(on board: HitoriBoard, in definition: HitoriPuzzle) -> [[Int]] {
        var seen = [Bool](repeating: false, count: definition.cellCount)
        var regions: [[Int]] = []

        for start in 0..<definition.cellCount
        where !seen[start] && board.isWhite(at: definition.position(of: start)) {
            var region: [Int] = []
            var stack = [start]
            seen[start] = true
            while let cell = stack.popLast() {
                region.append(cell)
                for neighbor in definition.neighbors[cell]
                where !seen[neighbor] && board.isWhite(at: definition.position(of: neighbor)) {
                    seen[neighbor] = true
                    stack.append(neighbor)
                }
            }
            regions.append(region)
        }
        return regions
    }
}
