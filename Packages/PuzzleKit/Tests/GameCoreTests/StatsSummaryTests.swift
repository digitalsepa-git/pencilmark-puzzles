import Testing
import PuzzleKit
import GameCore

@Suite("İstatistik özeti")
struct StatsSummaryTests {
    private let today = CalendarDay(year: 2026, month: 10, day: 24)

    private func record(
        _ variant: PuzzleVariantID = .kakuro,
        _ difficulty: Difficulty = .easy,
        daysAgo: Int = 0,
        seconds: Int = 100,
        hints: Int = 0,
        kind: PuzzleRecord.Kind = .free
    ) -> PuzzleRecord {
        PuzzleRecord(
            variant: variant,
            difficulty: difficulty,
            kind: kind,
            day: today.advanced(by: -daysAgo),
            seconds: seconds,
            hintCount: hints
        )
    }

    @Test("Kayıt yokken özet boş ama tanımlı")
    func emptySummary() {
        let summary = StatsSummary.summarise([], today: today)
        #expect(!summary.hasRecords)
        #expect(summary.totalSolved == 0)
        #expect(summary.currentStreak == 0)
        #expect(summary.longestStreak == 0)
        #expect(summary.lastPlayed == nil)
        #expect(summary.stats(for: .hashi).solved == 0)
    }

    @Test("Varyant ve zorluk kırılımı")
    func countsPerVariantAndDifficulty() {
        let summary = StatsSummary.summarise(
            [
                record(.kakuro, .easy),
                record(.kakuro, .easy),
                record(.kakuro, .hard),
                record(.hashi, .medium)
            ],
            today: today
        )

        #expect(summary.totalSolved == 4)
        let kakuro = summary.stats(for: .kakuro)
        #expect(kakuro.solved == 3)
        #expect(kakuro.solvedByDifficulty[.easy] == 2)
        #expect(kakuro.solvedByDifficulty[.hard] == 1)
        #expect(summary.stats(for: .hashi).solved == 1)
        #expect(summary.stats(for: .hitori).solved == 0)
    }

    @Test("En iyi süre zorluk başına ve en küçüğü")
    func bestTimeIsPerDifficultyAndMinimal() {
        let summary = StatsSummary.summarise(
            [
                record(.kakuro, .easy, seconds: 300),
                record(.kakuro, .easy, seconds: 120),
                record(.kakuro, .expert, seconds: 900)
            ],
            today: today
        )

        let kakuro = summary.stats(for: .kakuro)
        #expect(kakuro.bestSeconds[.easy] == 120)
        #expect(kakuro.bestSeconds[.expert] == 900)
        #expect(kakuro.bestSeconds[.medium] == nil)
    }

    // Brief b.7: ipuçlu bulmaca çözüldü sayılıyor ama ayrı işaretleniyor.
    @Test("İpuçlu çözüm sayılıyor ama ayrı işaretleniyor")
    func hintedSolvesAreCountedSeparately() {
        let summary = StatsSummary.summarise(
            [record(hints: 0), record(hints: 2), record(hints: 1)],
            today: today
        )

        #expect(summary.totalSolved == 3)
        #expect(summary.totalSolvedWithoutHints == 1)
        let kakuro = summary.stats(for: .kakuro)
        #expect(kakuro.solvedWithoutHints == 1)
        #expect(kakuro.usedHintsAtLeastOnce)
    }

    @Test("Bugün biten seri")
    func streakEndingToday() {
        let summary = StatsSummary.summarise(
            [record(daysAgo: 0), record(daysAgo: 1), record(daysAgo: 2)],
            today: today
        )
        #expect(summary.currentStreak == 3)
        #expect(summary.longestStreak == 3)
    }

    // Bugün oynanmamışsa oyuncu günü henüz kaybetmedi: dün biten dizi hâlâ güncel.
    @Test("Dün biten seri hâlâ güncel")
    func streakEndingYesterdayIsStillCurrent() {
        let summary = StatsSummary.summarise(
            [record(daysAgo: 1), record(daysAgo: 2)],
            today: today
        )
        #expect(summary.currentStreak == 2)
    }

    // Serinin yaşıyor olmasıyla günün kazanılmış olması aynı şey değil (#102): dün
    // biten dizi güncel sayılıyor ama bugün henüz sayılmadı. Ekran bu farkı söylüyor,
    // yani iki durumun ayrışması test edilmeli.
    @Test("Bugün sayıldı mı, seriden ayrı")
    func todayIsCountedOnlyWhenPlayed() {
        let unplayed = StatsSummary.summarise(
            [record(daysAgo: 1), record(daysAgo: 2)],
            today: today
        )
        #expect(unplayed.currentStreak == 2)
        #expect(!unplayed.isTodayCounted)

        let played = StatsSummary.summarise(
            [record(daysAgo: 0), record(daysAgo: 1)],
            today: today
        )
        #expect(played.isTodayCounted)

        #expect(!StatsSummary.summarise([], today: today).isTodayCounted)
    }

    @Test("İki gün atlanınca seri kırılıyor")
    func streakBreaksAfterTwoMissedDays() {
        let summary = StatsSummary.summarise(
            [record(daysAgo: 2), record(daysAgo: 3), record(daysAgo: 4)],
            today: today
        )
        #expect(summary.currentStreak == 0)
        #expect(summary.longestStreak == 3)
    }

    @Test("En uzun seri geçmişte kalabilir")
    func longestStreakCanBeInThePast() {
        let summary = StatsSummary.summarise(
            [
                record(daysAgo: 0),
                record(daysAgo: 10), record(daysAgo: 11),
                record(daysAgo: 12), record(daysAgo: 13)
            ],
            today: today
        )
        #expect(summary.currentStreak == 1)
        #expect(summary.longestStreak == 4)
    }

    @Test("Aynı günde iki bulmaca seriyi iki saymıyor")
    func twoPuzzlesInOneDayCountOnce() {
        let summary = StatsSummary.summarise(
            [record(daysAgo: 0), record(daysAgo: 0), record(daysAgo: 1)],
            today: today
        )
        #expect(summary.currentStreak == 2)
        #expect(summary.totalSolved == 3)
    }

    // Seri **herhangi** bir bulmacayı sayıyor, yalnız günlüğü değil.
    @Test("Serbest oyun da seriyi sürdürüyor")
    func freePlayKeepsTheStreakAlive() {
        let summary = StatsSummary.summarise(
            [record(daysAgo: 0, kind: .free), record(daysAgo: 1, kind: .daily)],
            today: today
        )
        #expect(summary.currentStreak == 2)
    }

    @Test("Son oynanan gün en yenisi")
    func lastPlayedIsTheMostRecent() {
        let summary = StatsSummary.summarise(
            [record(daysAgo: 5), record(daysAgo: 1), record(daysAgo: 9)],
            today: today
        )
        #expect(summary.lastPlayed == today.advanced(by: -1))
    }

    @Test("Yıl sınırını aşan seri")
    func streakAcrossYearBoundary() {
        let newYear = CalendarDay(year: 2027, month: 1, day: 1)
        let records = (0..<4).map { offset in
            PuzzleRecord(
                variant: .hitori,
                difficulty: .medium,
                kind: .daily,
                day: newYear.advanced(by: -offset),
                seconds: 60,
                hintCount: 0
            )
        }
        let summary = StatsSummary.summarise(records, today: newYear)
        #expect(summary.currentStreak == 4)
    }
}
