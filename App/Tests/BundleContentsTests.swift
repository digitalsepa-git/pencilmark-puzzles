import Testing
import Foundation
import UIKit
@testable import Pencilmark

/// Pakete gerçekten giren şeyleri koruyan testler.
///
/// İkisi de gönderim engeli: ikon olmadan uygulama yüklenmiyor, gizlilik beyanı olmadan
/// ya da yanlış olduğunda inceleme takılıyor. İkisi de sessizce kaybolabilecek şeyler —
/// bir varlık kataloğu ayarı ya da bir dosya silinince derleme yine geçiyor.
@Suite("Paket içeriği")
struct BundleContentsTests {
    @Test("Uygulama ikonu pakete bağlı")
    func appIconIsWired() throws {
        let icons = try #require(
            Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any]
        )
        let primary = try #require(icons["CFBundlePrimaryIcon"] as? [String: Any])
        #expect(primary["CFBundleIconName"] as? String == "AppIcon")

        let files = try #require(primary["CFBundleIconFiles"] as? [String])
        #expect(!files.isEmpty)
    }

    @Test("Açılış ekranı zemini kâğıt rengi")
    func launchScreenUsesThePaperColour() throws {
        let launch = try #require(
            Bundle.main.infoDictionary?["UILaunchScreen"] as? [String: Any]
        )
        #expect(launch["UIColorName"] as? String == "LaunchBackground")
        #expect(UIColor(named: "LaunchBackground") != nil)
    }

    private func privacyManifest() throws -> [String: Any] {
        let url = try #require(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        )
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        )
        return try #require(plist as? [String: Any])
    }

    @Test("Gizlilik beyanı pakette")
    func privacyManifestShips() throws {
        #expect(try !privacyManifest().isEmpty)
    }

    // Brief b.9: analitik yok, üçüncü parti SDK yok. Bu iki alanın "evet"e dönmesi
    // gizlilik etiketini bozar ve düzeltmek yeni bir sürüm gerektirir.
    @Test("İzleme ve veri toplama kapalı")
    func manifestDeclaresNoTrackingAndNoCollection() throws {
        let manifest = try privacyManifest()
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyTrackingDomains"] as? [Any])?.isEmpty == true)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
    }

    @Test("Kullanılan required reason API'si beyan edilmiş")
    func manifestDeclaresUserDefaults() throws {
        let manifest = try privacyManifest()
        let types = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaults = types.first {
            $0["NSPrivacyAccessedAPIType"] as? String
                == "NSPrivacyAccessedAPICategoryUserDefaults"
        }
        let entry = try #require(userDefaults)
        let reasons = try #require(entry["NSPrivacyAccessedAPITypeReasons"] as? [String])
        // CA92.1: yalnız bu uygulamanın kendi verisine erişim.
        #expect(reasons.contains("CA92.1"))
    }
}
