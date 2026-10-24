import Foundation
import GameCore
import PuzzleKit
import SwiftData
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
    @Environment(Preferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        content
            .background(Color.paper)
            .navigationTitle(model.difficulty.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if model.phase == .playing {
                        Text(PuzzleTimer.format(model.timer.seconds))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Color.inkSoft)
                    }
                }
            }
            .task {
                // Saklamayı kimin yapacağını model bilmiyor; burada bağlanıyor.
                let records = RecordStore(context: modelContext)
                let games = GameStore(context: modelContext)
                let key = GameStore.Key(
                    variant: Runtime.variant,
                    difficulty: model.difficulty,
                    kind: model.kind
                )

                // Yarım kalan oyun varsa üretimden **önce** benimseniyor: tohum da
                // oradan geliyor ve serbest oyunun rastgele tohumu başka bir bulmaca
                // üretirdi.
                if let resumed = try? games.load(Runtime.Move.self, key: key) {
                    model.adopt(resumed)
                }

                model.onChange = { snapshot, seconds in
                    try? games.save(
                        snapshot,
                        key: key,
                        seed: model.seed,
                        seconds: seconds,
                        day: model.kind == .daily ? LocalCalendar.today() : nil
                    )
                }

                model.errorChecking = preferences.errorChecking
                if preferences.isHapticsEnabled {
                    model.onMistakeAppeared = { Haptics.mistake() }
                }

                model.onFinish = { record in
                    // Kayıt yazılamadıysa oyun yine de bitti; oyuncuya bulmacanın
                    // ortasında saklama hatası göstermek kazandırdığından çok götürür.
                    try? records.add(record)
                    if preferences.isHapticsEnabled {
                        Haptics.solved()
                    }
                    // Biten oyunun yarım kalan satırı siliniyor, yoksa ana ekran
                    // bitmiş bulmacayı "devam et" diye gösterirdi.
                    try? games.delete(key)
                }

                await model.start()
            }
            .onChange(of: scenePhase) { _, phase in
                model.setActive(phase == .active)
            }
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
                    SolvedOverlay(
                        hintCount: model.hintCount,
                        shareCard: shareCard,
                        onDismiss: { dismiss() }
                    )
                }
            }
        }
    }

    /// `nil` ise kalem düğmesi çizilmiyor: kalem işareti yalnız rakam yazılan varyantlarda
    /// var (brief b.7).
    private var pencilState: Bool? {
        Runtime.self is any DigitPuzzleRuntime.Type ? model.isPencilMode : nil
    }

    /// Paylaşım kartı yalnız günlük bulmacada. Serbest oyunda paylaşılacak ortak bir şey
    /// yok: kart "aynı bulmacayı sen de çözdün mü" demek için var (brief b.7).
    private var shareCard: ShareCard? {
        guard model.kind == .daily else { return nil }
        return ShareCard(
            variant: Runtime.variant,
            day: LocalCalendar.today(),
            seconds: model.timer.seconds,
            usedHints: model.hintCount > 0
        )
    }
}

/// Bitiş ekranı. Brief b.7: ipucu kullanılan bulmaca "çözüldü" sayılıyor ama ayrı
/// işaretleniyor, bu yüzden ipucu sayısı burada görünüyor.
struct SolvedOverlay: View {
    let hintCount: Int
    var shareCard: ShareCard?
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

                if let shareCard, let image = Self.render(shareCard) {
                    ShareLink(
                        item: image,
                        preview: SharePreview("Daily Puzzle", image: image)
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(minHeight: Metrics.minimumTapTarget)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button("Back to puzzles", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(Metrics.screenPadding)
        }
    }

    /// Kart paylaşılırken görüntüye çevriliyor. Ölçek 3: paylaşılan görsel başka
    /// uygulamalarda büyütülebiliyor ve bulanık bir kart tek yayılma kanalımıza yakışmaz.
    @MainActor
    static func render(_ card: ShareCard) -> Image? {
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }

    private var hintSummary: String {
        switch hintCount {
        case 0: String(localized: "No hints used")
        case 1: String(localized: "1 hint used")
        default: String(localized: "\(hintCount) hints used")
        }
    }
}
