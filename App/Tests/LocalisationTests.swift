import Testing
import Foundation
@testable import Pencilmark

/// Yerelleştirme altyapısının yerinde durduğunu koruyan testler (ADR 0019).
///
/// Katalog silinse ya da boşalsa derleme yine geçiyor ve uygulama İngilizce çalışmaya
/// devam ediyor — eksiklik ancak ikinci dil eklenirken görülürdü.
@Suite("Yerelleştirme")
struct LocalisationTests {
    @Test("İngilizce tablo pakette")
    func englishTableShips() throws {
        #expect(Bundle.main.localizations.contains("en"))
        let url = Bundle.main.url(
            forResource: "Localizable", withExtension: "strings", subdirectory: "en.lproj"
        )
        #expect(url != nil)
    }

    // Kaba bir alt sınır: katalog boşalırsa ya da çıkarma kırılırsa yakalar. Kesin sayı
    // yazmak her yeni metinde testi kırardı.
    @Test("Tabloda beklenen büyüklükte dizgi var")
    func tableIsPopulated() throws {
        let url = try #require(
            Bundle.main.url(
                forResource: "Localizable", withExtension: "strings", subdirectory: "en.lproj"
            )
        )
        let table = try #require(NSDictionary(contentsOf: url) as? [String: String])
        #expect(table.count > 50, "Tabloda \(table.count) dizgi var")
    }

    // Kodda kurulan metinler `String(localized:)` olmazsa çıkarmaya görünmüyor; bu test
    // onlardan birkaçının gerçekten tabloda olduğunu kontrol ediyor.
    @Test("Kodda kurulan metinler tabloda")
    func composedStringsAreExtracted() throws {
        let url = try #require(
            Bundle.main.url(
                forResource: "Localizable", withExtension: "strings", subdirectory: "en.lproj"
            )
        )
        let table = try #require(NSDictionary(contentsOf: url) as? [String: String])

        let keys = [
            "Empty", "Shaded", "No bridge", "Single bridge", "Easy", "Expert",
            // Kota metinleri de kodda kuruluyor (ADR 0007'nin sayıları arayüze
            // interpolasyonla giriyor).
            "Hint (%lld)", "1 free puzzle left today", "%lld free puzzles left today"
        ]
        for key in keys {
            #expect(table[key] != nil, "\(key) tabloda yok")
        }
    }

    // ADR 0019: bulmaca adları çevrilmiyor. Bir çevirmenin "Hitori"yi yerel bir
    // karşılıkla değiştirmesi brief b.4'e aykırı olurdu.
    @Test("Bulmaca adları çeviriye açılmamış")
    func puzzleNamesAreNotTranslatable() throws {
        let url = try #require(
            Bundle.main.url(
                forResource: "Localizable", withExtension: "strings", subdirectory: "en.lproj"
            )
        )
        let table = try #require(NSDictionary(contentsOf: url) as? [String: String])

        for name in ["Kakuro", "Calcudoku", "Slitherlink", "Hashi", "Hitori"] {
            #expect(table[name] == nil, "\(name) çeviri tablosunda")
        }
    }
}
