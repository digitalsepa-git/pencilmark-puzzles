import SwiftUI

/// Bir çizim geçişinde tekrar eden rakamların çözümlenmiş hâli.
///
/// `GraphicsContext.draw(Text, at:)` her çağrıda metni baştan çözümlüyor ve ızgara
/// çiziminde bunun maliyeti baskın: 11×11 Kakuro'nun bütün hücreleri kalem işaretli
/// olduğunda kare başına 900 metin düşüyor ve çizim ~43 ms sürüyordu — 60 fps'in 16.7
/// ms'lik kare bütçesinin iki buçuk katı. Aynı ızgara, rakamlar geçiş başına bir kez
/// çözümlendiğinde ~6 ms (ölçüm `GridRenderPerformanceTests`'te).
///
/// Çizilen piksel aynı: `draw(Text)` zaten içeride aynı çözümlemeyi yapıyor.
struct GridDigitText {
    private let digits: ClosedRange<Int>
    private let resolved: [GraphicsContext.ResolvedText]

    init(context: GraphicsContext, digits: ClosedRange<Int>, font: Font, color: Color) {
        self.digits = digits
        resolved = digits.map { digit in
            context.resolve(Text("\(digit)").font(font).foregroundStyle(color))
        }
    }

    /// Aralığın dışındaki bir rakam en yakın uca kırpılıyor: çizim kapanışının içinde
    /// çökmek, yanlış rakam çizmekten kötü.
    func text(_ digit: Int) -> GraphicsContext.ResolvedText {
        resolved[min(max(digit, digits.lowerBound), digits.upperBound) - digits.lowerBound]
    }
}

/// Hücre oynanan üç varyantın ihtiyacı: kesin değer, hatalı değer ve kalem işareti.
struct GridTextCache {
    private let candidates: GridDigitText
    private let values: GridDigitText
    private let wrongValues: GridDigitText

    init(context: GraphicsContext, style: GridStyle, digits: ClosedRange<Int>) {
        candidates = GridDigitText(
            context: context,
            digits: digits,
            font: style.candidateFont,
            color: .inkSoft
        )
        values = GridDigitText(
            context: context,
            digits: digits,
            font: style.valueFont,
            color: .ink
        )
        wrongValues = GridDigitText(
            context: context,
            digits: digits,
            font: style.valueFont,
            color: .mistake
        )
    }

    /// Kalem işareti.
    func candidate(_ digit: Int) -> GraphicsContext.ResolvedText {
        candidates.text(digit)
    }

    /// Kesin değer; hatalıysa kırmızı.
    func value(_ digit: Int, isMistake: Bool = false) -> GraphicsContext.ResolvedText {
        (isMistake ? wrongValues : values).text(digit)
    }
}
