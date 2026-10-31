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

    /// Kodda kurulan her metin seçili dilin paketinden okunuyor mu (ADR 0026).
    ///
    /// `String(localized:)` doğrudan çağrılırsa metin **uygulamanın** paketinden gelir,
    /// yani uygulama içinden seçilen dil o satırda işlemez. Hata sessiz: ekranın bir
    /// köşesi eski dilde kalır. Tek doğru yol `localized(_:)`.
    @Test("Kodda kurulan metinler sarmalayıcıdan geçiyor")
    func codeBuiltStringsGoThroughTheWrapper() throws {
        let sources = Self.sourceDirectory.appendingPathComponent("Sources")
        let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)
        var offenders: [String] = []

        while let url = files?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            // Sarmalayıcının kendisi `String(localized:)` çağırmak zorunda.
            guard url.lastPathComponent != "AppLanguage.swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            for (number, line) in text.split(separator: "\n", omittingEmptySubsequences: false)
                .enumerated() where line.contains("String(localized:") {
                // Açıklama satırları sayılmıyor; metni anlatan yorumlar var.
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("//"), !trimmed.hasPrefix("///") else { continue }
                offenders.append("\(url.lastPathComponent):\(number + 1)")
            }
        }

        #expect(offenders.isEmpty, "localized(_:) kullanılmalı: \(offenders.joined(separator: ", "))")
    }

    /// Katalogdan kaçan İngilizce metin var mı (#102).
    ///
    /// Dil bütünlüğü kapısı yalnız **katalogdaki** dizgilere bakıyor; katalogdan hiç
    /// geçmeyen bir metni göremiyor. Kaçmanın en sessiz yolu tip: `Text(_:)` bir
    /// `String` aldığında çeviri yapmıyor ve Xcode da dizgiyi çıkarmıyor, yani metin
    /// hem katalogda yok hem ekranda İngilizce. "Current streak", "Longest streak" ve
    /// "Continue where you left off" tam olarak böyle kaçmıştı.
    ///
    /// Tarama satır satır: yorumlar, çok satırlı değişmezler, interpolasyonlu metinler
    /// (katalogda `%lld` biçiminde duruyorlar) ve `comment:` argümanları dışarıda.
    /// Geriye kalan ölçüt kaba ama kaçanları yakalıyor: boşluk içeren, harfle başlayan,
    /// yalnız ASCII bir dizgi ekrana çıkacak düzyazıdır.
    @Test("Katalogdan kaçan İngilizce metin yok")
    func everyUserFacingLiteralIsInTheCatalog() throws {
        let catalog = try Self.catalog()
        let sources = Self.sourceDirectory.appendingPathComponent("Sources")
        let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)
        var offenders: [String] = []

        while let url = files?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            var insideMultiline = false

            for (number, line) in text.split(separator: "\n", omittingEmptySubsequences: false)
                .enumerated() {
                let fences = String(line).components(separatedBy: "\"\"\"").count - 1
                if fences > 0 {
                    if !fences.isMultiple(of: 2) { insideMultiline.toggle() }
                    continue
                }
                if insideMultiline { continue }
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") { continue }

                for literal in Self.prose(in: String(line)) where catalog.strings[literal] == nil {
                    offenders.append("\(url.lastPathComponent):\(number + 1) \"\(literal)\"")
                }
            }
        }

        #expect(
            offenders.isEmpty,
            "Katalogda olmayan metin: \(offenders.prefix(10).joined(separator: ", "))"
        )
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

    /// Yeni çıkarılmış bir dizgide `localizations` düğümü **hiç olmuyor**: anahtarın
    /// kendisi kaynak dildeki değer. Swift'in sentezlediği çözücü eksik anahtarda
    /// varsayılan değeri kullanmadığı için okuma elle yazılıyor.
    struct Entry: Decodable {
        var shouldTranslate: Bool?
        var localizations: [String: CatalogLocalization]

        private enum CodingKeys: String, CodingKey {
            case shouldTranslate, localizations
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            shouldTranslate = try container.decodeIfPresent(Bool.self, forKey: .shouldTranslate)
            localizations = try container.decodeIfPresent(
                [String: CatalogLocalization].self, forKey: .localizations
            ) ?? [:]
        }
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

    /// Satırdaki, ekrana çıkabilecek değişmezler.
    ///
    /// Elle tarama: `//` bir değişmezin içinde de geçebiliyor (bağlantılar), o yüzden
    /// yorumun nerede başladığı ancak tırnakların içinde olup olmadığı bilinerek
    /// söylenebiliyor.
    static func prose(in line: String) -> [String] {
        var literals: [String] = []
        var current = ""
        var insideLiteral = false
        var previous = ""
        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let character = characters[index]
            if insideLiteral {
                if character == "\\", index + 1 < characters.count {
                    // Kaçışlı çift karakter bir bütün: yarısını almak anahtarı bozar.
                    current.append(character)
                    current.append(characters[index + 1])
                    index += 2
                    continue
                }
                if character == "\"" {
                    // `comment:` argümanı çevirmene not, ekrana çıkmıyor.
                    if !previous.hasSuffix("comment:"), isProse(current) {
                        literals.append(current)
                    }
                    current = ""
                    insideLiteral = false
                    index += 1
                    continue
                }
                current.append(character)
                index += 1
                continue
            }
            if character == "\"" {
                insideLiteral = true
                index += 1
                continue
            }
            if character == "/", index + 1 < characters.count, characters[index + 1] == "/" {
                break
            }
            if !character.isWhitespace { previous.append(character) }
            index += 1
        }
        return literals
    }

    private static func isProse(_ literal: String) -> Bool {
        guard literal.allSatisfy(\.isASCII) else { return false }
        guard !literal.contains("\\(") else { return false }
        guard literal.contains(" ") else { return false }
        return literal.first?.isLetter == true
    }

    static func languages(in catalog: StringCatalog) -> Set<String> {
        Set(catalog.strings.values.flatMap(\.localizations.keys))
    }
}
