import Foundation
import PuzzleKit

/// Varyantların arayüzde görünen metinleri. `displayName` PuzzleKit'te, çünkü kayıt şeması
/// ve günlük bulmaca onu kullanıyor; tanıtım metni burada, çünkü motorun arayüz sözlüğüne
/// ihtiyacı yok.
///
/// Brief b.4 iki kuralı bağlıyor ve ikisi de ret sebebi olabiliyor: uygulama içi metinlerde
/// bulmaca adları jenerik biçimleriyle geçer ("Calcudoku", asla "KenKen"), ve rakip marka
/// adları hiçbir yerde kullanılmaz. `VariantPresentationTests` bunu kapı olarak tutuyor.
extension PuzzleVariantID {
    /// Kartta adın altında duran tek satır. Oyuncu varyantı tanımıyorsa karar bu satırla
    /// veriliyor, bu yüzden kural anlatılıyor — övgü değil.
    var tagline: String {
        switch self {
        case .kakuro: localized("Fill the sums across and down")
        case .calcudoku: localized("Math cages, no repeated digits")
        case .slitherlink: localized("Draw a single closed loop")
        case .hashi: localized("Build bridges between islands")
        case .hitori: localized("Shade out the duplicates")
        }
    }
}

extension Difficulty {
    var displayName: String {
        switch self {
        case .easy: localized("Easy")
        case .medium: localized("Medium")
        case .hard: localized("Hard")
        case .expert: localized("Expert")
        }
    }

    /// Seviyenin oyuncudan ne isteyeceği (#100, ADR 0028).
    ///
    /// Zorluk ızgara boyutuna ya da ipucu sayısına göre değil, bulmacayı bitirmek için
    /// gereken en ileri tekniğe göre belirleniyor (brief b.6, `TechniqueTier`). Satırdaki
    /// cümle o tanımın oyuncu tarafındaki karşılığı; sırasıyla `basic`, `intermediate`,
    /// `advanced` ve `guessing`. Eşlemenin kaymadığını `VariantPresentationTests` tutuyor:
    /// derecelendirmeyle ters düşen bir satır, ekranda duran bir yalan olurdu.
    var tagline: String {
        switch self {
        case .easy: localized("Every square is forced on its own")
        case .medium: localized("Some squares only give way together")
        case .hard: localized("Chains and contradictions, several moves deep")
        case .expert: localized("Logic runs out; you test a branch")
        }
    }
}

// `PuzzleVariantID.displayName` bilerek çevrilmiyor ve PuzzleKit'te kalıyor: "Kakuro",
// "Hitori", "Slitherlink" özel adlar ve brief b.4 bulmaca adlarının jenerik biçimlerinde
// kalmasını şart koşuyor. Çevrilmeleri hem yanlış hem ret sebebi olabilirdi.
