import SwiftUI

/// 1-9 rakam çubuğu ve silgi (brief b.7: "Hücre seç, 1-9 rakam çubuğu").
///
/// Beş sütunluk ızgara: dokuz düğme tek satıra dizilse iPhone genişliğinde 38 pt'ye
/// düşüyor ve bu kitle için dar. Calcudoku'nun dört rakamı aynı ızgarada tek satır
/// oluyor, ayrı bir yerleşim gerekmiyor.
struct NumberPad: View {
    /// Calcudoku'da aralık ızgara kenarı kadar: 4×4'te 1-4.
    let digits: ClosedRange<Int>
    let isPencilMode: Bool
    let isEnabled: Bool
    let onDigit: (Int) -> Void
    let onErase: () -> Void

    /// Sütun sayısı rakam sayısına göre: Kakuro'nun dokuz rakamı + silgi iki satır
    /// (tek satırda düğme 38 pt'ye düşüyor ve bu kitle için dar), Calcudoku'nun dört ya
    /// da beş rakamı tek satır. Sabit beş sütunda Calcudoku'da silgi tek başına alta
    /// düşüyordu.
    private var columns: [GridItem] {
        let count = digits.count + 1
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count <= 6 ? count : 5)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(digits, id: \.self) { digit in
                Button {
                    onDigit(digit)
                } label: {
                    Text("\(digit)")
                        .font(isPencilMode ? .title3 : .title2.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: Metrics.minimumTapTarget)
                }
                .buttonStyle(PadButtonStyle(isPencilMode: isPencilMode))
            }
            Button(action: onErase) {
                Image(systemName: "delete.left")
                    .font(.title3)
                    .frame(maxWidth: .infinity, minHeight: Metrics.minimumTapTarget)
            }
            .buttonStyle(PadButtonStyle(isPencilMode: false))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .padding(.horizontal, Metrics.screenPadding)
    }
}

private struct PadButtonStyle: ButtonStyle {
    let isPencilMode: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isPencilMode ? Color.inkSoft : Color.ink)
            .background(configuration.isPressed ? Color.selection : Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.rule, lineWidth: Metrics.hairline)
            )
    }
}
