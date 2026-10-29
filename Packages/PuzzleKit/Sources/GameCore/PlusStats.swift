import PuzzleKit

/// Plus katmanının istatistikleri (ADR 0008): geçmiş, günlük bulmaca takvimi ve süre
/// eğilimi.
///
/// Üçü de kayıtlardan saf fonksiyonlarla türüyor — `StatsSummary` ile aynı gerekçe:
/// hesap SwiftData açmadan, Linux'ta sınanıyor; saklama tarafında sınanan şey yalnız
/// yazma ve okuma (ADR 0017 §1).
///
/// Veri her katmanda toplanıyor, kapı yalnızca gösterimde (ADR 0008). Bu yüzden
/// buradaki hiçbir fonksiyon katman sormuyor: ücretsiz oyuncunun kayıtları da aynı
/// şekilde hesaplanabilir ve Plus alındığı gün geçmiş eksiksiz görünür.
public enum PlusStats {}

// MARK: - Geçmiş

public extension PlusStats {
    /// Bir günün kayıtları; geçmiş listesi gün başlıklarıyla bölünüyor.
    struct HistoryDay: Hashable, Sendable, Identifiable {
        public let day: CalendarDay
        public let records: [PuzzleRecord]

        public var id: Int { day.dayNumber }
    }

    /// Kayıtları güne göre gruplayıp en yeniden eskiye sıralıyor.
    ///
    /// Gün içindeki sıra **girdinin sırası**: `PuzzleRecord` saat taşımıyor (ADR 0006:
    /// gün kararı yeterli) ve saklama katmanı satırları yazılma anına göre verebiliyor.
    /// Çağıran en yeniyi önce verirse gün içinde de en yeni önce görünüyor.
    static func history(from records: [PuzzleRecord]) -> [HistoryDay] {
        var byDay: [Int: [PuzzleRecord]] = [:]
        var order: [Int] = []
        for record in records {
            let key = record.day.dayNumber
            if byDay[key] == nil {
                order.append(key)
            }
            byDay[key, default: []].append(record)
        }
        return order
            .sorted(by: >)
            .map { HistoryDay(day: CalendarDay(dayNumber: $0), records: byDay[$0] ?? []) }
    }
}

// MARK: - Günlük bulmaca takvimi

public extension PlusStats {
    /// Bir ayın takvim ızgarası. Hücreler pazartesiyle başlayan haftalara hizalı.
    struct Calendar: Hashable, Sendable {
        public struct Cell: Hashable, Sendable, Identifiable {
            /// Ayın başındaki ve sonundaki hizalama boşlukları için `nil`.
            public let day: CalendarDay?
            public let isSolved: Bool
            public let isToday: Bool
            /// Gelecek günler soluk çiziliyor: çözülmemiş değil, henüz gelmemiş.
            public let isFuture: Bool
            public let index: Int

            public var id: Int { index }
        }

        public let year: Int
        public let month: Int
        public let cells: [Cell]
        public let solvedCount: Int
        /// Ayın bugüne kadar geçen gün sayısı; "8 / 29" gibi bir oran için.
        public let elapsedDays: Int
    }

    /// Verilen ayın günlük bulmaca takvimi.
    ///
    /// Yalnız `kind == .daily` kayıtlar sayılıyor: takvimin söylediği şey "o günün
    /// bulmacasını çözdün mü", serbest oyun değil.
    static func calendar(
        of records: [PuzzleRecord],
        year: Int,
        month: Int,
        today: CalendarDay
    ) -> Calendar {
        let solvedDays = Set(
            records.lazy
                .filter { $0.kind == .daily && $0.day.year == year && $0.day.month == month }
                .map(\.day.day)
        )
        let dayCount = CalendarDay.daysInMonth(year: year, month: month)
        let first = CalendarDay(year: year, month: month, day: 1)
        let leading = first.weekday.rawValue

        var cells: [Calendar.Cell] = []
        for index in 0..<leading {
            cells.append(
                Calendar.Cell(
                    day: nil, isSolved: false, isToday: false, isFuture: false, index: index
                )
            )
        }
        for dayOfMonth in 1...dayCount {
            let day = CalendarDay(year: year, month: month, day: dayOfMonth)
            cells.append(
                Calendar.Cell(
                    day: day,
                    isSolved: solvedDays.contains(dayOfMonth),
                    isToday: day == today,
                    isFuture: day > today,
                    index: cells.count
                )
            )
        }

        let elapsed: Int
        if today.year == year, today.month == month {
            elapsed = today.day
        } else {
            elapsed = CalendarDay(year: year, month: month, day: dayCount) < today ? dayCount : 0
        }

        return Calendar(
            year: year,
            month: month,
            cells: cells,
            solvedCount: solvedDays.count,
            elapsedDays: elapsed
        )
    }
}

// MARK: - Süre eğilimi

public extension PlusStats {
    /// Bir varyant ve zorluktaki sürelerin zaman içindeki gidişi.
    struct Trend: Hashable, Sendable, Identifiable {
        public let variant: PuzzleVariantID
        public let difficulty: Difficulty
        /// Eskiden yeniye süreler.
        public let seconds: [Int]

        public var id: String { "\(variant.rawValue)-\(difficulty.rawValue)" }

        public var count: Int { seconds.count }
        public var best: Int { seconds.min() ?? 0 }
        public var latest: Int { seconds.last ?? 0 }

        /// İlk ve son üç çözümün ortalaması. Tek tek süreler çok gürültülü — bir bulmaca
        /// diğerinden kolay çıkabiliyor — ama uçlardaki ortalama gidişi gösteriyor.
        public var earlyAverage: Int { Self.average(seconds.prefix(Self.window)) }
        public var recentAverage: Int { Self.average(seconds.suffix(Self.window)) }

        /// Pozitifse hızlanmış, negatifse yavaşlamış.
        public var improvementSeconds: Int { earlyAverage - recentAverage }

        static let window = 3

        private static func average(_ values: some Collection<Int>) -> Int {
            values.isEmpty ? 0 : values.reduce(0, +) / values.count
        }
    }

    /// Eğilimin anlamlı sayılması için gereken en az çözüm sayısı.
    ///
    /// Üç çözümle "gelişiyorsun" demek veri değil tahmin olurdu; altı, uçlardaki iki
    /// üçlünün çakışmadığı en küçük sayı.
    static var minimumTrendSamples: Int { Trend.window * 2 }

    /// Varyant ve zorluk başına eğilim; yalnız yeterli örneği olanlar.
    ///
    /// `records` **eskiden yeniye** verilmeli. Gün içindeki sıra girdiden geliyor;
    /// `PuzzleRecord` saat taşımıyor.
    static func trends(from records: [PuzzleRecord]) -> [Trend] {
        var buckets: [String: (variant: PuzzleVariantID, difficulty: Difficulty, times: [Int])] = [:]
        // Swift'in sıralaması kararlı değil; gün içindeki sıranın girdiden gelmesi için
        // sıra numarası ikinci anahtar olarak taşınıyor.
        let chronological = records.enumerated()
            .sorted { ($0.element.day.dayNumber, $0.offset) < ($1.element.day.dayNumber, $1.offset) }
            .map(\.element)
        for record in chronological {
            let key = "\(record.variant.rawValue)-\(record.difficulty.rawValue)"
            var bucket = buckets[key] ?? (record.variant, record.difficulty, [])
            bucket.times.append(record.seconds)
            buckets[key] = bucket
        }

        return buckets.values
            .filter { $0.times.count >= minimumTrendSamples }
            .map { Trend(variant: $0.variant, difficulty: $0.difficulty, seconds: $0.times) }
            // Sıra belirlenimci olmalı: sözlüğün sırası koşudan koşuya değişiyor.
            // Zorluk alfabetik değil kendi sırasıyla: Easy, Medium, Hard, Expert.
            .sorted { lhs, rhs in
                (Self.order(of: lhs.variant), Self.order(of: lhs.difficulty))
                    < (Self.order(of: rhs.variant), Self.order(of: rhs.difficulty))
            }
    }

    private static func order(of variant: PuzzleVariantID) -> Int {
        PuzzleVariantID.allCases.firstIndex(of: variant) ?? 0
    }

    private static func order(of difficulty: Difficulty) -> Int {
        Difficulty.allCases.firstIndex(of: difficulty) ?? 0
    }
}
