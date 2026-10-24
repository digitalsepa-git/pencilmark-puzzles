import GameCore
import PuzzleKit
import SwiftUI

/// Bulmaca ekranı (brief b.7, ekran 3): ızgara, rakam çubuğu, araç çubuğu.
///
/// Otomatik kayıt yok — oturum belleğe bağlı ve uygulama kapanırsa oyun kayboluyor.
/// Kayıt katmanı ayrı iş; bu ekranın kapsamı oynanabilirlik.
struct KakuroPuzzleScreen: View {
    let difficulty: Difficulty

    @State private var model: KakuroGameModel
    @Environment(\.dismiss) private var dismiss

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        // Tohum her açılışta farklı: aynı zorlukta arka arkaya aynı bulmacayı vermek
        // rakip şikâyetlerinden biri. Günlük bulmaca ayrı ve tarihten türüyor (ADR 0006).
        var generator = SystemRandomNumberGenerator()
        let counter = UInt64.random(in: 0..<UInt64.max, using: &generator)
        _model = State(
            initialValue: KakuroGameModel(
                difficulty: difficulty,
                seed: Seed.free(variant: .kakuro, difficulty: difficulty, counter: counter)
            )
        )
    }

    var body: some View {
        content
            .background(Color.paper)
            .navigationTitle(difficulty.displayName)
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
                // ızgara boş alanda ortalanıyor: üstte sabit durması, küçük ızgaralarda
                // ekranın altını kocaman bir boşluk bırakıyordu.
                Spacer(minLength: 0)

                KakuroGridView(
                    puzzle: session.definition,
                    board: session.board,
                    selection: session.selection,
                    mistakes: session.mistakes,
                    onTapEntry: { model.select($0) }
                )
                .padding(.horizontal, Metrics.screenPadding)

                Spacer(minLength: 0)

                NumberPad(
                    isPencilMode: model.isPencilMode,
                    isEnabled: session.selection != nil,
                    onDigit: { model.enter($0) },
                    onErase: { model.erase() }
                )

                PuzzleToolbar(model: model)
            }
            .padding(.vertical, 12)
            .overlay {
                if model.isSolved {
                    SolvedOverlay(hintCount: model.hintCount) { dismiss() }
                }
            }
        }
    }
}

/// Bitiş ekranı. Brief b.7: ipucu kullanılan bulmaca "çözüldü" sayılıyor ama ayrı
/// işaretleniyor, bu yüzden ipucu sayısı burada görünüyor.
private struct SolvedOverlay: View {
    let hintCount: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.paper.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Solved")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.ink)
                Text(hintCount == 0 ? "No hints used" : "\(hintCount) hint\(hintCount == 1 ? "" : "s") used")
                    .font(.body)
                    .foregroundStyle(Color.inkSoft)
                Button("Back to puzzles", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(Metrics.screenPadding)
        }
    }
}
