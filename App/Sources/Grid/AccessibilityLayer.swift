import PuzzleKit
import SwiftUI

/// `Canvas` ile çizilen ızgaranın üstüne, VoiceOver'ın gezebileceği görünmez öğeler
/// koyuyor.
///
/// Öğelerin çerçeveleri çizimdekiyle aynı geometriden türüyor; yoksa VoiceOver imleci
/// ekranda yanlış yeri gösterir ve dokunarak gezinme çalışmaz.
struct GridAccessibilityLayer<Cell: View>: View {
    let geometry: GridGeometry
    let positions: [Position]
    @ViewBuilder let cell: (Position) -> Cell

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(positions, id: \.self) { position in
                let rect = geometry.rect(of: position)
                cell(position)
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.minX, y: rect.minY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Dizi hâlindeki öğeler (kenarlar, adalar) için; konum yerine doğrudan çerçeve veriyor.
struct GridAccessibilityItems<Item: View>: View {
    let frames: [CGRect]
    @ViewBuilder let item: (Int) -> Item

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(frames.indices, id: \.self) { index in
                item(index)
                    .frame(width: frames[index].width, height: frames[index].height)
                    .offset(x: frames[index].minX, y: frames[index].minY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Tek bir erişilebilirlik öğesi.
///
/// Görünmez (`Color.clear`) çünkü çizimi `Canvas` yapıyor; buradaki tek iş VoiceOver'a
/// ad, değer ve eylem vermek.
struct AccessibilityCell: View {
    let label: String
    var value: String?
    var isInteractive = true
    let action: () -> Void

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(isInteractive ? .isButton : [])
            .accessibilityAction(.default) {
                guard isInteractive else { return }
                action()
            }
    }
}
