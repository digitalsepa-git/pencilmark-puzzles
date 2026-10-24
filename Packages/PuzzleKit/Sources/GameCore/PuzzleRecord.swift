import PuzzleKit

/// Bitmiş bir bulmacanın kaydı. İstatistiğin tek kaynağı bu satırlar.
///
/// ADR 0008: veri her katmanda eksiksiz toplanıyor, kapı yalnızca gösterimde. Yani Plus'a
/// ait alanlar (tarih, tam süre, ipucu sayısı) ücretsiz kullanıcıda da kaydediliyor;
/// kullanıcı üçüncü ayında Plus alırsa ilk gününden beri biriken geçmişini görüyor.
public struct PuzzleRecord: Hashable, Sendable, Codable {
    public enum Kind: String, Hashable, Sendable, Codable {
        case free
        case daily
    }

    public let variant: PuzzleVariantID
    public let difficulty: Difficulty
    public let kind: Kind
    /// Bulmacanın bitirildiği yerel gün (ADR 0006: cihazın yerel takvim günü).
    public let day: CalendarDay
    public let seconds: Int
    public let hintCount: Int

    public init(
        variant: PuzzleVariantID,
        difficulty: Difficulty,
        kind: Kind,
        day: CalendarDay,
        seconds: Int,
        hintCount: Int
    ) {
        precondition(seconds >= 0, "Süre negatif olamaz")
        precondition(hintCount >= 0, "İpucu sayısı negatif olamaz")
        self.variant = variant
        self.difficulty = difficulty
        self.kind = kind
        self.day = day
        self.seconds = seconds
        self.hintCount = hintCount
    }

    /// Brief b.7: ipucu kullanılan bulmaca "çözüldü" sayılıyor ama ayrı işaretleniyor.
    public var usedHints: Bool { hintCount > 0 }
}
