import PuzzleKit

/// İstatistik ekranının ücretsiz katmanda gösterdiği her şey (ADR 0008).
///
/// Kayıtlardan saf bir fonksiyonla türüyor: saklama katmanı ne olursa olsun hesap aynı ve
/// SwiftData açmadan test edilebiliyor.
public struct StatsSummary: Hashable, Sendable {
    public struct VariantStats: Hashable, Sendable {
        public var solved = 0
        public var solvedWithoutHints = 0
        public var solvedByDifficulty: [Difficulty: Int] = [:]
        /// Zorluk başına en iyi süre.
        ///
        /// ADR 0008 "varyant başına en iyi süre" diyor; zorluk kırılımı o kararın
        /// daraltılması değil genişletilmesi. Tek bir "en iyi süre" her zaman Easy'nin
        /// süresi olurdu ve Expert'i bitiren oyuncuya hiçbir şey söylemezdi.
        public var bestSeconds: [Difficulty: Int] = [:]

        public init() {}

        public var usedHintsAtLeastOnce: Bool { solved > solvedWithoutHints }
    }

    public let perVariant: [PuzzleVariantID: VariantStats]
    public let totalSolved: Int
    public let totalSolvedWithoutHints: Int
    /// Üst üste bulmaca çözülen gün sayısı; bugün ya da dün biten dizi.
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastPlayed: CalendarDay?

    public func stats(for variant: PuzzleVariantID) -> VariantStats {
        perVariant[variant] ?? VariantStats()
    }

    public var hasRecords: Bool { totalSolved > 0 }

    /// Kayıtlardan özet çıkarıyor.
    ///
    /// `today` dışarıdan geliyor: "bugün" kararı uygulama katmanının (ADR 0006) ve
    /// testlerin sabit bir bugüne ihtiyacı var.
    public static func summarise(
        _ records: [PuzzleRecord],
        today: CalendarDay
    ) -> StatsSummary {
        var perVariant: [PuzzleVariantID: VariantStats] = [:]
        var days = Set<Int>()

        for record in records {
            var stats = perVariant[record.variant] ?? VariantStats()
            stats.solved += 1
            if !record.usedHints {
                stats.solvedWithoutHints += 1
            }
            stats.solvedByDifficulty[record.difficulty, default: 0] += 1
            stats.bestSeconds[record.difficulty] = min(
                stats.bestSeconds[record.difficulty] ?? record.seconds,
                record.seconds
            )
            perVariant[record.variant] = stats
            days.insert(record.day.dayNumber)
        }

        let (current, longest) = streaks(of: days, today: today.dayNumber)
        return StatsSummary(
            perVariant: perVariant,
            totalSolved: records.count,
            totalSolvedWithoutHints: records.count { !$0.usedHints },
            currentStreak: current,
            longestStreak: longest,
            lastPlayed: days.max().map { CalendarDay(dayNumber: $0) }
        )
    }

    /// Seri, **herhangi** bir bulmaca çözülen üst üste günler.
    ///
    /// Yalnız günlük bulmacayı saymak daha paylaşılabilir bir sayı verirdi ama ücretsiz
    /// katmanda günde üç bulmaca oynayıp günlüğün varyantını sevmeyen oyuncunun serisi
    /// kırılırdı. Ödüllendirmek istediğimiz alışkanlık uygulamayı açmak.
    ///
    /// Bugün oynanmamışsa dün biten dizi hâlâ "güncel": oyuncu günü henüz kaybetmedi.
    private static func streaks(of days: Set<Int>, today: Int) -> (current: Int, longest: Int) {
        guard !days.isEmpty else { return (0, 0) }

        let sorted = days.sorted()
        var longest = 1
        var run = 1
        for index in 1..<sorted.count {
            run = sorted[index] == sorted[index - 1] + 1 ? run + 1 : 1
            longest = max(longest, run)
        }

        let anchor: Int
        if days.contains(today) {
            anchor = today
        } else if days.contains(today - 1) {
            anchor = today - 1
        } else {
            return (0, longest)
        }

        var current = 0
        var cursor = anchor
        while days.contains(cursor) {
            current += 1
            cursor -= 1
        }
        return (current, longest)
    }
}
