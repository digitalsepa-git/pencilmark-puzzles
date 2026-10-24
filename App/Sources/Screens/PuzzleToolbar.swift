import SwiftUI

/// Araç çubuğu: geri al, ileri al, kalem, ipucu, kontrol (brief b.7).
struct PuzzleToolbar: View {
    @Bindable var model: KakuroGameModel

    var body: some View {
        HStack(spacing: 0) {
            button("arrow.uturn.backward", "Undo", enabled: model.canUndo) { model.undo() }
            button("arrow.uturn.forward", "Redo", enabled: model.canRedo) { model.redo() }
            button(
                model.isPencilMode ? "pencil.circle.fill" : "pencil.circle",
                "Pencil",
                enabled: true,
                highlighted: model.isPencilMode
            ) {
                model.isPencilMode.toggle()
            }
            button("lightbulb", "Hint", enabled: true) { model.hint() }
            button("checkmark.circle", "Check", enabled: true) { model.check() }
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
