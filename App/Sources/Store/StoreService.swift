import Foundation
import GameCore
import StoreKit

/// StoreKit 2 katmanı: ürünleri okuyor, satın almayı yürütüyor, yetkiyi izliyor.
///
/// Yetki kontrolünün **tek** yeri burası (brief b.8'in istediği). Kilitli özellikler
/// `PlayLimits`'e bakıyor, `PlayLimits`'in katmanını da yalnız bu sınıf yazıyor; ikinci
/// bir yetki kaynağı, iki yerin farklı cevap verdiği bir hata sınıfı açardı.
///
/// Makbuz doğrulaması yok, sunucu da yok: StoreKit 2 imzayı kendisi doğruluyor ve
/// `VerificationResult.verified` olmayan hiçbir işlem kabul edilmiyor. Sunucu tarafı
/// doğrulama, V1'in çevrimdışı olma kararıyla (b.5) birlikte gelmiyor.
@MainActor
@Observable
final class StoreService {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        /// Mağazaya ulaşılamadı. Uygulama çalışmaya devam ediyor; yalnız paywall
        /// ürünleri gösteremiyor.
        case failed(String)
    }

    enum PurchaseOutcome: Equatable {
        case purchased
        case cancelled
        /// Aile onayı bekleyen satın alma; sonucu `Transaction.updates` getiriyor.
        case pending
        case failed(String)
    }

    private(set) var state: LoadState = .idle
    private(set) var products: [Product] = []
    private(set) var tier: PlayerTier = .free
    private(set) var isWorking = false

    /// Katman değiştiğinde haber veriliyor; `PlayLimits` buna bağlanıyor.
    var onTierChange: ((PlayerTier) -> Void)?

    /// `Transaction.updates` dinleyicisi. Uygulama boyunca yaşıyor ve bilinçli olarak
    /// iptal edilmiyor: akış kapanırsa uygulama kapalıyken tamamlanan bir satın alma
    /// kaybolur.
    private var updates: Task<Void, Never>?

    /// Uygulama açılırken bir kez. Üç iş: işlem akışını dinlemeye başla, eldeki yetkiyi
    /// oku, ürünleri getir.
    ///
    /// Dinleme **ilk** iş: satın alma uygulama kapalıyken tamamlanmış olabilir
    /// (aile onayı, kesintili ağ) ve o işlem akıştan geliyor.
    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.apply(update)
            }
        }
        Task {
            await refreshEntitlement()
            await loadProducts()
        }
    }

    func loadProducts() async {
        state = .loading
        do {
            let found = try await Product.products(for: PlusProduct.allCases.map(\.rawValue))
            // Mağazadan dönen sıra garantili değil; ekrandaki sıra bizim kararımız.
            products = PlusProduct.displayOrder.compactMap { plus in
                found.first { $0.id == plus.rawValue }
            }
            state = .loaded
        } catch {
            products = []
            state = .failed(error.localizedDescription)
        }
    }

    /// Elde duran yetkiler; katmanı bu belirliyor.
    func refreshEntitlement() async {
        var owned: [String] = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = Self.verified(result), transaction.revocationDate == nil else {
                continue
            }
            // Süresi dolmuş abonelik `currentEntitlements`'ta görünmüyor ama yükseltme
            // sırasında eski işlem bir süre kalabiliyor; tarih kontrolü ucuz.
            if let expiry = transaction.expirationDate, expiry < Date() {
                continue
            }
            owned.append(transaction.productID)
        }
        setTier(PlusEntitlement.tier(forOwned: owned))
    }

    func purchase(_ product: Product) async -> PurchaseOutcome {
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard let transaction = Self.verified(result) else {
                    return .failed(localized("That purchase could not be verified."))
                }
                await transaction.finish()
                await refreshEntitlement()
                return .purchased
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(localized("That purchase could not be completed."))
            }
        } catch StoreKitError.userCancelled {
            return .cancelled
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Satın alma geri yükleme. Ayarlar ekranında bulunması Apple'ın kuralı (brief b.8).
    ///
    /// `AppStore.sync()` App Store kimliği soruyor; bu yüzden kendiliğinden değil yalnız
    /// oyuncu istediğinde çağrılıyor. Uygulama açılışındaki `refreshEntitlement` zaten
    /// cihazdaki yetkiyi okuyor, yani normal durumda geri yüklemeye gerek kalmıyor.
    @discardableResult
    func restore() async -> PurchaseOutcome {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            return tier == .plus ? .purchased : .failed(
                localized("No previous purchase was found on this Apple Account.")
            )
        } catch StoreKitError.userCancelled {
            // Oyuncu App Store girişini kapattı. Bu bir hata değil; uyarı göstermek
            // vazgeçmeyi başarısızlık gibi gösterirdi.
            return .cancelled
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func apply(_ result: VerificationResult<Transaction>) async {
        guard let transaction = Self.verified(result) else { return }
        await transaction.finish()
        await refreshEntitlement()
    }

    private func setTier(_ new: PlayerTier) {
        guard new != tier else { return }
        tier = new
        onTierChange?(new)
    }

    /// İmzası doğrulanmamış işlem kabul edilmiyor.
    private static func verified(_ result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction): transaction
        case .unverified: nil
        }
    }
}
