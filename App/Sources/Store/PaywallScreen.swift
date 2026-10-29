import GameCore
import StoreKit
import SwiftUI

/// Bağlantılar. Apple her ikisinin de satın alma ekranından erişilebilir olmasını
/// istiyor; eksikliği ret sebebi (brief b.8).
enum StoreLinks {
    /// Kendi kullanım koşullarımızı yazmadığımız sürece geçerli olan standart EULA.
    /// Apple bu bağlantıyı kabul ediyor ve App Store Connect'in varsayılanı da bu.
    static let termsOfUse = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )
}

/// Pencilmark Plus satın alma ekranı (brief b.8).
///
/// Ne zaman gösterildiğine bu ekran karar vermiyor: kural `PaywallPolicy`'de ve kapıyı
/// `PlayLimitSheet` tutuyor. Burada yalnız teklif var.
struct PaywallScreen: View {
    let store: StoreService
    let onClose: () -> Void

    @State private var message: String?
    @State private var isShowingPrivacy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    benefits
                    plans
                    restoreRow
                    legal
                }
                .padding(Metrics.screenPadding)
            }
            .background(Color.paper)
            .navigationTitle("Pencilmark Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: onClose)
                }
            }
            .sheet(isPresented: $isShowingPrivacy) {
                NavigationStack {
                    PrivacyScreen { isShowingPrivacy = false }
                }
            }
            .alert(
                message ?? "",
                isPresented: Binding(
                    get: { message != nil },
                    set: { if !$0 { message = nil } }
                )
            ) {
                Button("OK") { message = nil }
            }
        }
        .task { await store.loadProducts() }
    }

    private var header: some View {
        Text("Every puzzle, every difficulty, no daily limit.")
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var benefits: some View {
        // Yalnız bugün var olan şeyler yazıyor; olmayan bir şeyi satmak bu kitlede
        // yorumla geri döner.
        VStack(alignment: .leading, spacing: 8) {
            benefit("Unlimited puzzles every day")
            benefit("Hard and Expert unlocked")
            benefit("Unlimited hints")
            benefit("Full history, Daily Puzzle calendar and time trends")
        }
    }

    private func benefit(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.ink)
            Text(text)
                .font(.body)
                .foregroundStyle(Color.ink)
        }
    }

    @ViewBuilder
    private var plans: some View {
        switch store.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        case .failed:
            // Mağazaya ulaşılamadığında fiyat uydurulmuyor: brief b.8 fiyatın
            // mağazadan okunmasını istiyor ve yanlış fiyat göstermek geri dönülmez.
            VStack(alignment: .leading, spacing: 8) {
                Text("The Store is not reachable right now.")
                    .font(.body)
                    .foregroundStyle(Color.ink)
                Button("Try again") {
                    Task { await store.loadProducts() }
                }
                .buttonStyle(.bordered)
            }
        case .loaded where store.products.isEmpty:
            Text("No plans are available right now.")
                .font(.body)
                .foregroundStyle(Color.inkSoft)
        case .loaded:
            VStack(spacing: Metrics.cardSpacing) {
                ForEach(store.products, id: \.id) { product in
                    planRow(product)
                }
            }
        }
    }

    private func planRow(_ product: Product) -> some View {
        Button {
            buy(product)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(PlusProduct(productID: product.id)?.title ?? product.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink)
                    if let note = PlusProduct(productID: product.id)?.periodNote {
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(Color.inkSoft)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.ink)
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
        .buttonStyle(.plain)
        .disabled(store.isWorking)
    }

    private var restoreRow: some View {
        Button("Restore purchases") {
            Task {
                let outcome = await store.restore()
                report(outcome)
            }
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
        .disabled(store.isWorking)
    }

    private var legal: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                """
                Monthly and yearly plans renew automatically unless cancelled at least \
                24 hours before the period ends. Manage or cancel in your Apple Account \
                settings. The lifetime plan is a single purchase.
                """
            )
            .font(.footnote)
            .foregroundStyle(Color.inkSoft)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                if let terms = StoreLinks.termsOfUse {
                    Link("Terms of Use", destination: terms)
                        .font(.footnote)
                }
                Button("Privacy Policy") { isShowingPrivacy = true }
                    .font(.footnote)
            }
        }
    }

    private func buy(_ product: Product) {
        Task {
            let outcome = await store.purchase(product)
            if outcome == .purchased {
                onClose()
            } else {
                report(outcome)
            }
        }
    }

    private func report(_ outcome: StoreService.PurchaseOutcome) {
        switch outcome {
        case .purchased:
            message = String(localized: "Pencilmark Plus is active.")
        case .cancelled:
            break
        case .pending:
            message = String(
                localized: "This purchase needs approval. It will unlock once approved."
            )
        case .failed(let reason):
            message = reason
        }
    }
}
