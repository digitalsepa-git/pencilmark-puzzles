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
        case .kakuro: "Fill the sums across and down"
        case .calcudoku: "Math cages, no repeated digits"
        case .slitherlink: "Draw a single closed loop"
        case .hashi: "Build bridges between islands"
        case .hitori: "Shade out the duplicates"
        }
    }
}

extension Difficulty {
    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .expert: "Expert"
        }
    }
}
