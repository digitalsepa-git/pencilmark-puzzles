import GameCore
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
    case plusStats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lockedDifficulty: localized("Hard and Expert need Plus")
        case .puzzleQuota: localized("That's today's free puzzles")
        case .hintQuota: localized("No hints left today")
        case .plusStats: localized("History needs Plus")
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
        case .plusStats:
            // ADR 0008: veri her katmanda toplanıyor, kapı yalnızca gösterimde.
            // Oyuncunun bunu bilmesi önemli — kaçırdığı şey geçmiş değil, geçmişi
            // görmek.
            String(
                localized: """
                Your times, dates and hints are already being saved. Pencilmark Plus \
                shows the full history, the Daily Puzzle calendar and how your times \
                change over time.
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

/// Sınıra çarpınca ne gösterileceğine karar veren kapı.
///
/// Brief b.8: "Paywall, kullanıcı en az 3 bulmaca bitirmeden gösterilmez." Kural
/// `PaywallPolicy`'de; burada yalnız uygulanıyor. Eşiğin altında bilgi ekranı, üstünde
/// teklif — ikisi de aynı dokunuşun cevabı, yani oyuncu için fazladan bir adım yok.
struct PlayLimitGate: View {
    let notice: PlayLimitNotice
    let solvedPuzzles: Int
    let store: StoreService
    let onDismiss: () -> Void

    var body: some View {
        if PaywallPolicy.canShow(solvedPuzzles: solvedPuzzles) {
            PaywallScreen(store: store, onClose: onDismiss)
        } else {
            PlayLimitSheet(notice: notice, onDismiss: onDismiss)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    PlayLimitSheet(notice: .puzzleQuota) {}
}
