import GameCore
import PuzzleKit
import SwiftData
import SwiftUI

/// Zorluk seçimi (brief b.7, ekran 2).
///
/// "Çözülen sayısı" henüz yok: istatistik kayıt katmanına bağlı ve o ayrı iş. Hard ve
/// Expert'in Plus'a kilitlenmesi de burada değil — paywall kuralları (brief b.8) StoreKit
/// işiyle birlikte gelecek.
struct DifficultyScreen: View {
    let variant: PuzzleVariantID

    @Environment(\.modelContext) private var modelContext
    @Environment(Preferences.self) private var preferences
    @State private var inProgress: Set<Difficulty> = []
    @State private var isShowingTutorial = false

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.cardSpacing) {
                Button {
                    isShowingTutorial = true
                } label: {
                    howToPlayRow
                }
                .buttonStyle(.plain)

                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    NavigationLink {
                        PuzzleScreen(variant: variant, difficulty: difficulty)
                    } label: {
                        row(difficulty)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Metrics.screenPadding)
        }
        .background(Color.paper)
        .task {
            inProgress =
                (try? GameStore(context: modelContext).difficultiesInProgress(variant: variant))
                ?? []
            // ADR 0009: ilk kez bir varyant açıldığında öğretici kendiliğinden başlıyor.
            if !preferences.hasSeenTutorial(variant) {
                isShowingTutorial = true
            }
        }
        .fullScreenCover(isPresented: $isShowingTutorial) {
            NavigationStack {
                TutorialScreen(variant: variant) {
                    preferences.markTutorialSeen(variant)
                    isShowingTutorial = false
                }
                .navigationTitle("How to play \(variant.displayName)")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationTitle(variant.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ difficulty: Difficulty) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(difficulty.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink)
                // Yarım kalan oyun zorluk başına saklanıyor: Easy'ye başlamak yarım
                // kalan Medium'u silmiyor (ADR 0018).
                if inProgress.contains(difficulty) {
                    Text("In progress")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.inkSoft)
        }
        .padding(Metrics.cardPadding)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(Color.rule, lineWidth: Metrics.hairline)
        )
    }
}

extension DifficultyScreen {
    /// ADR 0009: öğretici her zaman yeniden oynanabiliyor.
    private var howToPlayRow: some View {
        HStack {
            Text("How to play")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.ink)
            Spacer()
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Color.inkSoft)
        }
        .padding(Metrics.cardPadding)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(Color.rule, lineWidth: Metrics.hairline)
        )
    }
}
