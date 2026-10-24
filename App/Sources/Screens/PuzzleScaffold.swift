import GameCore
import PuzzleKit
import SwiftUI

/// Bulmaca ekranlarının ortak iskeleti: üretim/hata durumları, ızgaranın yerleşimi,
/// araç çubuğu ve bitiş ekranı.
///
/// Beş varyantın ekranı yalnız iki şeyde ayrılıyor — ızgaranın kendisi ve (varsa) rakam
/// çubuğu. Geri kalan her şey burada; aksi halde aynı yerleşim beş yerde tekrarlanır ve
/// beşi zamanla birbirinden ayrılır.
struct PuzzleScaffold<Runtime: PuzzleRuntime, Board: View, Footer: View>: View {
    let model: PuzzleGameModel<Runtime>
    @ViewBuilder let board: (GameSession<Runtime>) -> Board
    @ViewBuilder let footer: (GameSession<Runtime>) -> Footer

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        content
            .background(Color.paper)
            .navigationTitle(model.difficulty.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .generating:
            VStack(spacing: 12) {
                ProgressView()
                Text("Building a puzzle…")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSoft)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            VStack(spacing: 12) {
                Text("Could not build a puzzle.")
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center)
                Button("Try again") {
                    Task { await model.start() }
                }
                .buttonStyle(.bordered)
            }
            .padding(Metrics.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .playing:
            playing
        }
    }

    @ViewBuilder
    private var playing: some View {
        if let session = model.session {
            VStack(spacing: 16) {
                // Izgara boş alanda ortalanıyor: üstte sabit durması, küçük ızgaralarda
                // ekranın altında kocaman bir boşluk bırakıyordu.
                Spacer(minLength: 0)

                board(session)
                    .padding(.horizontal, Metrics.screenPadding)

                Spacer(minLength: 0)

                footer(session)

                PuzzleToolbar(
                    canUndo: model.canUndo,
                    canRedo: model.canRedo,
                    isPencilMode: pencilState,
                    onUndo: { model.undo() },
                    onRedo: { model.redo() },
                    onPencil: { model.isPencilMode.toggle() },
                    onHint: { model.hint() },
                    onCheck: { model.check() }
                )
            }
            .padding(.vertical, 12)
            .overlay {
                if model.isSolved {
                    SolvedOverlay(hintCount: model.hintCount) { dismiss() }
                }
            }
        }
    }

    /// `nil` ise kalem düğmesi çizilmiyor: kalem işareti yalnız rakam yazılan varyantlarda
    /// var (brief b.7).
    private var pencilState: Bool? {
        Runtime.self is any DigitPuzzleRuntime.Type ? model.isPencilMode : nil
    }
}

/// Bitiş ekranı. Brief b.7: ipucu kullanılan bulmaca "çözüldü" sayılıyor ama ayrı
/// işaretleniyor, bu yüzden ipucu sayısı burada görünüyor.
struct SolvedOverlay: View {
    let hintCount: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.paper.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Solved")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.ink)
                Text(hintSummary)
                    .font(.body)
                    .foregroundStyle(Color.inkSoft)
                Button("Back to puzzles", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(Metrics.screenPadding)
        }
    }

    private var hintSummary: String {
        switch hintCount {
        case 0: "No hints used"
        case 1: "1 hint used"
        default: "\(hintCount) hints used"
        }
    }
}
