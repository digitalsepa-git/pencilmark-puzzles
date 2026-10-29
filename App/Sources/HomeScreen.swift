import GameCore
import PuzzleKit
import SwiftData
import SwiftUI

/// Ana ekran: günün bulmacası ve beş varyant (brief b.7, ekran 1).
///
/// Satırlar `List` içinde: disclosure göstergesi, ayırıcılar, basılı hâl ve dokunma
/// geri bildirimi sistemin kendisinden geliyor (ADR 0024). Daha önce elle çizilmiş
/// kartlardı ve üçü de taklit ediliyordu.
///
/// `NavigationStack` burada değil, sekme çubuğunda (`RootTabs`): ekranın kendisi bir
/// sekmenin köküymüş gibi davranıyor.
struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var today = LocalCalendar.today()
    @State private var dailySolved = false
    @State private var inProgress: Set<PuzzleVariantID> = []
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PuzzlePrefetcher.self) private var prefetcher

    var body: some View {
        List {
            Section {
                NavigationLink {
                    DailyPuzzleScreen(day: today)
                } label: {
                    DailyRow(day: today, isSolved: dailySolved)
                }
            }

            Section {
                ForEach(PuzzleVariantID.allCases, id: \.self) { variant in
                    NavigationLink {
                        DifficultyScreen(variant: variant)
                    } label: {
                        VariantRow(
                            variant: variant,
                            isInProgress: inProgress.contains(variant)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .navigationTitle("Puzzles")
        .task {
            refreshDaily()
            // Günün bulmacası ana ekranın ilk satırı; oyuncu ona dokunduğunda
            // üretim çoktan bitmiş oluyor.
            primeDaily()
        }
        .onChange(of: scenePhase) { _, phase in
            // Gece yarısını geçen bir oturum yeni günü görmeli; uygulama öne
            // geldiğinde gün yeniden okunuyor (ADR 0006: cihazın yerel günü).
            if phase == .active { refreshDaily() }
        }
    }
}

/// Varyant satırı. Yalnız içeriği çiziyor — gösterge, ayırıcı ve dokunma hâli `List`'in.
struct VariantRow: View {
    let variant: PuzzleVariantID
    /// Brief b.7: ana ekranda "yarım kalan oyun varsa devam et".
    var isInProgress = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(variant.displayName)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.ink)
            Text(isInProgress ? "Continue where you left off" : variant.tagline)
                .font(.subheadline)
                .foregroundStyle(isInProgress ? Color.ink : Color.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Brief b.7: geniş dokunma hedefleri. `List` satırı kendi asgarisini
        // içeriğinden alıyor, o yüzden asgari burada veriliyor.
        .frame(minHeight: Metrics.minimumTapTarget)
    }
}

/// Günün bulmaca satırı. Brief b.7: ana ekranda günlük bulmaca rozeti.
struct DailyRow: View {
    let day: CalendarDay
    let isSolved: Bool

    var body: some View {
        HStack(spacing: Metrics.cardPadding) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Puzzle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
                    .textCase(.uppercase)
                Text(DailyPuzzle.variant(on: day).displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text(ShareCard.longDate(day))
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSolved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(Color.ink)
                    .accessibilityLabel("Solved")
            }
        }
        .frame(minHeight: Metrics.minimumTapTarget)
    }
}

#Preview {
    NavigationStack { HomeScreen() }
}

extension HomeScreen {
    /// Günün varyantı tarihten geliyor (ADR 0006), yani hangi üreticinin
    /// çalıştırılacağı bugünden belli.
    private func primeDaily() {
        guard !dailySolved else { return }
        switch DailyPuzzle.variant(on: today) {
        case .kakuro: prefetcher.primeDaily(KakuroRuntime.self, on: today)
        case .calcudoku: prefetcher.primeDaily(CalcudokuRuntime.self, on: today)
        case .hitori: prefetcher.primeDaily(HitoriRuntime.self, on: today)
        case .slitherlink: prefetcher.primeDaily(SlitherlinkRuntime.self, on: today)
        case .hashi: prefetcher.primeDaily(HashiRuntime.self, on: today)
        }
    }

    private func refreshDaily() {
        today = LocalCalendar.today()
        dailySolved = (try? RecordStore(context: modelContext).hasSolvedDaily(on: today)) ?? false
        inProgress = (try? GameStore(context: modelContext).variantsInProgress()) ?? []
    }
}
