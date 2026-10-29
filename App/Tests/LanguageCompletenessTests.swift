import Foundation
import GameCore
import PuzzleKit
import Testing
@testable import Pencilmark

/// İkinci dilin sessizce eksik kalmasını engelleyen kapı (ADR 0025).
///
/// ADR 0019 bu boşluğu kayda geçmişti: katalogda bir dizginin çevirisi eksik kalırsa
/// hiçbir şey kırılmıyor, uygulama sessizce İngilizceye düşüyor. Tek dilliyken bedeli
/// yoktu; ikinci dille birlikte yarım çeviri gönderilebilir hâle geliyor.
///
/// Test katalog dosyasını **kaynak ağacından** okuyor, paketten değil: eksik çeviri
/// zaten pakete girmiyor ve pakete bakan bir test onu göremezdi.
@Suite("Dil bütünlüğü")
struct LanguageCompletenessTests {
    /// Katalogdaki her dizginin, katalogda geçen her dilde çevirisi var mı.
    ///
    /// Beklenen dil listesi elle yazılmıyor: katalogda **geçen** diller üzerinden
    /// yürüyor. Böylece yeni bir dil eklendiğinde test kendiliğinden onu da kapsıyor;
    /// elle yazılan bir liste güncellenmeyi unutulurdu.
    @Test("Her dizgi her dilde çevrili")
    func everyStringIsTranslatedInEveryLanguage() throws {
        let catalog = try Self.catalog()
        let languages = Self.languages(in: catalog)
        #expect(languages.contains(catalog.sourceLanguage))

        var missing: [String] = []
        for (key, entry) in catalog.strings {
            guard entry.shouldTranslate ?? true else { continue }
            for language in languages where language != catalog.sourceLanguage {
                guard let unit = entry.localizations[language] else {
                    missing.append("\(language): \(key)")
                    continue
                }
                // "new" Xcode'un yeni çıkardığı dizgiye verdiği durum; kaynak dilde
                // zararsız ama çeviride "henüz çevrilmedi" demek. "stale" ise kaynak
                // metin değişmiş, çeviri eskimiş.
                if unit.state != "translated" {
                    missing.append("\(language): \(key) [\(unit.state)]")
                }
            }
        }

        #expect(missing.isEmpty, "Eksik çeviri: \(missing.prefix(10).joined(separator: ", "))")
    }

    /// Katalogda geçen her dil projede de tanınıyor mu.
    ///
    /// İkisi ayrışırsa çeviri katalogda durur ama pakete hiç girmez — sessiz ve
    /// bulması zor bir hata.
    @Test("Katalogdaki diller projede tanımlı")
    func catalogLanguagesAreKnownToTheProject() throws {
        let catalog = try Self.catalog()
        let project = try String(contentsOf: Self.projectFile, encoding: .utf8)
        let regions = try #require(
            project.firstMatch(of: /knownRegions = \(([^)]*)\)/)?.1
        )
        let known = Set(
            regions.split(whereSeparator: { ",\n\t ".contains($0) }).map(String.init)
        )

        for language in Self.languages(in: catalog) {
            #expect(known.contains(language), "\(language) knownRegions içinde yok")
        }
    }

    /// Öğreticinin her adımının bir cümlesi var mı (ADR 0025).
    ///
    /// Anlatım `GameCore`'dan uygulama katmanına taşındı ve ikisi artık ayrı yerlerde
    /// duruyor: senaryoya bir adım eklenip cümlesi yazılmazsa ızgaranın üstü boş kalır.
    /// Derleyici bunu yakalamıyor, bu test yakalıyor.
    @Test("Her öğretici adımının cümlesi var")
    func everyTutorialStepHasASentence() {
        let counts: [PuzzleVariantID: Int] = [
            .kakuro: TutorialScenarios.kakuro().steps.count,
            .calcudoku: TutorialScenarios.calcudoku().steps.count,
            .hitori: TutorialScenarios.hitori().steps.count,
            .slitherlink: TutorialScenarios.slitherlink().steps.count,
            .hashi: TutorialScenarios.hashi().steps.count
        ]

        for (variant, stepCount) in counts {
            let texts = TutorialCopy.texts(for: variant)
            #expect(
                texts.count == stepCount,
                "\(variant): \(stepCount) adım, \(texts.count) cümle"
            )
            #expect(texts.allSatisfy { !$0.isEmpty })
            #expect(!TutorialCopy.correction(for: variant).isEmpty)
        }
    }
}

/// Katalog dosyasının okunan kadarı.
struct StringCatalog: Decodable {
    let sourceLanguage: String
    let strings: [String: Entry]

    struct Entry: Decodable {
        var shouldTranslate: Bool?
        var localizations: [String: CatalogLocalization] = [:]
    }
}

/// Bir dizginin tek bir dildeki hâli.
///
/// Çoğul ya da cihaza göre değişen dizgilerde `stringUnit` yerine `variations` duruyor.
/// Böyle bir girdide durum tek bir değer değil; varyasyonların **en kötüsü** alınıyor,
/// yani biri çevrilmemişse girdi çevrilmemiş sayılıyor.
struct CatalogLocalization: Decodable {
    let state: String

    private enum CodingKeys: String, CodingKey {
        case stringUnit, variations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let unit = try container.decodeIfPresent(CatalogUnit.self, forKey: .stringUnit) {
            state = unit.state
            return
        }
        let variations = try container.decodeIfPresent(
            [String: [String: CatalogVariation]].self, forKey: .variations
        )
        let states = (variations ?? [:]).values.flatMap(\.values).compactMap(\.stringUnit?.state)
        state = !states.isEmpty && states.allSatisfy { $0 == "translated" } ? "translated" : "new"
    }
}

struct CatalogUnit: Decodable {
    let state: String
}

struct CatalogVariation: Decodable {
    let stringUnit: CatalogUnit?
}

extension LanguageCompletenessTests {
    static var sourceDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var projectFile: URL {
        sourceDirectory.appendingPathComponent("Pencilmark.xcodeproj/project.pbxproj")
    }

    static func catalog() throws -> StringCatalog {
        let url = sourceDirectory.appendingPathComponent("Sources/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(StringCatalog.self, from: data)
    }

    static func languages(in catalog: StringCatalog) -> Set<String> {
        Set(catalog.strings.values.flatMap(\.localizations.keys))
    }
}
