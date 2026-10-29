import Foundation
import PuzzleKit

// Cümleler tek parça değişmez olmak zorunda: `String(localized:)` birleştirilmiş bir
// ifadeyi kabul etmiyor ve çıkarma da yalnız değişmezi görüyor. Satırı bölmenin yolu
// yok, o yüzden uzunluk kuralı bu dosyada kapalı.
// swiftlint:disable line_length

/// Öğreticinin anlatımı (ADR 0009'un cümleleri, ADR 0025'in yeri).
///
/// Cümleler burada, `GameCore`'da değil. Sebebi çeviri: `GameCore` Foundation'ın
/// yerelleştirme kaynaklarını ve bir `Bundle.module` kurmadan `String(localized:)`
/// kullanamıyor ve o kurulum paketin Linux'ta 1x maliyetle test edilmesini riske
/// atıyordu (ADR 0015). Senaryonun yapısı — ızgara, adım sırası, adımın ne zaman
/// bittiği — orada kalmaya devam ediyor; taşınan yalnız proza.
///
/// Anahtar üretmek yerine cümlenin kendisi yazılıyor: üretilmiş anahtarlar çıkarmaya
/// görünmüyor ve katalogu elle doldurmayı gerektirirdi (ADR 0019 bunu yasaklıyor).
enum TutorialCopy {
    /// Adımın ızgara üstündeki cümlesi. Sıra `TutorialScenarios`'takiyle aynı; ikisinin
    /// ayrışmadığını `LanguageCompletenessTests` koruyor.
    static func text(for variant: PuzzleVariantID, step: Int) -> String {
        let steps = texts(for: variant)
        guard steps.indices.contains(step) else { return "" }
        return steps[step]
    }

    /// Yanlış hamleden sonraki tek cümle. Varyant başına tek: ADR 0009 düzeltmeyi
    /// kuralın kendisine bağlıyor, adıma değil.
    static func correction(for variant: PuzzleVariantID) -> String {
        switch variant {
        case .kakuro:
            localized("That doesn't fit the sums. Tap Undo and try another digit.")
        case .calcudoku:
            localized("That digit breaks a row, a column or its cage. Tap Undo and try again.")
        case .hitori:
            localized("That cell stays white in the solution. Tap it again to clear it.")
        case .slitherlink:
            localized("That edge isn't part of the loop. Tap it again to clear it.")
        case .hashi:
            localized("Every island here needs exactly two bridges. Tap the bridge to change it.")
        }
    }

    static func texts(for variant: PuzzleVariantID) -> [String] {
        switch variant {
        case .kakuro: kakuro
        case .calcudoku: calcudoku
        case .hitori: hitori
        case .slitherlink: slitherlink
        case .hashi: hashi
        }
    }

    private static var kakuro: [String] {
        [
            localized("White cells take 1 to 9. The 3 on the left is the sum of this row, and the 9 above is the sum of this column."),
            localized("Digits never repeat inside one sum, so the rest of this row is the only digit left."),
            localized("The bottom row adds up to 17. With two cells, only 8 and 9 do that."),
            localized("One cell left — the column sums tell you which digit goes where.")
        ]
    }

    private static var calcudoku: [String] {
        [
            localized("Every row and column uses 1 to 4 once. A cage showing just a number is already solved — type it in. Start with the 2× pair."),
            localized("Only 1 and 2 multiply to 2, so the other cell of that cage is settled too."),
            localized("Now the top row has two cells left and they add up to 7."),
            localized("Its partner follows from the same cage."),
            localized("Keep going: every cell you fill removes a digit from its row and column.")
        ]
    }

    private static var hitori: [String] {
        [
            localized("Tap a cell to shade it. No number may appear twice in a row or column — the top row has two 1s, so one of them goes."),
            localized("Shaded cells may never touch each other side by side. The first column has two 4s; only one of them can go."),
            localized("The second row has two 3s. Shade the one that keeps the white cells connected."),
            localized("The bottom row has two 2s — and the first column still has a duplicate."),
            localized("One duplicate left. Every white cell must stay reachable from every other.")
        ]
    }

    private static var slitherlink: [String] {
        [
            localized("Tap an edge once for a line, twice for a cross. The 0 in the middle means none of its four edges are used."),
            localized("Each number says how many of that cell's edges the loop uses. Draw the top edge of the grid."),
            localized("The loop never branches and never stops. Follow it down the left side."),
            localized("Close it: one single loop, no loose ends.")
        ]
    }

    private static var hashi: [String] {
        [
            localized("Drag from one island to another to build a bridge. The number says how many bridges that island needs."),
            localized("Bridges run straight, never diagonally, and never cross."),
            localized("Tapping a bridge again doubles it, and once more removes it. Here single bridges are enough."),
            localized("One bridge left. When you're done every island must be reachable from every other.")
        ]
    }
}

// swiftlint:enable line_length
