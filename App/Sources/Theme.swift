import SwiftUI
import UIKit

/// Kâğıt hissi, yüksek kontrast, geniş dokunma hedefleri (brief b.7). Kitle 35 yaş üstü,
/// kâğıt-kalem bulmaca geçmişi olan insanlar; beklentileri sakin ve okunaklı bir arayüz.
///
/// Renkler varlık kataloğu yerine burada tanımlı. Sebebi, katalogun ikili bir dosya olması:
/// repoda okunamıyor, PR'da diff'i görünmüyor ve bir rengin neden o değer olduğu
/// yazılamıyor. Beş-altı renk için kod daha dürüst bir yer.
extension Color {
    /// Zemin. Açık modda kirli beyaz — saf beyaz ekranda parlıyor ve uzun oturumda yoruyor.
    static let paper = dynamic(
        light: UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1),
        dark: UIColor(white: 0.071, alpha: 1)
    )

    /// Ana metin ve ızgara çizgileri. Saf siyah değil; kâğıt üstünde mürekkep biraz açıktır.
    static let ink = dynamic(
        light: UIColor(white: 0.118, alpha: 1),
        dark: UIColor(red: 0.937, green: 0.929, blue: 0.906, alpha: 1)
    )

    /// İkincil metin.
    static let inkSoft = dynamic(
        light: UIColor(white: 0.361, alpha: 1),
        dark: UIColor(white: 0.675, alpha: 1)
    )

    /// Kart zemini — zeminden bir tık ayrılıyor, gölge kullanmadan.
    static let card = dynamic(
        light: UIColor(white: 1, alpha: 1),
        dark: UIColor(white: 0.133, alpha: 1)
    )

    /// Kart kenarı ve ayırıcı çizgiler.
    static let rule = dynamic(
        light: UIColor(white: 0.831, alpha: 1),
        dark: UIColor(white: 0.286, alpha: 1)
    )

    /// Seçili hücre. Doygun bir vurgu değil: bu kitle sakin arayüz bekliyor ve seçim
    /// kalıcı değil, dokunuşla geziniyor.
    static let selection = dynamic(
        light: UIColor(red: 0.898, green: 0.925, blue: 0.976, alpha: 1),
        dark: UIColor(red: 0.149, green: 0.196, blue: 0.282, alpha: 1)
    )

    /// Hata kontrolünün işaretlediği giriş. Kırmızı, çünkü anlamı evrensel; ama ızgara
    /// zemininde okunabilsin diye koyu tarafta.
    static let mistake = dynamic(
        light: UIColor(red: 0.702, green: 0.153, blue: 0.133, alpha: 1),
        dark: UIColor(red: 0.937, green: 0.427, blue: 0.400, alpha: 1)
    )

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

/// Ölçüler tek yerde: Dynamic Type büyüdüğünde kartların birbirine girmemesi buna bağlı.
enum Metrics {
    /// Apple'ın asgarisi 44 pt; bu kitle için daha geniş tutuluyor.
    static let minimumTapTarget: CGFloat = 60
    static let screenPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    static let hairline: CGFloat = 1

    /// Ana ekrandaki mini ızgaranın kenarı (ADR 0027). Satır yüksekliğini belirleyen
    /// şey bu değil: dokunma hedefi asgarisi hâlâ daha büyük.
    static let previewSize: CGFloat = 56
    /// Önizlemede iki açılış arasındaki süre. Sakin bir tempo: gözün takip edebileceği
    /// kadar yavaş, bekletmeyecek kadar hızlı.
    static let previewStep: Double = 0.55
    /// Çözülünce beklenen süre; sonra baştan.
    static let previewHold: Double = 1.8
    /// Açılan hücrenin belirme süresi. Kesme yerine kısa bir yumuşama.
    static let previewFade: Double = 0.2
    /// Kaç tur oynanıp durulacağı. Sonsuz döngü sakin bir ekran değil.
    static let previewCycles = 2
}
