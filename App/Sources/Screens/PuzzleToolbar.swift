import SwiftUI

/// Araç çubuğu: geri al, ileri al, kalem, ipucu, kontrol (brief b.7).
///
/// Modele bağlı değil, değerlere bağlı: beş varyantın modeli farklı tiplerde ve çubuğun
/// bunu bilmesi için bir sebep yok.
struct PuzzleToolbar: View {
    let canUndo: Bool
    let canRedo: Bool
    /// `nil` ise kalem düğmesi çizilmiyor.
    let isPencilMode: Bool?
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onPencil: () -> Void
    let onHint: () -> Void
    let onCheck: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            button("arrow.uturn.backward", "Undo", enabled: canUndo, action: onUndo)
            button("arrow.uturn.forward", "Redo", enabled: canRedo, action: onRedo)
            if let isPencilMode {
                button(
                    isPencilMode ? "pencil.circle.fill" : "pencil.circle",
                    "Pencil",
                    enabled: true,
                    highlighted: isPencilMode,
                    action: onPencil
                )
            }
            button("lightbulb", "Hint", enabled: true, action: onHint)
            button("checkmark.circle", "Check", enabled: true, action: onCheck)
        }
        .padding(.horizontal, Metrics.screenPadding)
    }

    private func button(
        _ systemImage: String,
        _ title: String,
        enabled: Bool,
        highlighted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: Metrics.minimumTapTarget)
        }
        .disabled(!enabled)
        .foregroundStyle(highlighted ? Color.ink : (enabled ? Color.inkSoft : Color.rule))
    }
}
