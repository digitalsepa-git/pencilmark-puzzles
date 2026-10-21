// Kakuro'nun siyah hücre deseni: kurulumu ve ölçütleri.
//
// Ayrı dosyada, çünkü desen tasarımı Kakuro'nun en zor parçası çıktı (ADR 0013) ve ölçütler
// — kesit uzunluğu kuralları ile kapalı 2×2 blok cezası — üreticinin geri kalanından
// bağımsız okunması gereken bir konu.

extension KakuroGenerator {
    /// Siyah hücre deseni: `true` ipucu hücresi.
    ///
    /// Üst satır ve sol sütun her zaman ipucu hücresi — toplamları onlar taşıyor. İç hücreler
    /// giriş olarak başlıyor ve geçerli hale gelene kadar siyahlanıyor.
    ///
    /// Geçerlilik tek bir koşul: her yatay ve dikey kesit 2-9 uzunluğunda. Tek hücreli kesit
    /// rakamı ipucunda açık ediyor, dokuzdan uzun kesit tekrarsız doldurulamıyor.
    public static func pattern(for layout: KakuroLayout, using rng: inout SeededGenerator) -> Grid<Bool>? {
        let size = GridSize(square: layout.side)
        var black = Grid(size: size, repeating: false)
        for index in 0..<layout.side {
            black[0, index] = true
            black[index, 0] = true
        }

        // Tek tek siyahlayıp kabul etmek işe yaramıyor: başlangıç durumu zaten geçersiz
        // (iç kesitler dokuzdan uzun) ve "geçerliyse kabul et" kuralı hiçbir hamleyi kabul
        // etmezdi. Bunun yerine ihlal miktarını ölçüp azaltan hamleleri kabul ediyoruz.
        var penalty = patternPenalty(black)
        var attempts = 0
        let limit = layout.side * layout.side * 60

        while penalty > 0 && attempts < limit {
            attempts += 1
            let row = Int.random(in: 1..<layout.side, using: &rng)
            let column = Int.random(in: 1..<layout.side, using: &rng)
            black[row, column].toggle()
            let candidate = patternPenalty(black)
            if candidate <= penalty {
                penalty = candidate
            } else {
                black[row, column].toggle()
            }
        }
        guard penalty == 0 else { return nil }

        addExtraBlackCells(&black, layout: layout, using: &rng)
        return black
    }

    /// Geçerliliği koruyarak fazladan siyah hücre ekliyor; kesitleri kısaltmanın yolu bu.
    private static func addExtraBlackCells(
        _ black: inout Grid<Bool>,
        layout: KakuroLayout,
        using rng: inout SeededGenerator
    ) {
        var candidates = (1..<layout.side).flatMap { row in
            (1..<layout.side).map { Position(row: row, column: $0) }
        }.filter { !black[$0] }
        candidates.shuffle(using: &rng)

        let target = candidates.count * layout.extraBlackPercent / 100
        var added = 0
        for position in candidates where added < target {
            black[position] = true
            if patternPenalty(black) == 0 {
                added += 1
            } else {
                black[position] = false
            }
        }
    }

    /// Desenin kural ihlali miktarı. Sıfır ise desen geçerli.
    ///
    /// Dışa açık: desen kurallarını ölçen tek yer burası ve Faz 3'teki öğreticide elle
    /// kurulmuş bulmacalar olacak (ADR 0009) — onların desenleri de bu kontrolden geçmeli.
    public static func violationPenalty(_ black: Grid<Bool>) -> Int {
        var penalty = 0
        for segment in segments(of: black) {
            if segment.count == 1 {
                penalty += 1
            } else if segment.count > 9 {
                penalty += segment.count - 9
            }
        }
        return penalty
    }

    /// Desenin benzersizliğe elverişliliği. Sıfır ise desende bilinen bir engel yok.
    ///
    /// Kural ihlallerinin üstüne **kapalı 2×2 blok** cezası ekliyor. ADR 0013'ün teşhisi:
    /// dört kesidi de 2 hücreli olan bir 2×2 blok, ızgaranın geri kalanından kopuk bir
    /// denklem sistemi oluşturuyor —
    ///
    ///     A B      A+B = S₁   C+D = S₂
    ///     C D      A+C = S₃   B+D = S₄
    ///
    /// — ve `S₁+S₂ = S₃+S₄` olduğu için dört denklem bağımsız değil. Dört bilinmeyene üç
    /// bağımsız denklem kalıyor, bir serbestlik derecesi açıkta. Onu kapatan tek şey 1-9
    /// aralığı, ve genellikle kapatmıyor.
    ///
    /// Blok "kapalı" demek: dört hücreye başka hiçbir kesit dokunmuyor, yani dört kesidin
    /// hepsi tam o iki hücreden oluşuyor. Blok daha uzun bir kesidin parçasıysa o kesit
    /// hücreleri ızgaranın geri kalanına bağlıyor ve serbestlik kalmıyor.
    public static func patternPenalty(_ black: Grid<Bool>) -> Int {
        violationPenalty(black) + closedBlockCount(black) * closedBlockWeight
    }

    /// Kapalı 2×2 blok cezasının ağırlığı.
    ///
    /// Kural ihlallerinden ağır: tek hücreli bir kesit bulmacayı bozuk yapar ama kapalı blok
    /// doğrudan çok çözümlülük üretiyor ve ölçümde tek engel buydu.
    static let closedBlockWeight = 4

    /// Desendeki kapalı 2×2 blok sayısı.
    public static func closedBlockCount(_ black: Grid<Bool>) -> Int {
        let size = black.size
        var count = 0

        for row in 0..<(size.rows - 1) {
            for column in 0..<(size.columns - 1) {
                let corners = [
                    Position(row: row, column: column),
                    Position(row: row, column: column + 1),
                    Position(row: row + 1, column: column),
                    Position(row: row + 1, column: column + 1)
                ]
                guard corners.allSatisfy({ black.element(at: $0) == false }) else { continue }

                // Dört kesidin de tam iki hücreli olması, bloğun dört bir yanının kapalı
                // olması demek: solunda, sağında, üstünde ve altında siyah hücre (ya da
                // ızgara kenarı) var.
                let closedLeft = isBlocked(black, row: row, column: column - 1)
                    && isBlocked(black, row: row + 1, column: column - 1)
                let closedRight = isBlocked(black, row: row, column: column + 2)
                    && isBlocked(black, row: row + 1, column: column + 2)
                let closedTop = isBlocked(black, row: row - 1, column: column)
                    && isBlocked(black, row: row - 1, column: column + 1)
                let closedBottom = isBlocked(black, row: row + 2, column: column)
                    && isBlocked(black, row: row + 2, column: column + 1)

                if closedLeft && closedRight && closedTop && closedBottom {
                    count += 1
                }
            }
        }
        return count
    }

    /// Hücre siyah mı ya da ızgara dışında mı — ikisi de kesidi orada bitiriyor.
    private static func isBlocked(_ black: Grid<Bool>, row: Int, column: Int) -> Bool {
        black.element(at: Position(row: row, column: column)) != false
    }

    /// Desendeki bütün yatay ve dikey kesitler (kesintisiz giriş hücresi dizileri).
    public static func segments(of black: Grid<Bool>) -> [[Int]] {
        let size = black.size
        var result: [[Int]] = []

        for row in 0..<size.rows {
            var current: [Int] = []
            for column in 0..<size.columns {
                if black[row, column] {
                    if !current.isEmpty { result.append(current) }
                    current = []
                } else {
                    current.append(row * size.columns + column)
                }
            }
            if !current.isEmpty { result.append(current) }
        }

        for column in 0..<size.columns {
            var current: [Int] = []
            for row in 0..<size.rows {
                if black[row, column] {
                    if !current.isEmpty { result.append(current) }
                    current = []
                } else {
                    current.append(row * size.columns + column)
                }
            }
            if !current.isEmpty { result.append(current) }
        }

        return result
    }
}
