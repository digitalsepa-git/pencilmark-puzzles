import Testing
import Foundation
import SwiftData
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("Kayıt saklama")
@MainActor
struct RecordStoreTests {
    private func store() throws -> RecordStore {
        // Bellek içi kap: test diske yazmıyor ve her test temiz başlıyor.
        let container = try AppStorage.container(inMemory: true)
        return RecordStore(context: ModelContext(container))
    }

    private func record(
        _ variant: PuzzleVariantID = .kakuro,
        _ difficulty: Difficulty = .easy,
        day: CalendarDay = CalendarDay(year: 2026, month: 10, day: 24),
        seconds: Int = 120,
        hints: Int = 0,
        kind: PuzzleRecord.Kind = .free
    ) -> PuzzleRecord {
        PuzzleRecord(
            variant: variant,
            difficulty: difficulty,
            kind: kind,
            day: day,
            seconds: seconds,
            hintCount: hints
        )
    }

    @Test("Yazılan kayıt geri okunuyor")
    func recordsRoundTrip() throws {
        let store = try store()
        let written = record(.hashi, .hard, seconds: 455, hints: 2, kind: .daily)
        try store.add(written)

        let read = try store.allRecords()
        #expect(read == [written])
    }

    @Test("Boş saklamada kayıt yok")
    func emptyStoreHasNoRecords() throws {
        let store = try store()
        #expect(try store.allRecords().isEmpty)
        #expect(try !store.summary(today: CalendarDay(year: 2026, month: 10, day: 24)).hasRecords)
    }

    @Test("Özet saklanan kayıtlardan çıkıyor")
    func summaryComesFromStoredRecords() throws {
        let store = try store()
        let today = CalendarDay(year: 2026, month: 10, day: 24)
        try store.add(record(.kakuro, .easy, day: today, seconds: 300))
        try store.add(record(.kakuro, .easy, day: today, seconds: 180))
        try store.add(record(.hitori, .medium, day: today.advanced(by: -1), hints: 1))

        let summary = try store.summary(today: today)
        #expect(summary.totalSolved == 3)
        #expect(summary.stats(for: .kakuro).bestSeconds[.easy] == 180)
        #expect(summary.totalSolvedWithoutHints == 2)
        #expect(summary.currentStreak == 2)
    }

    // Günlük bulmaca ana ekranda "çözüldü" işaretlenecek; sorunun saklamadan tek satırla
    // cevaplanması gerekiyor, bütün kayıtları çekip taramadan.
    @Test("Günün günlük bulmacası çözüldü mü")
    func dailyCompletionIsQueryable() throws {
        let store = try store()
        let today = CalendarDay(year: 2026, month: 10, day: 24)

        #expect(try !store.hasSolvedDaily(on: today))

        try store.add(record(day: today, kind: .free))
        #expect(try !store.hasSolvedDaily(on: today), "Serbest oyun günlüğü çözmüş sayılmaz")

        try store.add(record(day: today, kind: .daily))
        #expect(try store.hasSolvedDaily(on: today))
        #expect(try !store.hasSolvedDaily(on: today.advanced(by: -1)))
    }

    // Enum'lar `rawValue` olarak saklanıyor; tanınmayan bir değer bütün istatistiği
    // çökertmemeli. Eski bir sürümün yazdığı, bu sürümde olmayan bir varyant olabilir.
    @Test("Tanınmayan satır özeti çökertmiyor")
    func unknownRowsAreSkipped() throws {
        let container = try AppStorage.container(inMemory: true)
        let context = ModelContext(container)
        let store = RecordStore(context: context)
        try store.add(record())

        let broken = StoredRecord(record: record(.hitori))
        broken.variantID = "boyle-bir-varyant-yok"
        context.insert(broken)
        try context.save()

        let read = try store.allRecords()
        #expect(read.count == 1)
        #expect(read.first?.variant == .kakuro)
    }

    @Test("Geçersiz tarih taşıyan satır atlanıyor")
    func rowsWithImpossibleDatesAreSkipped() throws {
        let container = try AppStorage.container(inMemory: true)
        let context = ModelContext(container)
        let store = RecordStore(context: context)

        let broken = StoredRecord(record: record())
        broken.month = 2
        broken.day = 30
        context.insert(broken)
        try context.save()

        #expect(try store.allRecords().isEmpty)
    }
}

@Suite("Yerel takvim")
struct LocalCalendarTests {
    // ADR 0006: gün, cihazın yerel takvim günü. Dönüşümün tek bir yeri olmak zorunda;
    // ikinci bir yer, günlük bulmacayla seri hesabının farklı günlerde çalışması demek.
    @Test("Tarih yerel takvim gününe çevriliyor")
    func datesBecomeLocalDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        let zone = try #require(TimeZone(identifier: "Europe/Istanbul"))
        calendar.timeZone = zone

        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 24
        components.hour = 23
        components.minute = 30
        components.timeZone = zone

        let date = try #require(calendar.date(from: components))
        let day = LocalCalendar.day(of: date, calendar: calendar)
        #expect(day == CalendarDay(year: 2026, month: 10, day: 24))
    }

    // Aynı an, farklı saat dilimi, farklı gün. ADR 0006 bunu bilerek kabul etti.
    @Test("Saat dilimi günü değiştirebiliyor")
    func timeZoneCanChangeTheDay() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 24
        components.hour = 23
        components.minute = 30
        components.timeZone = TimeZone(identifier: "Europe/Istanbul")

        var istanbul = Calendar(identifier: .gregorian)
        istanbul.timeZone = try #require(TimeZone(identifier: "Europe/Istanbul"))
        let date = try #require(istanbul.date(from: components))

        var london = Calendar(identifier: .gregorian)
        london.timeZone = try #require(TimeZone(identifier: "Europe/London"))

        #expect(LocalCalendar.day(of: date, calendar: istanbul)
            == CalendarDay(year: 2026, month: 10, day: 24))
        #expect(LocalCalendar.day(of: date, calendar: london)
            == CalendarDay(year: 2026, month: 10, day: 24))
    }
}

@Suite("Süre sayacı")
@MainActor
struct PuzzleTimerTests {
    @Test("Biçimlendirme")
    func formatting() {
        #expect(PuzzleTimer.format(0) == "0:00")
        #expect(PuzzleTimer.format(9) == "0:09")
        #expect(PuzzleTimer.format(65) == "1:05")
        #expect(PuzzleTimer.format(600) == "10:00")
        #expect(PuzzleTimer.format(3_661) == "1:01:01")
    }

    @Test("Başlamadan süre sıfır")
    func idleTimerIsZero() {
        let timer = PuzzleTimer()
        #expect(!timer.isRunning)
        #expect(timer.elapsed == 0)
    }

    @Test("Duraklatınca sayaç ilerlemiyor")
    func pausedTimerDoesNotAdvance() async throws {
        let timer = PuzzleTimer()
        timer.start()
        #expect(timer.isRunning)
        try await Task.sleep(for: .milliseconds(60))
        timer.pause()

        let afterPause = timer.elapsed
        #expect(afterPause > 0)
        try await Task.sleep(for: .milliseconds(60))
        #expect(timer.elapsed == afterPause)
    }

    @Test("Devam edince biriken süre korunuyor")
    func resumingKeepsAccumulatedTime() async throws {
        let timer = PuzzleTimer()
        timer.start()
        try await Task.sleep(for: .milliseconds(60))
        timer.pause()
        let afterFirst = timer.elapsed

        timer.start()
        try await Task.sleep(for: .milliseconds(60))
        #expect(timer.elapsed > afterFirst)
    }
}
