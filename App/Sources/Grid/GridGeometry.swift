import CoreGraphics
import PuzzleKit

/// Izgaranın ekrandaki geometrisi: hücre dikdörtgenleri, nokta koordinatları ve dokunma
/// noktasından hücreye/kenara dönüş.
///
/// Çizimden ayrı duruyor ve `SwiftUI` bilmiyor. Sebebi test edilebilirlik: dokunma
/// eşlemesinin doğruluğu piksel karşılaştırmasıyla değil sayıyla sınanmalı — "şu noktaya
/// dokununca şu hücre seçilir" bir anlık görüntü testinin cevaplayabileceği soru değil.
///
/// Hücreler her zaman kare: dikdörtgen hücre, Kakuro'nun çapraz ipucu başlığını ve
/// Slitherlink'in noktalarını çirkinleştiriyor. Artan yer kenarlarda boşluk olarak kalıyor.
struct GridGeometry: Equatable {
    let rows: Int
    let columns: Int
    let origin: CGPoint
    let cellSide: CGFloat

    init(fitting size: GridSize, in rect: CGRect) {
        self.rows = max(size.rows, 1)
        self.columns = max(size.columns, 1)
        let side = min(rect.width / CGFloat(columns), rect.height / CGFloat(rows))
        self.cellSide = max(side, 0)
        let width = cellSide * CGFloat(columns)
        let height = cellSide * CGFloat(rows)
        self.origin = CGPoint(x: rect.midX - width / 2, y: rect.midY - height / 2)
    }

    var boardRect: CGRect {
        CGRect(
            origin: origin,
            size: CGSize(width: cellSide * CGFloat(columns), height: cellSide * CGFloat(rows))
        )
    }

    func rect(of position: Position) -> CGRect {
        CGRect(
            x: origin.x + CGFloat(position.column) * cellSide,
            y: origin.y + CGFloat(position.row) * cellSide,
            width: cellSide,
            height: cellSide
        )
    }

    func center(of position: Position) -> CGPoint {
        let rect = rect(of: position)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    /// Nokta ızgarası: hücre köşeleri. Slitherlink burada oynanıyor.
    func dot(row: Int, column: Int) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(column) * cellSide,
            y: origin.y + CGFloat(row) * cellSide
        )
    }

    func dot(at position: Position) -> CGPoint {
        dot(row: position.row, column: position.column)
    }

    /// Dokunulan hücre. Izgara dışına dokunulduysa `nil`.
    func cell(at point: CGPoint) -> Position? {
        guard cellSide > 0 else { return nil }
        let column = Int((point.x - origin.x) / cellSide)
        let row = Int((point.y - origin.y) / cellSide)
        guard point.x >= origin.x, point.y >= origin.y else { return nil }
        guard (0..<rows).contains(row), (0..<columns).contains(column) else { return nil }
        return Position(row: row, column: column)
    }

    /// Verilen doğru parçalarından dokunma noktasına en yakını.
    ///
    /// Kenar oynanan iki varyantta (Slitherlink, Hashi) dokunma hedefi ince bir çizgi;
    /// tam üstüne basmayı beklemek bu kitle için kullanılamaz bir arayüz olur. Bu yüzden
    /// eşleme "en yakın parça" ve `tolerance` kadar uzaklığa izin veriliyor.
    static func nearestSegment(
        to point: CGPoint,
        among segments: [(start: CGPoint, end: CGPoint)],
        tolerance: CGFloat
    ) -> Int? {
        var bestIndex: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for (index, segment) in segments.enumerated() {
            let candidate = distance(from: point, to: segment.start, segment.end)
            if candidate <= tolerance, candidate < bestDistance {
                bestDistance = candidate
                bestIndex = index
            }
        }
        return bestIndex
    }

    private static func distance(from point: CGPoint, to start: CGPoint, _ end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(point.x - start.x, point.y - start.y) }

        // Noktanın parça üzerindeki izdüşümü, 0...1 aralığına kırpılıyor: parçanın dışına
        // düşen izdüşüm en yakın uç noktaya çekiliyor.
        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        t = min(max(t, 0), 1)
        let projected = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        return hypot(point.x - projected.x, point.y - projected.y)
    }
}
