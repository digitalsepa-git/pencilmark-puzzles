import Foundation
import os

/// Uygulamanın dili (ADR 0026).
///
/// Varsayılan `sistem`: uygulama cihazın dilinde açılıyor. Kullanıcı bir dil seçerse
/// uygulama o dilde çalışıyor, cihaz ayarına dokunmadan.
enum AppLanguage: Hashable, Identifiable, Sendable {
    /// Cihazın dili. iOS, uygulamanın desteklediği diller arasından kendisi seçiyor.
    case system
    /// Kullanıcının seçtiği dil; `en`, `tr` gibi bir kod.
    case fixed(String)

    var id: String {
        switch self {
        case .system: "system"
        case .fixed(let code): code
        }
    }

    /// Pakette gerçekten bulunan diller. Liste kodda sabit **değil**: üçüncü bir dil
    /// eklemek yalnız çeviri işi olsun diye paketin kendisinden okunuyor.
    static var available: [AppLanguage] {
        let codes = Bundle.main.localizations
            .filter { $0 != "Base" }
            .sorted()
        return [.system] + codes.map(AppLanguage.fixed)
    }

    /// Dilin kendi dilindeki adı: "English", "Türkçe". Seçim ekranında bir dili kendi
    /// adıyla göstermek, o dili arayan birinin bulabileceği tek biçim.
    var displayName: String {
        switch self {
        case .system:
            return localized("System")
        case .fixed(let code):
            let locale = Locale(identifier: code)
            let name = locale.localizedString(forLanguageCode: code) ?? code
            // Dilin kendi büyük harf kuralı: Türkçede "i" → "İ".
            return name.prefix(1).uppercased(with: locale) + name.dropFirst()
        }
    }

    // MARK: - Seçilen dilin çözülmüş hâli

    /// Metinlerin okunduğu paket. Seçim `sistem` ise uygulamanın kendi paketi, yani
    /// iOS'un çözümü; bir dil seçiliyse o dilin `.lproj` paketi.
    static var currentBundle: Bundle { state.withLock(\.bundle) }

    /// Tarih ve sayı biçimlendirmesinin kullandığı `Locale`.
    static var currentLocale: Locale { state.withLock(\.locale) }

    /// Bu dilin paketi. Görünüm ağacına verilen değer buradan geliyor; seçim
    /// değiştiğinde SwiftUI'nin yeniden çizmesi `Preferences`'taki değere bağlı.
    var bundle: Bundle { Resolved(self).bundle }

    /// Bu dilin `Locale`'i.
    var locale: Locale { Resolved(self).locale }

    /// Seçimi uyguluyor. Yalnız `Preferences` çağırıyor; tek yazan olması kasıtlı.
    static func apply(_ language: AppLanguage) {
        state.withLock { $0 = Resolved(language) }
    }

    /// Çözülmüş seçim.
    ///
    /// Kilit arkasında: metinler görünüm katmanının **dışından** da okunuyor
    /// (erişilebilirlik etiketleri, mağaza hataları), o yüzden bu durum MainActor'a
    /// bağlanamıyor. `Bundle` kurulduktan sonra değişmiyor ve arama işlemleri iş
    /// parçacığı güvenli; `@unchecked` o yüzden.
    private struct Resolved: @unchecked Sendable {
        let bundle: Bundle
        let locale: Locale

        init(_ language: AppLanguage) {
            switch language {
            case .system:
                bundle = .main
                locale = .autoupdatingCurrent
            case .fixed(let code):
                bundle = Bundle.main.path(forResource: code, ofType: "lproj")
                    .flatMap(Bundle.init(path:)) ?? .main
                locale = Locale(identifier: code)
            }
        }
    }

    private static let state = OSAllocatedUnfairLock(initialState: Resolved(.system))
}

/// Seçili dildeki metin.
///
/// `String(localized:)` yerine bunu çağırmanın sebebi paket: kodda kurulan bir metin
/// hangi `.lproj`'dan okunacağını ortam `locale`'ine değil pakete soruyor, yani
/// `.environment(\.locale, …)` tek başına kodda kurulan metinleri çevirmiyor (ADR 0026).
///
/// Değişmez buraya da düz geçiyor, yani `-exportLocalizations` dizgiyi görmeye devam
/// ediyor; ADR 0019'un "her metin çıkarmaya görünür" garantisi korunuyor.
func localized(_ value: String.LocalizationValue, comment: StaticString? = nil) -> String {
    String(
        localized: value,
        bundle: AppLanguage.currentBundle,
        locale: AppLanguage.currentLocale,
        comment: comment
    )
}
