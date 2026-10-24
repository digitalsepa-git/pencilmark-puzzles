import GameCore
import PuzzleKit
import SwiftData
import SwiftUI

/// Ana ekran: beş varyant kartı (brief b.7, ekran 1).
///
/// Günlük bulmaca rozeti ve "devam et" satırı henüz yok — ikisi de kayıt katmanına bağlı
/// ve o Faz 3'ün ayrı işi.
///
struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var today = LocalCalendar.today()
    @State private var dailySolved = false
    @State private var inProgress: Set<PuzzleVariantID> = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.cardSpacing) {
                    NavigationLink {
                        DailyPuzzleScreen(day: today)
                    } label: {
                        DailyCard(day: today, isSolved: dailySolved)
                    }
                    .buttonStyle(.plain)

                    ForEach(PuzzleVariantID.allCases, id: \.self) { variant in
                        NavigationLink {
                            DifficultyScreen(variant: variant)
                        } label: {
                            VariantCard(
                                variant: variant,
                                isInProgress: inProgress.contains(variant)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Metrics.screenPadding)
            }
            .background(Color.paper)
            .navigationTitle("Puzzles")
            .task { refreshDaily() }
            .onChange(of: scenePhase) { _, phase in
                // Gece yarısını geçen bir oturum yeni günü görmeli; uygulama öne
                // geldiğinde gün yeniden okunuyor (ADR 0006: cihazın yerel günü).
                if phase == .active { refreshDaily() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        StatsScreen()
                    } label: {
                        Image(systemName: "chart.bar")
                            .foregroundStyle(Color.ink)
                    }
                    .accessibilityLabel("Statistics")
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsScreen()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.ink)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }
}

struct VariantCard: View {
    let variant: PuzzleVariantID
    var isAvailable = true
    /// Brief b.7: ana ekranda "yarım kalan oyun varsa devam et".
    var isInProgress = false

    var body: some View {
        HStack(spacing: Metrics.cardPadding) {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text(isInProgress ? "Continue where you left off" : variant.tagline)
                    .font(.subheadline)
                    .foregroundStyle(isInProgress ? Color.ink : Color.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isAvailable {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .padding(Metrics.cardPadding)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(Color.rule, lineWidth: Metrics.hairline)
        )
        .opacity(isAvailable ? 1 : 0.45)
    }
}

#Preview {
    HomeScreen()
}

extension HomeScreen {
    private func refreshDaily() {
        today = LocalCalendar.today()
        dailySolved = (try? RecordStore(context: modelContext).hasSolvedDaily(on: today)) ?? false
        inProgress = (try? GameStore(context: modelContext).variantsInProgress()) ?? []
    }
}

/// Günün bulmaca kartı. Brief b.7: ana ekranda günlük bulmaca rozeti.
struct DailyCard: View {
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
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text(ShareCard.longDate(day))
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: isSolved ? "checkmark.circle.fill" : "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(isSolved ? Color.ink : Color.inkSoft)
                .accessibilityLabel(isSolved ? "Solved" : "Not solved yet")
        }
        .padding(Metrics.cardPadding)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(Color.ink, lineWidth: Metrics.hairline * 2)
        )
    }
}
