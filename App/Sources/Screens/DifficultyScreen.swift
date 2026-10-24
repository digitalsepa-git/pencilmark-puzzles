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
    @State private var inProgress: Set<Difficulty> = []

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.cardSpacing) {
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
