import GameCore
import PuzzleKit
import SwiftUI

/// Varyant ve zorluk başına süre eğilimi (ADR 0008, Plus).
struct TrendsScreen: View {
    let records: [PuzzleRecord]

    private var trends: [PlusStats.Trend] {
        // `PlusStats.trends` kayıtları eskiden yeniye bekliyor; saklama katmanı en
        // yeniyi önce veriyor.
        PlusStats.trends(from: records.reversed())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.cardSpacing) {
                if trends.isEmpty {
                    empty
                } else {
                    ForEach(trends) { trend in
                        TrendCard(trend: trend)
                    }
                }
            }
            .padding(Metrics.screenPadding)
        }
        .background(Color.paper)
        .navigationTitle("Time trend")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Yeterli örnek yoksa boş bir grafik çizmek yerine kaç çözüm gerektiği yazıyor.
    private var empty: some View {
        VStack(spacing: 12) {
            Text("Not enough solves yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.ink)
            Text(
                """
                Finish \(PlusStats.minimumTrendSamples) puzzles at the same difficulty \
                and the trend shows up here.
                """
            )
            .font(.subheadline)
            .foregroundStyle(Color.inkSoft)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }
}

struct TrendCard: View {
    let trend: PlusStats.Trend

    var body: some View {
        StatsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(trend.variant.displayName) · \(trend.difficulty.displayName)")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    // Çıplak bir sayı neyin sayısı olduğunu söylemiyor.
                    Text("\(trend.count) solves")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkSoft)
                }

                TrendSparkline(seconds: trend.seconds)
                    .frame(height: 64)

                HStack {
                    figure(String(localized: "Best"), PuzzleTimer.format(trend.best))
                    Spacer()
                    figure(String(localized: "Latest"), PuzzleTimer.format(trend.latest))
                    Spacer()
                    figure(changeCaption, changeValue)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func figure(_ caption: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.ink)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Color.inkSoft)
        }
    }

    /// Gelişim, ilk üç ve son üç çözümün ortalaması arasındaki fark. Tek tek süreler
    /// çok gürültülü: bir bulmaca diğerinden kolay çıkabiliyor.
    private var changeCaption: String {
        trend.improvementSeconds >= 0
            ? String(localized: "Faster")
            : String(localized: "Slower")
    }

    private var changeValue: String {
        PuzzleTimer.format(abs(trend.improvementSeconds))
    }

    private var accessibilityLabel: String {
        String(
            localized: """
            \(trend.variant.displayName) \(trend.difficulty.displayName): \
            \(trend.count) solves, best \(PuzzleTimer.format(trend.best)), \
            latest \(PuzzleTimer.format(trend.latest)), \
            \(changeCaption) by \(changeValue)
            """
        )
    }
}

/// Sürelerin küçük çizgi grafiği.
///
/// `Canvas`: nokta sayısı yüzlere çıkabiliyor ve her noktayı ayrı bir görünüm yapmak
/// ızgaralardakiyle aynı sorunu doğururdu (brief b.9).
struct TrendSparkline: View {
    let seconds: [Int]

    var body: some View {
        Canvas { context, size in
            guard seconds.count > 1 else { return }
            let lowest = seconds.min() ?? 0
            let highest = seconds.max() ?? 1
            let span = max(highest - lowest, 1)
            let step = size.width / CGFloat(seconds.count - 1)

            var line = Path()
            for (index, value) in seconds.enumerated() {
                let x = CGFloat(index) * step
                // Dikey eksen sürenin kendisi: altta kısa süre, üstte uzun. Düşen bir
                // çizgi hızlanma demek ve altındaki sayılar da süre olduğu için okuma
                // tutarlı kalıyor. Tersi (yukarı = iyi) daha "olumlu" görünüyordu ama
                // aynı kartta iki farklı yön okutuyordu.
                let ratio = CGFloat(value - lowest) / CGFloat(span)
                let y = (1 - ratio) * (size.height - 8) + 4
                if index == 0 {
                    line.move(to: CGPoint(x: x, y: y))
                } else {
                    line.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(line, with: .color(.ink), lineWidth: 2)

            // En iyi süre işaretli: grafiğin tek mutlak değeri o. En kısa süre en altta.
            if let bestIndex = seconds.firstIndex(of: lowest) {
                let x = CGFloat(bestIndex) * step
                let dot = CGRect(x: x - 3, y: size.height - 7, width: 6, height: 6)
                context.fill(Path(ellipseIn: dot), with: .color(.ink))
            }
        }
        .accessibilityHidden(true)
    }
}
