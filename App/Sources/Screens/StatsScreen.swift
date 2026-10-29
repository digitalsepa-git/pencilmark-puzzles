import Foundation
import GameCore
import PuzzleKit
import SwiftData
import SwiftUI

/// İstatistik ekranı (brief b.7, ekran 4).
///
/// Kapsam ADR 0008'de ikiye ayrılmış: ücretsiz katman toplamları ve güncel durumu
/// görüyor, Plus geçmişi, takvimi ve eğilimi. Plus bölümleri kilitliyken de duruyor
/// (ADR 0021 §5).
struct StatsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PlayLimits.self) private var limits
    @Environment(StoreService.self) private var store

    @State private var summary: StatsSummary?
    @State private var records: [PuzzleRecord] = []
    @State private var notice: PlayLimitNotice?
    @State private var today = LocalCalendar.today()

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.cardSpacing) {
                StatsContent(summary: summary)
                PlusStatsSection(
                    isUnlocked: limits.allowance.isUnlimited,
                    records: records,
                    today: today
                ) { notice = .plusStats }
                .padding(.horizontal, Metrics.screenPadding)
                .padding(.bottom, Metrics.screenPadding)
            }
        }
        .background(Color.paper)
        .navigationTitle("Statistics")
        .task { reload() }
        .sheet(item: $notice) { notice in
            PlayLimitGate(
                notice: notice,
                solvedPuzzles: records.count,
                store: store
            ) { self.notice = nil }
        }
    }

    private func reload() {
        today = LocalCalendar.today()
        let store = RecordStore(context: modelContext)
        summary = try? store.summary(today: today)
        records = (try? store.allRecords()) ?? []
    }
}

/// Ekranın yalnız çizen kısmı; ne saklamayı ne kaydırmayı biliyor.
///
/// Kaydırmanın dışarıda kalması anlık görüntü testi için şart: `ImageRenderer` bir
/// `ScrollView`'u boş çiziyor (içeriğin kendiliğinden bir boyu olmadığı için) ve referans
/// sessizce zemin rengine iniyor. İlk sürümde tam olarak bu oldu — dolu ekranın referansı
/// boş ekranınkiyle birebir aynı çıktı.
struct StatsContent: View {
    let summary: StatsSummary?

    var body: some View {
        if let summary, summary.hasRecords {
            VStack(spacing: Metrics.cardSpacing) {
                StreakCard(summary: summary)
                ForEach(PuzzleVariantID.allCases, id: \.self) { variant in
                    let stats = summary.stats(for: variant)
                    if stats.solved > 0 {
                        VariantStatsCard(variant: variant, stats: stats)
                    }
                }
            }
            .padding(Metrics.screenPadding)
        } else {
            EmptyStatsView()
                .padding(Metrics.screenPadding)
        }
    }
}

/// Hiç bulmaca çözülmemişken ekran boş kalmıyor.
///
/// Rakip analizinde (PR #10) "ilerleme sistemi yok" bir zayıflık olarak işaretlenmişti;
/// ilerleme ekranının boş bir sayfayla karşılaması o zayıflığın başka bir hali olurdu.
///
/// Boş durumun kendisi sistemin deseni: `ContentUnavailableView` (ADR 0024). Elle
/// kurulmuş hâli aynı yerleşimi taklit ediyordu.
struct EmptyStatsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No puzzles yet", systemImage: "chart.bar")
        } description: {
            Text("Finish a puzzle and your times, streak and totals will show up here.")
        }
    }
}

struct StreakCard: View {
    let summary: StatsSummary

    var body: some View {
        StatsCard {
            HStack(alignment: .top, spacing: 0) {
                figure("\(summary.currentStreak)", "Current streak")
                separator
                figure("\(summary.longestStreak)", "Longest streak")
                separator
                figure("\(summary.totalSolved)", "Solved")
            }
        }
    }

    /// `Divider` yerine sabit yükseklikli bir çizgi: `Divider` dikeyde esnek ve kart
    /// yükseklik veren bir kabın içindeyse ayırıcılar kartı gereksizce uzatıyor.
    private var separator: some View {
        Rectangle()
            .fill(Color.rule)
            .frame(width: Metrics.hairline, height: 48)
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.ink)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
                // Üç sütun dar; "Current streak" tek satıra sığmıyor ve sığmazsa
                // kırpılıyor. İki satıra sarması, kısaltılmış bir başlıktan iyi.
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VariantStatsCard: View {
    let variant: PuzzleVariantID
    let stats: StatsSummary.VariantStats

    var body: some View {
        StatsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(variant.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text("\(stats.solved) solved")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkSoft)
                }

                // Brief b.7: ipuçlu bulmaca çözüldü sayılıyor ama ayrı işaretleniyor.
                Text(hintSummary)
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)

                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    if let solved = stats.solvedByDifficulty[difficulty], solved > 0 {
                        row(difficulty, solved: solved, best: stats.bestSeconds[difficulty])
                    }
                }
            }
        }
    }

    private var hintSummary: String {
        let hinted = stats.solved - stats.solvedWithoutHints
        if hinted == 0 {
            return String(localized: "All solved without hints")
        }
        let clean = stats.solvedWithoutHints
        return String(localized: "\(clean) without hints · \(hinted) with hints")
    }

    private func row(_ difficulty: Difficulty, solved: Int, best: Int?) -> some View {
        HStack {
            Text(difficulty.displayName)
                .font(.subheadline)
                .foregroundStyle(Color.ink)
            Spacer()
            Text("\(solved)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.inkSoft)
            if let best {
                Text("best \(PuzzleTimer.format(best))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color.inkSoft)
                    .frame(minWidth: 90, alignment: .trailing)
            }
        }
    }
}

struct StatsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(Metrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                    .stroke(Color.rule, lineWidth: Metrics.hairline)
            )
    }
}
