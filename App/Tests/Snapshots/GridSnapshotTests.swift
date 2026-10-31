import Testing
import SwiftUI
import PuzzleKit
import GameCore
@testable import Pencilmark

/// Brief b.11'in istediği anlık görüntü testleri: ızgara çizimi, karanlık mod, Dynamic Type.
///
/// Yalnız sabitlenmiş çalışma zamanında koşuyorlar (ADR 0016). Başka sürümde **atlanıyorlar**,
/// sessizce geçmiyorlar: piksel karşılaştırması çalışma zamanına bağlı ve 18.2'de üretilen
/// bir referans 18.6'da tutmuyor.
@Suite("Anlık görüntüler", .enabled(if: SnapshotHarness.isPinnedRuntime))
@MainActor
struct GridSnapshotTests {
    private let gridSize = CGSize(width: 320, height: 320)

    private func check(_ outcome: SnapshotHarness.Outcome) {
        switch outcome {
        case .matched, .recorded:
            break
        case .missingReference(let name):
            Issue.record("Referans yok: \(name). SNAPSHOT_RECORD=1 ile üretilmeli.")
        case .differed(let name, let ratio, let path):
            Issue.record("\(name) referanstan farklı (%\(ratio * 100)). Fark görüntüsü: \(path)")
        case .renderFailed:
            Issue.record("Çizim başarısız")
        }
    }

    private func snapshot(
        _ view: some View,
        _ name: String,
        size: CGSize? = nil,
        dynamicTypeSize: DynamicTypeSize = .large
    ) {
        for scheme in [ColorScheme.light, .dark] {
            let image = SnapshotHarness.render(
                view,
                size: size ?? gridSize,
                colorScheme: scheme,
                dynamicTypeSize: dynamicTypeSize
            )
            check(SnapshotHarness.verify(image, named: "\(name)-\(scheme == .light ? "light" : "dark")"))
        }
    }

    @Test("Kakuro ızgarası")
    func kakuroGrid() {
        let fixture = SnapshotFixtures.kakuro()
        snapshot(
            KakuroGridView(
                puzzle: fixture.puzzle,
                board: fixture.board,
                selection: Position(row: 2, column: 2),
                mistakes: [Position(row: 3, column: 3)]
            ),
            "kakuro"
        )
    }

    @Test("Calcudoku ızgarası")
    func calcudokuGrid() {
        let fixture = SnapshotFixtures.calcudoku()
        snapshot(
            CalcudokuGridView(
                puzzle: fixture.puzzle,
                board: fixture.board,
                selection: Position(row: 1, column: 1)
            ),
            "calcudoku"
        )
    }

    @Test("Hitori ızgarası")
    func hitoriGrid() {
        let fixture = SnapshotFixtures.hitori()
        snapshot(
            HitoriGridView(puzzle: fixture.puzzle, board: fixture.board),
            "hitori"
        )
    }

    @Test("Slitherlink ızgarası")
    func slitherlinkGrid() {
        let fixture = SnapshotFixtures.slitherlink()
        snapshot(
            SlitherlinkGridView(puzzle: fixture.puzzle, board: fixture.board),
            "slitherlink"
        )
    }

    @Test("Hashi ızgarası")
    func hashiGrid() {
        let fixture = SnapshotFixtures.hashi()
        snapshot(
            HashiGridView(puzzle: fixture.puzzle, board: fixture.board),
            "hashi"
        )
    }

    // Izgaradaki rakamlar Dynamic Type ile değil hücreyle büyüyor (ADR 0015 kapsamı
    // dışında, `GridStyle`'da gerekçesi var), bu yüzden Dynamic Type referansı ızgaranın
    // değil kartın: büyüyen şey orası.
    @Test("Varyant satırı")
    func variantCard() {
        snapshot(
            VariantRow(variant: .kakuro, isAnimated: false),
            "variant-row",
            size: CGSize(width: 320, height: 110)
        )
    }

    // Cümlenin görünürlüğü biçimine bağlı (#96): simge, mürekkep rengi ve cümle
    // hâlinde yazım. Gri ikincil metne geri dönerse referans tutmaz.
    @Test("Varyant bölümü notu")
    func variantSectionNote() {
        snapshot(
            VariantSectionNote(),
            "variant-note",
            size: CGSize(width: 320, height: 72)
        )
    }

    @Test("İstatistik ekranı — dolu")
    func statsScreenWithRecords() {
        snapshot(
            StatsContent(summary: StatsFixtures.summary()),
            "stats-filled",
            // İçeriğin tamamı sığacak kadar yüksek: yarısı kesilmiş bir referans,
            // kesilen yarıdaki regresyonu yakalayamaz.
            size: CGSize(width: 320, height: 820)
        )
    }

    @Test("İstatistik ekranı — boş")
    func statsScreenWithoutRecords() {
        snapshot(
            StatsContent(summary: nil),
            "stats-empty",
            size: CGSize(width: 320, height: 260)
        )
    }

    // Plus bölümleri kilitliyken de duruyor (ADR 0021 §5): referans, kilidin sessizce
    // bölümü gizlemeye dönüşmesini yakalıyor.
    @Test("Plus bölümü — kilitli")
    func plusStatsLocked() {
        snapshot(
            PlusStatsSection(
                isUnlocked: false,
                records: StatsFixtures.records(),
                today: StatsFixtures.today
            ) {},
            "plus-stats-locked",
            size: CGSize(width: 320, height: 300)
        )
    }

    // Açık hâl bir bütün olarak referanslanamıyor: satırları `NavigationLink` ve
    // `ImageRenderer` bir `NavigationStack`'i çizemiyor — sarı bir "desteklenmiyor"
    // işareti basıyor (`ScrollView`'u boş çizmesiyle aynı aile, ADR 0016'nın notu).
    // Bu yüzden görünümü belirleyen iki parça ayrı ayrı referanslanıyor.
    @Test("Plus satırı — açık ve kilitli")
    func plusRows() {
        snapshot(
            VStack(spacing: Metrics.cardSpacing) {
                PlusRow(title: "History", detail: "8 finished puzzles", isLocked: false)
                PlusRow(title: "Time trend", detail: "2 difficulties", isLocked: true)
            },
            "plus-rows",
            size: CGSize(width: 320, height: 180)
        )
    }

    @Test("Günlük bulmaca takvimi")
    func dailyCalendar() {
        snapshot(
            DailyCalendarCard(
                calendar: PlusStats.calendar(
                    of: StatsFixtures.records(),
                    year: StatsFixtures.today.year,
                    month: StatsFixtures.today.month,
                    today: StatsFixtures.today
                )
            ),
            "daily-calendar",
            size: CGSize(width: 320, height: 300)
        )
    }

    @Test("Eğilim kartı")
    func trendCard() throws {
        let trend = try #require(PlusStats.trends(from: StatsFixtures.trendRecords()).first)
        snapshot(TrendCard(trend: trend), "trend-card", size: CGSize(width: 320, height: 200))
    }

    // Kart bulmacayı ele vermiyor: varyant, tarih, süre ve ipucu işareti (brief b.7).
    // Referans, kartın içeriğinin sessizce genişlemesini de yakalıyor.
    @Test("Paylaşım kartı")
    func shareCard() {
        snapshot(
            ShareCard(
                variant: .kakuro,
                day: CalendarDay(year: 2026, month: 10, day: 24),
                seconds: 754,
                usedHints: false
            ),
            "share-card",
            size: CGSize(width: 320, height: 320)
        )
    }

    @Test("Günün satırı")
    func dailyCard() {
        snapshot(
            DailyRow(day: CalendarDay(year: 2026, month: 10, day: 24), isSolved: false),
            "daily-row",
            size: CGSize(width: 320, height: 120)
        )
    }

    // Öğretici ekranı (ADR 0009): adım sayacı, tek cümlelik anlatım ve ızgara.
    @Test("Öğretici ekranı")
    func tutorialScreen() {
        let scenario = TutorialScenarios.hitori()
        let run = TutorialRun(scenario: scenario)
        snapshot(
            TutorialChrome(
                stepNumber: 1,
                stepCount: scenario.steps.count,
                text: TutorialCopy.text(for: .hitori, step: 0),
                correction: nil,
                isFinished: false,
                onUndo: {},
                onSkip: {},
                onDone: {},
                grid: {
                    HitoriGridView(puzzle: scenario.definition, board: run.session.board)
                }
            ),
            "tutorial",
            size: CGSize(width: 320, height: 520)
        )
    }

    @Test("Varyant satırı — büyük Dynamic Type")
    func variantCardAtLargeDynamicType() {
        snapshot(
            VariantRow(variant: .calcudoku, isAnimated: false),
            "variant-row-xl",
            size: CGSize(width: 320, height: 220),
            dynamicTypeSize: .accessibility1
        )
    }
}
