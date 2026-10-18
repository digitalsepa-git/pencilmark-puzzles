/// Rastgele Latin karesi: her satır ve her sütunda 1..n birer kez.
///
/// İki varyant kullanıyor. Calcudoku'da kuralın kendisi (brief b.6: "her satır ve sütunda
/// 1..n birer kez"), Hitori'de ise beyaz hücrelerin tekrarsızlığını kurulum gereği garanti
/// etmenin yolu. Ortak katmanda olmasının sebebi bu — iki ayrı kopya, ikisi de aynı tohumdan
/// farklı çıktı verme riski taşır.
public enum LatinSquare {
    /// Döngüsel kareyi satır, sütun ve sembol permütasyonlarıyla karıştırıyor.
    ///
    /// Bütün Latin karelerini eşit olasılıkla üretmiyor — döngüsel karenin izotopi
    /// sınıfıyla sınırlı. Bulmaca üretimi için yeterli: üstüne kafes bölüntüsü ya da
    /// karalama deseni geldiğinde çeşitlilik oradan geliyor. Düzgün dağılım isteyen bir
    /// ihtiyaç çıkarsa Jacobson-Matthews gerekir ve o ayrı bir karar olur.
    public static func random(side: Int, using rng: inout SeededGenerator) -> Grid<Int> {
        precondition(side > 0, "Kenar uzunluğu pozitif olmalı")

        var rowOrder = Array(0..<side)
        var columnOrder = Array(0..<side)
        var symbols = Array(1...side)
        rowOrder.shuffle(using: &rng)
        columnOrder.shuffle(using: &rng)
        symbols.shuffle(using: &rng)

        var grid = Grid(size: GridSize(square: side), repeating: 0)
        for row in 0..<side {
            for column in 0..<side {
                grid[row, column] = symbols[(rowOrder[row] + columnOrder[column]) % side]
            }
        }
        return grid
    }
}
