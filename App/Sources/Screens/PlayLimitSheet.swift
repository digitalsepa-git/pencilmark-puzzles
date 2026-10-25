import SwiftUI

/// Kotanın dolduğunu ya da zorluğun kilitli olduğunu anlatan bilgi ekranı.
///
/// **Paywall değil.** Brief b.8: paywall kullanıcı en az üç bulmaca bitirmeden
/// gösterilmiyor ve "erken paywall bu kategoride silinme sebebi". Burada fiyat, satın
/// alma düğmesi ya da abonelik şartları yok; yalnız ne olduğu ve ne zaman geri geleceği
/// yazıyor. Paywall StoreKit işiyle gelecek (#61) ve kendi ekranı olacak.
enum PlayLimitNotice: String, Identifiable {
    case lockedDifficulty
    case puzzleQuota
    case hintQuota

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lockedDifficulty: String(localized: "Hard and Expert need Plus")
        case .puzzleQuota: String(localized: "That's today's free puzzles")
        case .hintQuota: String(localized: "No hints left today")
        }
    }

    var message: String {
        switch self {
        case .lockedDifficulty:
            String(
                localized: """
                Easy and Medium are always free. Pencilmark Plus opens Hard and Expert, \
                along with unlimited puzzles and hints.
                """
            )
        case .puzzleQuota:
            String(
                localized: """
                The free tier includes three new puzzles a day. Three more arrive \
                tomorrow, the Daily Puzzle is always free, and anything you have already \
                started is still there to finish.
                """
            )
        case .hintQuota:
            String(
                localized: """
                The free tier includes three hints a day, shared across every puzzle. \
                They come back tomorrow.
                """
            )
        }
    }
}

struct PlayLimitSheet: View {
    let notice: PlayLimitNotice
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(notice.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)

            Text(notice.message)
                .font(.body)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)

            Button("OK", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
        }
        .padding(Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
    }
}

#Preview {
    PlayLimitSheet(notice: .puzzleQuota) {}
}
