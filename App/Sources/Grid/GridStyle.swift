import CoreGraphics
import SwiftUI

/// Izgara çiziminin ölçüleri. Hepsi hücre kenarından türüyor, hiçbiri sabit punto değil.
///
/// Bu bilinçli bir sapma: uygulamanın geri kalanı Dynamic Type'a uyuyor ama ızgaradaki
/// rakamlar hücreyle birlikte büyüyor. Sebebi, hücrenin büyüyemiyor olması — 12×12 bir
/// ızgarada hücre zaten ekranın onda biri ve metni bağımsız büyütmek rakamı hücrenin
/// dışına taşırıyor. Izgara kendisi ekranın tamamını kullanıyor, yani okunaklılık ızgara
/// boyutuyla değil ekran boyutuyla ölçekleniyor.
struct GridStyle {
    let geometry: GridGeometry

    var thinLine: CGFloat { max(geometry.cellSide * 0.02, 0.5) }
    var thickLine: CGFloat { max(geometry.cellSide * 0.07, 1.5) }

    /// Kesin değer.
    var valueFont: Font { .system(size: geometry.cellSide * 0.56, weight: .medium) }
    /// Kalem işareti — kesin değerin yarısından küçük, karışmasın diye.
    var candidateFont: Font { .system(size: geometry.cellSide * 0.24, weight: .regular) }
    /// Kakuro'nun ipucu toplamı — siyah hücrenin yarısına sığmak zorunda.
    var clueFont: Font { .system(size: geometry.cellSide * 0.34, weight: .semibold) }
    /// Slitherlink'in ipucu rakamı. Kesin değerden küçük ve normal kalınlıkta: ipucu
    /// okunmalı ama ızgaraya hükmetmemeli, oynanan şey çizgiler.
    var slitherlinkClueFont: Font { .system(size: geometry.cellSide * 0.44, weight: .regular) }
    /// Calcudoku kafes etiketi. Köşede duruyor ve hücrenin ortasındaki rakamla ya da
    /// kalem işaretleriyle çakışmamak için belirgin biçimde küçük.
    var cageFont: Font { .system(size: geometry.cellSide * 0.22, weight: .semibold) }
    /// Hashi adasının derecesi.
    var islandFont: Font { .system(size: geometry.cellSide * 0.46, weight: .semibold) }

    /// Kalem işaretinin 3×3 yerleşiminde bir rakamın merkezi.
    func candidateCenter(of digit: Int, in rect: CGRect) -> CGPoint {
        let index = digit - 1
        let column = CGFloat(index % 3)
        let row = CGFloat(index / 3)
        let inset = rect.width * 0.12
        let usable = rect.width - inset * 2
        let step = usable / 3
        return CGPoint(
            x: rect.minX + inset + step * (column + 0.5),
            y: rect.minY + inset + step * (row + 0.5)
        )
    }
}
