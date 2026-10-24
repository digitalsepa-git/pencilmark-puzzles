import SwiftUI

/// 1-9 rakam çubuğu ve silgi (brief b.7: "Hücre seç, 1-9 rakam çubuğu").
///
/// Tek satır yerine iki satır: tek satırda dokuz düğme iPhone genişliğinde 38 pt'ye
/// düşüyor ve bu kitle için dar. İki satır her düğmeye asgari dokunma hedefinden geniş
/// yer bırakıyor.
struct NumberPad: View {
    let isPencilMode: Bool
    let isEnabled: Bool
    let onDigit: (Int) -> Void
    let onErase: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...9, id: \.self) { digit in
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
