import Foundation
import StoreKit
import StoreKitTest
import Testing
import GameCore
@testable import Pencilmark

/// Mağaza katmanının testleri, `StoreKitTest`'in yerel oturumuyla.
///
/// `.storekit` dosyası şemadan da gösteriliyor (simülatörde elle denemek için) ama
/// buradaki oturum dosyayı doğrudan yoldan açıyor — anlık görüntü harness'ının
/// `#filePath` kullanmasıyla aynı yaklaşım. Böylece test, şemanın yapılandırmasına
/// bağlı kalmıyor.
///
/// Sınanan asıl şey ürün kimlikleri: koddaki kimlikle yapılandırmadaki kimlik
/// birbirini tutmazsa mağaza boş liste döner ve bu hata derlemede görünmez.
@Suite("Mağaza", .serialized)
@MainActor
struct StoreServiceTests {
    private static var configurationURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Pencilmark.storekit")
    }

    private func session() throws -> SKTestSession {
        let session = try SKTestSession(contentsOf: Self.configurationURL)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }

    @Test("Üç ürün mağazadan okunuyor")
    func productsLoad() async throws {
        let session = try session()
        defer { session.clearTransactions() }

        let store = StoreService()
        await store.loadProducts()

        #expect(store.state == .loaded)
        #expect(store.products.count == PlusProduct.allCases.count)
        // Ekrandaki sıra bizim kararımız, mağazanın döndürdüğü sıra değil.
        #expect(store.products.map(\.id) == PlusProduct.displayOrder.map(\.rawValue))
    }

    // Fiyat koda yazılmıyor (brief b.8); bu test fiyatın mağazadan geldiğini ve
    // biçimlendirilmiş hâlinin boş olmadığını kontrol ediyor.
    @Test("Fiyat mağazadan geliyor")
    func pricesComeFromTheStore() async throws {
        let session = try session()
        defer { session.clearTransactions() }

        let store = StoreService()
        await store.loadProducts()

        for product in store.products {
            #expect(!product.displayPrice.isEmpty)
        }
    }

    @Test("Satın alma katmanı Plus'a çeviriyor")
    func purchaseGrantsPlus() async throws {
        let session = try session()
        defer { session.clearTransactions() }

        let store = StoreService()
        var reported: PlayerTier?
        store.onTierChange = { reported = $0 }
        await store.loadProducts()

        let lifetime = try #require(
            store.products.first { $0.id == PlusProduct.lifetime.rawValue }
        )
        let outcome = await store.purchase(lifetime)

        #expect(outcome == .purchased)
        #expect(store.tier == .plus)
        #expect(reported == .plus)
    }

    @Test("Yetki temizlenince ücretsiz katmana dönüyor")
    func clearingEntitlementsFallsBackToFree() async throws {
        let session = try session()
        defer { session.clearTransactions() }

        let store = StoreService()
        await store.loadProducts()
        let lifetime = try #require(
            store.products.first { $0.id == PlusProduct.lifetime.rawValue }
        )
        _ = await store.purchase(lifetime)
        #expect(store.tier == .plus)

        session.clearTransactions()
        await store.refreshEntitlement()
        #expect(store.tier == .free)
    }

    // İade edilen satın almanın testi yok. `StoreService` iade edilmiş işlemi
    // `revocationDate` ile eliyor (StoreKit'in belgelediği sözleşme) ama
    // `StoreKitTest`'in `refundTransaction`'ı aynı süreçteki
    // `Transaction.currentEntitlements` çıktısına yansımıyor: işlem iadeden sonra da
    // `revocationDate = nil` ile dönüyor. Yanlış şeyi doğrulayan bir test yazmaktansa
    // bu yolu kapsamsız bırakmak dürüst.
}

@Suite("Ürün kimlikleri ve yetki kuralı")
struct PlusProductTests {
    // Kimlikler App Store Connect'te bire bir aynı olmak zorunda; biçim bozulursa
    // mağaza boş döner ve bu hata ancak çalışırken görünür.
    @Test("Kimlikler paket kimliğinin altında")
    func identifiersSitUnderTheBundleID() {
        for product in PlusProduct.allCases {
            #expect(product.rawValue.hasPrefix("com.pencilmarkgames.puzzles.plus."))
        }
        #expect(Set(PlusProduct.allCases.map(\.rawValue)).count == PlusProduct.allCases.count)
    }

    @Test("Sıralama bütün ürünleri kapsıyor")
    func theDisplayOrderCoversEveryProduct() {
        #expect(Set(PlusProduct.displayOrder) == Set(PlusProduct.allCases))
    }

    @Test("Abonelik ve tek seferlik ayrımı")
    func subscriptionsAreMarked() {
        #expect(PlusProduct.monthly.isSubscription)
        #expect(PlusProduct.yearly.isSubscription)
        #expect(!PlusProduct.lifetime.isSubscription)
    }

    @Test("Tanınan tek bir ürün bile Plus veriyor")
    func anyOwnedProductGrantsPlus() {
        #expect(PlusEntitlement.tier(forOwned: [PlusProduct.monthly.rawValue]) == .plus)
        #expect(PlusEntitlement.tier(forOwned: [PlusProduct.lifetime.rawValue]) == .plus)
        #expect(PlusEntitlement.tier(forOwned: [] as [String]) == .free)
        // Başka bir uygulamanın ya da eski bir sürümün kimliği yetki vermiyor.
        #expect(PlusEntitlement.tier(forOwned: ["com.example.other"]) == .free)
    }
}

@Suite("Paywall eşiği")
struct PaywallPolicyTests {
    @Test("Üç bulmacadan önce gösterilmiyor")
    func theWallWaitsForThreeSolvedPuzzles() {
        #expect(!PaywallPolicy.canShow(solvedPuzzles: 0))
        #expect(!PaywallPolicy.canShow(solvedPuzzles: 2))
        #expect(PaywallPolicy.canShow(solvedPuzzles: 3))
        #expect(PaywallPolicy.canShow(solvedPuzzles: 30))
    }

    @Test("Eşiğe kalan sayı")
    func remainingCountsDown() {
        #expect(PaywallPolicy.remainingBeforeShowing(solvedPuzzles: 0) == 3)
        #expect(PaywallPolicy.remainingBeforeShowing(solvedPuzzles: 2) == 1)
        #expect(PaywallPolicy.remainingBeforeShowing(solvedPuzzles: 5) == 0)
    }
}
