import PuzzleKit
import SwiftUI

/// Zorluk seçimi (brief b.7, ekran 2).
///
/// "Çözülen sayısı" henüz yok: istatistik kayıt katmanına bağlı ve o ayrı iş. Hard ve
/// Expert'in Plus'a kilitlenmesi de burada değil — paywall kuralları (brief b.8) StoreKit
/// işiyle birlikte gelecek.
struct DifficultyScreen: View {
    let variant: PuzzleVariantID

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
        .navigationTitle(variant.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ difficulty: Difficulty) -> some View {
        HStack {
            Text(difficulty.displayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.ink)
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
