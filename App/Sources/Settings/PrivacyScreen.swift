import SwiftUI

/// Gizlilik politikası, uygulamanın içinde.
///
/// Apple satın alma ekranından gizlilik politikasına erişilebilmesini istiyor (brief
/// b.8). Normalde bu bir web adresi olur; bu uygulamanın sunucusu yok ve bir alan adı
/// da henüz yok. Metni uygulamaya koymak hem bugün çalışıyor hem de çevrimdışı bir
/// uygulamaya daha uygun: politika "hiçbir veri toplanmıyor" diyorsa, onu okumak için
/// ağ gerekmemeli.
///
/// Metin `PrivacyInfo.xcprivacy` ile tutarlı olmak zorunda: orada izleme kapalı,
/// toplanan veri yok ve beyan edilen tek API `UserDefaults` (CA92.1).
struct PrivacyScreen: View {
    var onClose: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                section(
                    "What we collect",
                    """
                    Nothing. Pencilmark Puzzles has no accounts, no servers and no \
                    analytics. We cannot see what you play, how long you play or who \
                    you are.
                    """
                )
                section(
                    "What stays on your device",
                    """
                    Your solved puzzles, best times, streaks, unfinished games and \
                    settings are stored on this device only. Deleting the app deletes \
                    them.
                    """
                )
                section(
                    "Purchases",
                    """
                    Purchases are handled by Apple. We never see your payment details. \
                    The app only asks Apple whether a purchase is active on your Apple \
                    Account.
                    """
                )
                section(
                    "Tracking",
                    """
                    There is no tracking, no advertising identifier and no third-party \
                    SDK in this app.
                    """
                )
                section(
                    "Contact",
                    "Questions about this policy can be sent to the support address on our App Store page."
                )
            }
            .padding(Metrics.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.paper)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                }
            }
        }
    }

    private func section(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.ink)
            Text(body)
                .font(.body)
                .foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack { PrivacyScreen() }
}
