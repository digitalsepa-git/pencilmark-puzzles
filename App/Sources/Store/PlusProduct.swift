import Foundation
import GameCore

/// Pencilmark Plus'ın üç ürünü (brief b.8).
///
/// Kimlikler App Store Connect'tekiyle **bire bir** aynı olmak zorunda; yazım hatası
/// mağazadan boş ürün listesi dönmesi demek ve bu hata derlemede görünmüyor.
/// `PlusProductTests` kimlik biçimini bu yüzden sınıyor.
///
/// Fiyat burada yok: brief b.8 "fiyatlandırma kodda sabit değer olarak değil, App Store
/// Connect ürün kimlikleri üzerinden okunmalı" diyor. Ekranda görünen fiyat
/// `Product.displayPrice`, yani mağazanın verdiği yerelleştirilmiş değer.
enum PlusProduct: String, CaseIterable, Identifiable, Sendable {
    case monthly = "com.pencilmarkgames.puzzles.plus.monthly"
    case yearly = "com.pencilmarkgames.puzzles.plus.yearly"
    case lifetime = "com.pencilmarkgames.puzzles.plus.lifetime"

    var id: String { rawValue }

    /// Ekrandaki sıra: ömür boyu en altta çünkü en pahalı görünen ama bu kitlede en çok
    /// tercih edilmesi beklenen seçenek (brief b.8: "40 yaş üstü bulmaca oyuncusu
    /// aboneliğe dirençlidir").
    static let displayOrder: [PlusProduct] = [.monthly, .yearly, .lifetime]

    var title: String {
        switch self {
        case .monthly: String(localized: "Monthly")
        case .yearly: String(localized: "Yearly")
        case .lifetime: String(localized: "Lifetime")
        }
    }

    /// Abonelik mi, tek seferlik mi. Abonelik olanların otomatik yenileme açıklaması
    /// göstermesi Apple'ın kuralı.
    var isSubscription: Bool { self != .lifetime }

    var periodNote: String? {
        switch self {
        case .monthly: String(localized: "per month, renews automatically")
        case .yearly: String(localized: "per year, renews automatically")
        case .lifetime: String(localized: "one-time purchase")
        }
    }

    /// Mağazadan dönen kimliği tanıyor; tanımıyorsa `nil`.
    init?(productID: String) {
        self.init(rawValue: productID)
    }
}

/// Yetki kuralı: elde hangi ürünler varsa katman nedir.
///
/// Saf ve StoreKit'ten bağımsız — `Transaction` üretmek testte mümkün değil, ama
/// "şu kimlikler elimdeyse katman şu" kararı sınanabilir ve asıl yanlış olabilecek
/// kısım bu.
enum PlusEntitlement {
    static func tier(forOwned productIDs: some Collection<String>) -> PlayerTier {
        productIDs.contains(where: { PlusProduct(productID: $0) != nil }) ? .plus : .free
    }
}
