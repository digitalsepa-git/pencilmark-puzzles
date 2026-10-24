import Testing
import PuzzleKit
@testable import Pencilmark

@Suite("Varyant metinleri")
struct VariantPresentationTests {
    @Test("Her varyantın tanıtım satırı var")
    func everyVariantHasATagline() {
        for variant in PuzzleVariantID.allCases {
            #expect(!variant.tagline.isEmpty)
            #expect(!variant.displayName.isEmpty)
        }
    }

    // Brief b.4: rakip marka adları ne anahtar kelime alanında ne uygulama içi metinlerde
    // geçebilir — Apple'ın kurallarına aykırı ve ret sebebi. Kural akılda tutulacak bir şey
    // değil, kapı olmalı.
    @Test("Hiçbir metinde rakip marka adı yok")
    func userFacingTextAvoidsCompetitorBrands() {
        let banned = ["kenken", "kendoku", "nikoli", "mathdoku puzzle by"]
        var strings = PuzzleVariantID.allCases.flatMap { [$0.displayName, $0.tagline] }
        strings += Difficulty.allCases.map(\.displayName)

        for text in strings {
            let lowered = text.lowercased()
            for brand in banned {
                #expect(!lowered.contains(brand), "\"\(text)\" içinde \"\(brand)\" var")
            }
        }
    }

    @Test("Zorluk adları dört seviyeyi karşılıyor")
    func everyDifficultyHasADisplayName() {
        #expect(Difficulty.allCases.map(\.displayName) == ["Easy", "Medium", "Hard", "Expert"])
    }
}
