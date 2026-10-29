import Testing
import GameCore
import PuzzleKit

@Suite("Plus geçmişi")
struct PlusHistoryTests {
    private func record(
        _ variant: PuzzleVariantID = .kakuro,
        day: Int,
        kind: PuzzleRecord.Kind = .free,
        seconds: Int = 60
    ) -> PuzzleRecord {
        PuzzleRecord(
            variant: variant,
            difficulty: .easy,
            kind: kind,
            day: CalendarDay(year: 2026, month: 10, day: day),
            seconds: seconds,
            hintCount: 0
        )
    }

    @Test("Kayıtlar güne göre gruplanıyor, en yeni gün başta")
    func recordsGroupByDayNewestFirst() {
        let history = PlusStats.history(from: [
            record(day: 5), record(day: 7), record(day: 5)
        ])
        #expect(history.map(\.day.day) == [7, 5])
        #expect(history[0].records.count == 1)
        #expect(history[1].records.count == 2)
    }

    // Gün içindeki sıra girdiden geliyor: `PuzzleRecord` saat taşımıyor ve saklama
    // katmanı satırları yazılma anına göre veriyor.
    @Test("Gün içinde girdinin sırası korunuyor")
    func withinADayTheInputOrderIsKept() {
        let history = PlusStats.history(from: [
            record(day: 5, seconds: 10), record(day: 5, seconds: 20)
        ])
        #expect(history[0].records.map(\.seconds) == [10, 20])
    }

    @Test("Boş geçmiş boş dönüyor")
    func emptyRecordsGiveEmptyHistory() {
        #expect(PlusStats.history(from: []).isEmpty)
    }

    @Test("Ay ve yıl sınırı doğru sıralanıyor")
    func daysSortAcrossMonths() {
        let december = PuzzleRecord(
            variant: .hashi, difficulty: .easy, kind: .free,
            day: CalendarDay(year: 2025, month: 12, day: 31), seconds: 30, hintCount: 0
        )
        let january = PuzzleRecord(
            variant: .hashi, difficulty: .easy, kind: .free,
            day: CalendarDay(year: 2026, month: 1, day: 1), seconds: 30, hintCount: 0
        )
        let history = PlusStats.history(from: [december, january])
        #expect(history.map(\.day) == [january.day, december.day])
    }
}

@Suite("Günlük bulmaca takvimi")
struct PlusCalendarTests {
    private let today = CalendarDay(year: 2026, month: 10, day: 25)

    private func daily(_ day: Int) -> PuzzleRecord {
        PuzzleRecord(
            variant: .kakuro, difficulty: .medium, kind: .daily,
            day: CalendarDay(year: 2026, month: 10, day: day), seconds: 90, hintCount: 0
        )
    }

    @Test("Hücre sayısı hizalama boşluklarıyla birlikte")
    func cellsIncludeTheLeadingBlanks() {
        let calendar = PlusStats.calendar(of: [], year: 2026, month: 10, today: today)
        // 1 Ekim 2026 perşembe: pazartesi tabanlı indekste 3 boş hücre.
        #expect(CalendarDay(year: 2026, month: 10, day: 1).weekday == .thursday)
        #expect(calendar.cells.prefix(3).allSatisfy { $0.day == nil })
        #expect(calendar.cells.count == 3 + 31)
    }

    @Test("Yalnız günlük bulmaca sayılıyor")
    func onlyDailyPuzzlesCount() {
        let free = PuzzleRecord(
            variant: .kakuro, difficulty: .easy, kind: .free,
            day: CalendarDay(year: 2026, month: 10, day: 4), seconds: 30, hintCount: 0
        )
        let calendar = PlusStats.calendar(
            of: [daily(3), free], year: 2026, month: 10, today: today
        )
        #expect(calendar.solvedCount == 1)
        #expect(calendar.cells.first { $0.day?.day == 3 }?.isSolved == true)
        #expect(calendar.cells.first { $0.day?.day == 4 }?.isSolved == false)
    }

    @Test("Bugün ve gelecek günler işaretli")
    func todayAndFutureAreMarked() {
        let calendar = PlusStats.calendar(of: [], year: 2026, month: 10, today: today)
        #expect(calendar.cells.first { $0.day?.day == 25 }?.isToday == true)
        #expect(calendar.cells.first { $0.day?.day == 26 }?.isFuture == true)
        #expect(calendar.cells.first { $0.day?.day == 24 }?.isFuture == false)
    }

    @Test("Geçen gün sayısı aya göre")
    func elapsedDaysFollowTheMonth() {
        let current = PlusStats.calendar(of: [], year: 2026, month: 10, today: today)
        #expect(current.elapsedDays == 25)

        let past = PlusStats.calendar(of: [], year: 2026, month: 9, today: today)
        #expect(past.elapsedDays == 30)

        let future = PlusStats.calendar(of: [], year: 2026, month: 11, today: today)
        #expect(future.elapsedDays == 0)
    }

    @Test("Başka ayın kaydı bu aya karışmıyor")
    func otherMonthsAreIgnored() {
        let september = PuzzleRecord(
            variant: .kakuro, difficulty: .medium, kind: .daily,
            day: CalendarDay(year: 2026, month: 9, day: 3), seconds: 90, hintCount: 0
        )
        let calendar = PlusStats.calendar(
            of: [september, daily(3)], year: 2026, month: 10, today: today
        )
        #expect(calendar.solvedCount == 1)
    }
}

@Suite("Süre eğilimi")
struct PlusTrendTests {
    private func record(
        _ variant: PuzzleVariantID = .kakuro,
        _ difficulty: Difficulty = .easy,
        day: Int,
        seconds: Int
    ) -> PuzzleRecord {
        PuzzleRecord(
            variant: variant, difficulty: difficulty, kind: .free,
            day: CalendarDay(year: 2026, month: 10, day: day),
            seconds: seconds, hintCount: 0
        )
    }

    @Test("Yetersiz örnek eğilim vermiyor")
    func tooFewSamplesGiveNoTrend() {
        let records = (1...PlusStats.minimumTrendSamples - 1).map {
            record(day: $0, seconds: 100)
        }
        #expect(PlusStats.trends(from: records).isEmpty)
    }

    @Test("Hızlanma pozitif çıkıyor")
    func gettingFasterIsPositive() throws {
        let times = [200, 190, 180, 120, 110, 100]
        let records = times.enumerated().map { record(day: $0.offset + 1, seconds: $0.element) }
        let trend = try #require(PlusStats.trends(from: records).first)

        #expect(trend.seconds == times)
        #expect(trend.earlyAverage == 190)
        #expect(trend.recentAverage == 110)
        #expect(trend.improvementSeconds == 80)
        #expect(trend.best == 100)
        #expect(trend.latest == 100)
    }

    @Test("Yavaşlama negatif çıkıyor")
    func gettingSlowerIsNegative() throws {
        let times = [100, 110, 120, 180, 190, 200]
        let records = times.enumerated().map { record(day: $0.offset + 1, seconds: $0.element) }
        let trend = try #require(PlusStats.trends(from: records).first)
        #expect(trend.improvementSeconds == -80)
    }

    // Kayıtlar karışık sırayla gelse de eğilim kronolojik olmalı; aksi halde "gelişim"
    // sayısı saklama katmanının sıralamasına göre değişirdi.
    @Test("Karışık sıradaki kayıtlar kronolojiye diziliyor")
    func recordsAreSortedChronologically() throws {
        let records = [
            record(day: 6, seconds: 100),
            record(day: 1, seconds: 200),
            record(day: 3, seconds: 150)
        ]
        let trend = try #require(
            PlusStats.trends(from: records + records.map {
                record(day: $0.day.day + 10, seconds: $0.seconds)
            }).first
        )
        #expect(trend.seconds.first == 200)
        #expect(trend.seconds.last == 100)
    }

    @Test("Varyant ve zorluk ayrı kovalarda")
    func variantsAndDifficultiesAreSeparate() {
        var records: [PuzzleRecord] = []
        for index in 1...PlusStats.minimumTrendSamples {
            records.append(record(.kakuro, .easy, day: index, seconds: 100))
            records.append(record(.kakuro, .hard, day: index, seconds: 300))
            records.append(record(.hashi, .easy, day: index, seconds: 50))
        }
        let trends = PlusStats.trends(from: records)
        #expect(trends.count == 3)
        // Sıra belirlenimci ve zorluk alfabetik değil kendi sırasında.
        #expect(trends.map(\.id) == ["kakuro-easy", "kakuro-hard", "hashi-easy"])
    }
}
