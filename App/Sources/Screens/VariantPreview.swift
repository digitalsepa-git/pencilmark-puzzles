import GameCore
import PuzzleKit
import SwiftUI

/// Ana ekrandaki mini ızgara: bulmacanın kendini çizmesi (ADR 0027).
///
/// Oyuncu listeye baktığında beş adın ne demek olduğunu bilmiyor. En kısa anlatım
/// ızgaranın kendisi: küçük bir tahta, sakin bir tempoyla doluyor. Ses yok, rozet yok,
/// kazanılan bir şey yok — anlatım var (brief b.7'nin sakin tonu).
///
/// Izgaralar **elle hazırlanmış öğretici senaryoları**. Üretilmiş bulmaca göstermek beş
/// üretim demekti ve açılışa saniyeler eklerdi (#78); bu ızgaralar sabit veri.
struct VariantPreview: View {
    let variant: PuzzleVariantID
    /// Kapalıyken önizleme çözülmüş hâlde duruyor. Anlık görüntü testleri ve
    /// "Hareketi Azalt" aynı kareyi istiyor.
    var isAnimated = true

    var body: some View {
        switch variant {
        case .kakuro:
            PreviewBoard(scenario: TutorialScenarios.kakuro(), isAnimated: isAnimated) { session in
                KakuroGridView(puzzle: session.definition, board: session.board)
            }
        case .calcudoku:
            PreviewBoard(scenario: TutorialScenarios.calcudoku(), isAnimated: isAnimated) { session in
                CalcudokuGridView(puzzle: session.definition, board: session.board)
            }
        case .hitori:
            PreviewBoard(scenario: TutorialScenarios.hitori(), isAnimated: isAnimated) { session in
                HitoriGridView(puzzle: session.definition, board: session.board)
            }
        case .slitherlink:
            PreviewBoard(scenario: TutorialScenarios.slitherlink(), isAnimated: isAnimated) { session in
                SlitherlinkGridView(puzzle: session.definition, board: session.board)
            }
        case .hashi:
            PreviewBoard(scenario: TutorialScenarios.hashi(), isAnimated: isAnimated) { session in
                HashiGridView(puzzle: session.definition, board: session.board)
            }
        }
    }
}

/// Önizlemenin ortak iskeleti: oturumu kurar, adım adım açar, başa sarar.
private struct PreviewBoard<Runtime: PuzzleRuntime, Content: View>: View {
    let scenario: TutorialScenario<Runtime>
    let isAnimated: Bool
    @ViewBuilder let grid: (GameSession<Runtime>) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: GameSession<Runtime>

    /// Başlangıç durumu **senkron** kuruluyor: `ImageRenderer` görevleri çalıştırmıyor,
    /// yani anlık görüntü testlerinde boş bir kutu kalırdı. Oynamayan önizleme de
    /// doğrudan çözülmüş hâlde başlıyor.
    init(
        scenario: TutorialScenario<Runtime>,
        isAnimated: Bool,
        @ViewBuilder grid: @escaping (GameSession<Runtime>) -> Content
    ) {
        self.scenario = scenario
        self.isAnimated = isAnimated
        self.grid = grid

        var session = GameSession<Runtime>(
            definition: scenario.definition, solution: scenario.solution
        )
        if !isAnimated {
            Self.solve(&session)
        }
        _session = State(initialValue: session)
    }

    var body: some View {
        grid(session)
        .frame(width: Metrics.previewSize, height: Metrics.previewSize)
        // Hashi'nin adaları ızgara kutusunun dışına taşabiliyor; beş önizleme aynı
        // alanı kaplamalı, yoksa liste düzensiz görünüyor.
        .clipped()
        // Izgara görünümlerinin kendi dokunma işleyicisi var; önizleme satırın
        // dokunmasını yutmamalı.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: reduceMotion) { await play() }
    }

    /// Bulmacayı açan döngü.
    ///
    /// Açılan yeri `revealHint` seçiyor — ipucu düğmesiyle aynı kod, belirlenimci sırayla
    /// ilk boş yeri dolduruyor. Slitherlink'te bu kenar kenar, Kakuro'da hücre hücre
    /// demek; yani "nasıl oynanır" sorusunun cevabı zaten o sırada.
    ///
    /// `.task` görünüm ekrandan çıkınca iptal ediliyor, yani listede görünmeyen satır
    /// çizim yapmıyor.
    private func play() async {
        var run = GameSession<Runtime>(definition: scenario.definition, solution: scenario.solution)

        guard isAnimated, !reduceMotion else {
            // Hareketi azaltılmış cihazda hareket yok: çözülmüş hâl duruyor.
            Self.solve(&run)
            session = run
            return
        }

        session = run
        for _ in 0..<Metrics.previewCycles {
            while !run.isSolved {
                guard await sleep(Metrics.previewStep) else { return }
                _ = run.revealHint()
                withAnimation(.easeOut(duration: Metrics.previewFade)) { session = run }
            }
            guard await sleep(Metrics.previewHold) else { return }
            run = GameSession<Runtime>(definition: scenario.definition, solution: scenario.solution)
            withAnimation(.easeOut(duration: Metrics.previewFade)) { session = run }
        }

        // Son turdan sonra çözülmüş hâlde duruyor: ekran sonsuza kadar oynamıyor.
        Self.solve(&run)
        withAnimation(.easeOut(duration: Metrics.previewFade)) { session = run }
    }

    /// Tahtayı çözüme kadar açıyor. `revealHint` boş dönerse duruyor: açacak yer
    /// kalmadığında sonsuz döngüye girmesin.
    private static func solve(_ session: inout GameSession<Runtime>) {
        while !session.isSolved, session.revealHint() != nil {}
    }

    /// İptal edilirse `false`; döngü o zaman sessizce çıkıyor.
    private func sleep(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds))
            return true
        } catch {
            return false
        }
    }
}
