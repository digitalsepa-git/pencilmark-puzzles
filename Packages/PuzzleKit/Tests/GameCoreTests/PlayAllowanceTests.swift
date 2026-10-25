import Testing
import GameCore
import PuzzleKit

@Suite("Günlük kota")
struct DailyQuotaTests {
    private let today = CalendarDay(year: 2026, month: 10, day: 25)

    @Test("Aynı bulmacayı iki kez başlatmak bir hak harcıyor")
    func startingTheSamePuzzleTwiceCostsOne() {
        let quota = DailyQuota(day: today).starting(seed: 7).starting(seed: 7)
        #expect(quota.startedCount == 1)
    }

    @Test("Farklı bulmacalar ayrı sayılıyor")
    func differentPuzzlesCountSeparately() {
        let quota = DailyQuota(day: today).starting(seed: 7).starting(seed: 8)
        #expect(quota.startedCount == 2)
    }

    @Test("Gün değişince sayaç sıfırlanıyor")
    func counterResetsOnANewDay() {
        let yesterday = DailyQuota(day: today).starting(seed: 1).usingHint()
        let rolled = yesterday.rolledOver(to: CalendarDay(year: 2026, month: 10, day: 26))
        #expect(rolled.day == CalendarDay(year: 2026, month: 10, day: 26))
        #expect(rolled.startedCount == 0)
        #expect(rolled.hintsUsed == 0)
    }

    @Test("Aynı gün sayaç korunuyor")
    func counterSurvivesWithinTheDay() {
        let quota = DailyQuota(day: today).starting(seed: 1)
        #expect(quota.rolledOver(to: today) == quota)
    }

    // ADR 0007: saati geri almak kotayı yenilemiyor. Saklanan gün de geri gitmiyor,
    // yoksa kullanıcı dünkü güne dönüp ertesi gün yeniden sıfırlatabilirdi.
    @Test("Saati geri almak kotayı yenilemiyor")
    func movingTheClockBackwardsDoesNotRefill() {
        let quota = DailyQuota(day: today).starting(seed: 1).starting(seed: 2)
        let rolled = quota.rolledOver(to: CalendarDay(year: 2026, month: 10, day: 24))
        #expect(rolled == quota)
        #expect(rolled.day == today)
    }

    @Test("Ay ve yıl sınırında gün ilerliyor")
    func theDayAdvancesAcrossMonthAndYearBoundaries() {
        let yearEnd = DailyQuota(day: CalendarDay(year: 2026, month: 12, day: 31))
            .starting(seed: 1)
        let rolled = yearEnd.rolledOver(to: CalendarDay(year: 2027, month: 1, day: 1))
        #expect(rolled.startedCount == 0)
    }
}

@Suite("Oyun hakkı")
struct PlayAllowanceTests {
    private let today = CalendarDay(year: 2026, month: 10, day: 25)

    private func free(started: Int = 0, hints: Int = 0) -> PlayAllowance {
        var quota = DailyQuota(day: today, hintsUsed: hints)
        for seed in 0..<started {
            quota = quota.starting(seed: UInt64(seed))
        }
        return PlayAllowance(tier: .free, quota: quota)
    }

    private var plus: PlayAllowance {
        PlayAllowance(tier: .plus, quota: DailyQuota(day: today))
    }

    @Test("Ücretsiz katmanda Easy ve Medium açık, Hard ve Expert kilitli")
    func freeTierUnlocksTheFirstTwoDifficulties() {
        let allowance = free()
        #expect(allowance.isUnlocked(.easy))
        #expect(allowance.isUnlocked(.medium))
        #expect(!allowance.isUnlocked(.hard))
        #expect(!allowance.isUnlocked(.expert))
    }

    @Test("Plus'ta bütün zorluklar açık ve sınır yok")
    func plusUnlocksEverything() {
        for difficulty in Difficulty.allCases {
            #expect(plus.isUnlocked(difficulty))
        }
        #expect(plus.remainingPuzzles == nil)
        #expect(plus.remainingHints == nil)
        #expect(plus.canUseHint)
    }

    @Test("Üç bulmacadan sonra yeni bulmaca yok")
    func threePuzzlesExhaustTheDay() {
        #expect(free(started: 2).remainingPuzzles == 1)
        #expect(free(started: 2).canStart(.easy, kind: .free, isResuming: false))

        let spent = free(started: FreeTier.dailyPuzzleLimit)
        #expect(spent.remainingPuzzles == 0)
        #expect(!spent.canStart(.easy, kind: .free, isResuming: false))
    }

    @Test("Günlük bulmaca kotadan muaf")
    func theDailyPuzzleIsExempt() {
        let spent = free(started: FreeTier.dailyPuzzleLimit)
        // Günlük bulmacanın zorluğu Medium ve o ücretsiz katmanda açık.
        #expect(spent.canStart(.medium, kind: .daily, isResuming: false))
    }

    @Test("Yarım kalan bulmacaya dönmek hak harcamıyor")
    func resumingDoesNotNeedQuota() {
        let spent = free(started: FreeTier.dailyPuzzleLimit)
        #expect(spent.canStart(.easy, kind: .free, isResuming: true))
    }

    // Kilitli zorluk kotadan önce geliyor: hakkı olsa da Hard açılmıyor.
    @Test("Kilitli zorluk, hak varken de kapalı")
    func lockedDifficultyStaysLockedWithQuotaLeft() {
        #expect(!free().canStart(.hard, kind: .free, isResuming: false))
        #expect(!free().canStart(.hard, kind: .free, isResuming: true))
    }

    @Test("İpucu havuzu günde üç")
    func hintsAreLimitedToThree() {
        #expect(free(hints: 2).remainingHints == 1)
        #expect(free(hints: 2).canUseHint)
        #expect(free(hints: FreeTier.dailyHintLimit).remainingHints == 0)
        #expect(!free(hints: FreeTier.dailyHintLimit).canUseHint)
    }

    // Sayaç sınırı aşsa bile kalan negatif gösterilmemeli: arayüz bu sayıyı yazıyor.
    @Test("Kalan sayı negatife düşmüyor")
    func remainingNeverGoesNegative() {
        #expect(free(started: 9).remainingPuzzles == 0)
        #expect(free(hints: 9).remainingHints == 0)
    }
}
