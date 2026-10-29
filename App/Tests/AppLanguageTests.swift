import Foundation
import Testing
@testable import Pencilmark

/// Uygulama içi dil seçimi (ADR 0026).
///
/// Testler seçimi **uygulamıyor**: `AppLanguage.apply` süreç genelinde bir durum
/// değiştiriyor ve swift-testing paketleri paralel koşuyor; uygulanan bir dil başka bir
/// paketin ortasında metinleri değiştirirdi. Onun yerine çözümün kendisi sınanıyor.
@Suite("Uygulama dili")
struct AppLanguageTests {
    @Test("Dil listesi paketten türüyor")
    func availableLanguagesComeFromTheBundle() {
        let available = AppLanguage.available
        #expect(available.first == .system)

        let codes = available.compactMap { language -> String? in
            if case .fixed(let code) = language { return code }
            return nil
        }
        // Pakette ne varsa o: liste kodda sabit değil, üçüncü dil kendiliğinden gelecek.
        let packaged = Bundle.main.localizations.filter { $0 != "Base" }.sorted()
        #expect(codes == packaged)
        #expect(codes.contains("en"))
    }

    @Test("Sistem seçimi uygulamanın kendi paketini kullanıyor")
    func systemUsesTheMainBundle() {
        #expect(AppLanguage.system.bundle == Bundle.main)
    }

    // Asıl mesele bu: kodda kurulan metin hangi `.lproj`'dan okunacağını pakete soruyor.
    // Paket yanlışsa dil seçimi sessizce çalışmıyormuş gibi görünür.
    @Test("Seçilen dilin paketi o dilin metinlerini veriyor")
    func fixedLanguageResolvesItsOwnBundle() throws {
        try #require(Bundle.main.localizations.contains("tr"), "Türkçe pakette yok")
        let bundle = AppLanguage.fixed("tr").bundle
        #expect(bundle != Bundle.main)
        #expect(bundle.localizedString(forKey: "Settings", value: nil, table: nil) == "Ayarlar")

        let english = AppLanguage.fixed("en").bundle
        #expect(english.localizedString(forKey: "Settings", value: nil, table: nil) == "Settings")
    }

    @Test("Bilinmeyen dil uygulamanın paketine düşüyor")
    func unknownLanguageFallsBack() {
        #expect(AppLanguage.fixed("zz").bundle == Bundle.main)
    }

    @Test("Diller kendi adlarıyla yazılıyor")
    func languagesAreNamedInTheirOwnLanguage() {
        #expect(AppLanguage.fixed("en").displayName == "English")
        #expect(AppLanguage.fixed("tr").displayName == "Türkçe")
    }

    // `Locale` biçimlendirmeyi de taşıyor: tarih, sayı ve sıralama buna bakıyor.
    @Test("Seçilen dilin locale'i geliyor")
    func fixedLanguageCarriesItsLocale() {
        #expect(AppLanguage.fixed("tr").locale.identifier == "tr")
        #expect(AppLanguage.system.locale == .autoupdatingCurrent)
    }

    @Test("Seçim kalıcı")
    @MainActor
    func selectionSurvivesRelaunch() throws {
        let suite = "dil-testi-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let first = Preferences(defaults: defaults)
        #expect(first.language == .system)
        first.language = .fixed("tr")

        let second = Preferences(defaults: defaults)
        #expect(second.language == .fixed("tr"))

        // Sisteme dönmek kaydı siliyor; "sistem" bir değer değil, değerin yokluğu.
        second.language = .system
        #expect(Preferences(defaults: defaults).language == .system)
    }

    @Test("Pakette olmayan kayıtlı dil sisteme düşüyor")
    @MainActor
    func savedLanguageThatIsGoneFallsBack() throws {
        let suite = "dil-testi-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set("zz", forKey: "tercih.dil")
        #expect(Preferences(defaults: defaults).language == .system)
    }
}
