import PuzzleKit
import SwiftUI

/// Ana ekran: beş varyant kartı (brief b.7, ekran 1).
///
/// Günlük bulmaca rozeti ve "devam et" satırı henüz yok — ikisi de kayıt katmanına bağlı
/// ve o Faz 3'ün ayrı işi. Kartlar bu sürümde dokunmaya yanıt vermiyor; zorluk seçimi ve
/// bulmaca ekranı #37 ile geliyor.
struct HomeScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.cardSpacing) {
                    ForEach(PuzzleVariantID.allCases, id: \.self) { variant in
                        VariantCard(variant: variant)
                    }
                }
                .padding(Metrics.screenPadding)
            }
            .background(Color.paper)
            .navigationTitle("Puzzles")
        }
    }
}

struct VariantCard: View {
    let variant: PuzzleVariantID

    var body: some View {
        HStack(spacing: Metrics.cardPadding) {
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text(variant.tagline)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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

#Preview {
    HomeScreen()
}
