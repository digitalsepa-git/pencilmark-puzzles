import GameCore
import PuzzleKit

/// Günlük bulmacanın kuralları (ADR 0006).
///
/// Üç şey burada ve üçü de ADR 0006'da karara bağlanmıştı: hangi gün hangi varyant,
/// zorluk, ve hangi algoritma sürümü.
enum DailyPuzzle {
    /// Sabit Medium: ücretsiz kullanıcı oynayabiliyor ve günlük bulmaca ücretsiz katmanın
    /// üç bulmaca kotasından sayılmıyor (ADR 0007).
    static let difficulty = Difficulty.medium

    /// Haftanın gününe sabit eşleme.
    ///
    /// Hafta sonu Kakuro ve Calcudoku'ya gidiyor: arama talebi en yüksek ikisi ve kalem
    /// işareti derinliği olan ikisi, hafta sonu oturumları da daha uzun. Sabit eşleme
    /// alışkanlık kuruyor — "perşembe Hashi günü".
    static func variant(on day: CalendarDay) -> PuzzleVariantID {
        switch day.weekday {
        case .monday, .saturday: .kakuro
        case .tuesday, .sunday: .calcudoku
        case .wednesday: .slitherlink
        case .thursday: .hashi
        case .friday: .hitori
        }
    }

    /// Verilen günün hangi algoritma sürümüyle üretileceği.
    ///
    /// Bugün tek bir sürüm var, yani eşleme sabit. İkinci sürüm geldiğinde buraya bir
    /// geçiş tarihi giriyor: o tarihten **önceki** günler eski sürümle üretilmeye devam
    /// ediyor (ADR 0006). Eşlemenin burada olmasının sebebi, motorun tarih bilmemesi.
    static func algorithmVersion(on day: CalendarDay) -> Int {
        Seed.algorithmVersion
    }

    static func seed(on day: CalendarDay) -> UInt64 {
        Seed.daily(
            variant: variant(on: day),
            year: day.year,
            month: day.month,
            day: day.day,
            version: algorithmVersion(on: day)
        )
    }
}
