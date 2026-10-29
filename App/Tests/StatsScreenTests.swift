import Testing
import SwiftUI
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("İstatistik ekranı")
@MainActor
struct StatsScreenTests {
    // Boş ekran ile dolu ekran farklı çiziliyor; "hiç bulmaca yok" hali sessizce dolu
    // ekranın boş hali olarak çıkmıyor.
    @Test("Boş ekran dolu ekrandan farklı")
    func emptyStateDiffersFromPopulated() throws {
        let size = CGSize(width: 320, height: 420)
        let empty = SnapshotHarness.render(
            StatsContent(summary: nil), size: size, colorScheme: .light
        )
        let populated = SnapshotHarness.render(
            StatsContent(summary: StatsFixtures.summary()), size: size, colorScheme: .light
        )

        let emptyImage = try #require(empty)
        let populatedImage = try #require(populated)
        // Oran 0 çıkarsa `ImageRenderer` içeriği hiç çizmemiş demektir ve referanslar
        // sessizce zemin rengine iner; bu testin asıl işi o sessiz hatayı yakalamak.
        #expect(SnapshotHarness.compare(emptyImage, populatedImage).ratio > 0.1)
    }

    @Test("Kaydı olmayan özet boş ekran gösteriyor")
    func summaryWithoutRecordsShowsEmptyState() throws {
        let size = CGSize(width: 320, height: 420)
        let nothing = SnapshotHarness.render(
            StatsContent(summary: nil), size: size, colorScheme: .light
        )
        let emptySummary = SnapshotHarness.render(
            StatsContent(summary: StatsSummary.summarise([], today: StatsFixtures.today)),
            size: size,
            colorScheme: .light
        )

        let a = try #require(nothing)
        let b = try #require(emptySummary)
        #expect(SnapshotHarness.compare(a, b).ratio == 0)
    }
}

/// İstatistik ekranının anlık görüntü sabitleri.
///
/// Kayıtlar elle kurulu: üreticiden ya da saklamadan gelseydi referanslar onların
/// değişimine bağlı olurdu (aynı gerekçe `SnapshotFixtures`'ta).
enum StatsFixtures {
    static let today = CalendarDay(year: 2026, month: 10, day: 24)

    static func summary() -> StatsSummary {
        StatsSummary.summarise(records(), today: today)
    }

    /// Eğilim kartı için: tek varyant ve zorlukta, yeterli sayıda ve giderek hızlanan
    /// çözümler. `records()` bunu veremiyor — orada her kovada en fazla iki çözüm var.
    static func trendRecords() -> [PuzzleRecord] {
        // Son çözüm en iyisi değil: gerçek bir seri düz inmiyor ve kart "Best" ile
        // "Latest"i aynı sayı göstermemeli.
        [320, 300, 290, 250, 198, 185, 210].enumerated().map { index, seconds in
            PuzzleRecord(
                variant: .kakuro,
                difficulty: .medium,
                kind: .free,
                day: today.advanced(by: -(14 - index * 2)),
                seconds: seconds,
                hintCount: 0
            )
        }
    }

    static func records() -> [PuzzleRecord] {
        func record(
            _ variant: PuzzleVariantID,
            _ difficulty: Difficulty,
            daysAgo: Int,
            seconds: Int,
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

        return [
            record(.kakuro, .easy, daysAgo: 0, seconds: 214),
            record(.kakuro, .easy, daysAgo: 1, seconds: 331),
            record(.kakuro, .medium, daysAgo: 1, seconds: 742, hints: 1),
            record(.kakuro, .hard, daysAgo: 2, seconds: 1_508),
            record(.calcudoku, .medium, daysAgo: 0, seconds: 405, kind: .daily),
            record(.calcudoku, .easy, daysAgo: 3, seconds: 160),
            record(.slitherlink, .medium, daysAgo: 2, seconds: 950, hints: 2),
            record(.hitori, .easy, daysAgo: 9, seconds: 288)
        ]
    }
}
