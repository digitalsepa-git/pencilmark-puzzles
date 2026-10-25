import Foundation
import Testing
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("Günlük kota saklaması")
@MainActor
struct PlayLimitsTests {
    /// Her testin kendi `UserDefaults` alanı; `.standard` paylaşılan ve testler
    /// birbirinin sayacını görürdü.
    private func defaults(_ name: String = UUID().uuidString) -> UserDefaults {
        UserDefaults(suiteName: name) ?? .standard
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components) ?? Date()
    }

    @Test("Varsayılan katman ücretsiz ve sayaç boş")
    func startsEmptyOnTheFreeTier() {
        let limits = PlayLimits(defaults: defaults())
        #expect(limits.tier == .free)
        #expect(limits.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit)
        #expect(limits.allowance.remainingHints == FreeTier.dailyHintLimit)
    }

    @Test("Başlatılan bulmaca saklanıyor ve yeni örnekte okunuyor")
    func startsSurviveARestart() {
        let store = defaults()
        let first = PlayLimits(defaults: store, now: date(2026, 10, 25))
        first.noteStart(seed: 42, kind: .free)
        first.noteHint()

        let second = PlayLimits(defaults: store, now: date(2026, 10, 25))
        #expect(second.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit - 1)
        #expect(second.allowance.remainingHints == FreeTier.dailyHintLimit - 1)
    }

    @Test("Aynı tohum ikinci kez hak harcamıyor")
    func theSameSeedIsChargedOnce() {
        let limits = PlayLimits(defaults: defaults())
        limits.noteStart(seed: 42, kind: .free)
        limits.noteStart(seed: 42, kind: .free)
        #expect(limits.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit - 1)
    }

    @Test("Günlük bulmaca hak harcamıyor")
    func theDailyPuzzleIsFree() {
        let limits = PlayLimits(defaults: defaults())
        limits.noteStart(seed: 7, kind: .daily)
        #expect(limits.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit)
    }

    @Test("Ertesi gün açılışta sayaç sıfırlanıyor")
    func theCounterResetsOnTheNextLaunch() {
        let store = defaults()
        let yesterday = PlayLimits(defaults: store, now: date(2026, 10, 25))
        yesterday.noteStart(seed: 1, kind: .free)
        yesterday.noteStart(seed: 2, kind: .free)

        let today = PlayLimits(defaults: store, now: date(2026, 10, 26))
        #expect(today.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit)
    }

    // Uygulama gece yarısını geçerek açık kalabiliyor; ana ekran öne gelince
    // `refresh` çağırıyor.
    @Test("Açık uygulamada gün dönünce sayaç yenileniyor")
    func refreshRollsTheDayOverWithoutARestart() {
        let limits = PlayLimits(defaults: defaults(), now: date(2026, 10, 25))
        limits.noteStart(seed: 1, kind: .free)
        #expect(limits.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit - 1)

        limits.refresh(now: date(2026, 10, 26))
        #expect(limits.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit)
    }

    @Test("Saat geri alınınca sayaç yenilenmiyor")
    func movingTheClockBackwardsKeepsTheCounter() {
        let limits = PlayLimits(defaults: defaults(), now: date(2026, 10, 25))
        limits.noteStart(seed: 1, kind: .free)

        limits.refresh(now: date(2026, 10, 24))
        #expect(limits.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit - 1)
    }

    @Test("Bozuk kayıt sayacı sıfırdan başlatıyor")
    func corruptStorageFallsBackToAFreshCounter() {
        let store = defaults()
        store.set(Data("bu JSON değil".utf8), forKey: "kota.gunluk")
        let limits = PlayLimits(defaults: store)
        #expect(limits.allowance.remainingPuzzles == FreeTier.dailyPuzzleLimit)
    }

    @Test("Plus katmanında sınır yok")
    func plusHasNoLimits() {
        let limits = PlayLimits(defaults: defaults(), tier: .plus)
        for seed in 0..<10 {
            limits.noteStart(seed: UInt64(seed), kind: .free)
        }
        #expect(limits.allowance.remainingPuzzles == nil)
        #expect(limits.allowance.canStart(.expert, kind: .free, isResuming: false))
    }

    @Test("Katman sonradan verilebiliyor")
    func theTierCanBeUpdatedLater() {
        let limits = PlayLimits(defaults: defaults())
        #expect(!limits.allowance.isUnlocked(.expert))
        limits.update(tier: .plus)
        #expect(limits.allowance.isUnlocked(.expert))
    }
}

@Suite("Zorluk satırının kilidi")
struct DifficultyRowLockTests {
    private let today = CalendarDay(year: 2026, month: 10, day: 25)

    private func allowance(tier: PlayerTier = .free, started: Int = 0) -> PlayAllowance {
        var quota = DailyQuota(day: today)
        for seed in 0..<started {
            quota = quota.starting(seed: UInt64(seed))
        }
        return PlayAllowance(tier: tier, quota: quota)
    }

    @Test("Hak varken Easy açık")
    func easyOpensWhileQuotaRemains() {
        #expect(
            DifficultyScreen.blockedReason(
                .easy, allowance: allowance(), isResuming: false
            ) == nil
        )
    }

    @Test("Hard kilidi kotadan önce geliyor")
    func theLockComesBeforeTheQuota() {
        #expect(
            DifficultyScreen.blockedReason(
                .hard, allowance: allowance(), isResuming: false
            ) == .lockedDifficulty
        )
        // Hak bitmiş olsa da sebep hâlâ kilit: oyuncuya yanlış açıklama gitmemeli.
        #expect(
            DifficultyScreen.blockedReason(
                .hard,
                allowance: allowance(started: FreeTier.dailyPuzzleLimit),
                isResuming: false
            ) == .lockedDifficulty
        )
    }

    @Test("Hak bitince Easy kota açıklamasına düşüyor")
    func exhaustedQuotaBlocksEasy() {
        #expect(
            DifficultyScreen.blockedReason(
                .easy,
                allowance: allowance(started: FreeTier.dailyPuzzleLimit),
                isResuming: false
            ) == .puzzleQuota
        )
    }

    @Test("Yarım kalan oyun hak bitse de açılıyor")
    func aStartedPuzzleStaysOpen() {
        #expect(
            DifficultyScreen.blockedReason(
                .easy,
                allowance: allowance(started: FreeTier.dailyPuzzleLimit),
                isResuming: true
            ) == nil
        )
    }

    @Test("Plus'ta hiçbir satır kilitli değil")
    func plusOpensEveryRow() {
        for difficulty in Difficulty.allCases {
            #expect(
                DifficultyScreen.blockedReason(
                    difficulty,
                    allowance: allowance(tier: .plus, started: 9),
                    isResuming: false
                ) == nil
            )
        }
    }

    @Test("Kalan hak cümlesi sayıya göre değişiyor")
    func theSummaryFollowsTheCount() {
        #expect(DifficultyScreen.remainingSummary(2).contains("2"))
        #expect(DifficultyScreen.remainingSummary(1).contains("1"))
        // Sıfırda sayı değil, günlük bulmacanın hâlâ ücretsiz olduğu yazıyor.
        #expect(DifficultyScreen.remainingSummary(0).contains("Daily"))
    }
}
