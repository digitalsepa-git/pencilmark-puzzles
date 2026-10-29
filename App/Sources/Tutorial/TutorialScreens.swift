import GameCore
import PuzzleKit
import SwiftUI

/// Varyantın öğreticisi (ADR 0009).
///
/// Beş ekran da aynı kalıpta: senaryoyu bir `TutorialRun`'a veriyor, ızgarayı çiziyor ve
/// dokunuşu hamleye çeviriyor. Üretim hattı hiçbirinde yok — senaryolar sabit veri.
struct TutorialScreen: View {
    let variant: PuzzleVariantID
    let onFinish: () -> Void

    var body: some View {
        switch variant {
        case .kakuro: KakuroTutorial(onFinish: onFinish)
        case .calcudoku: CalcudokuTutorial(onFinish: onFinish)
        case .hitori: HitoriTutorial(onFinish: onFinish)
        case .slitherlink: SlitherlinkTutorial(onFinish: onFinish)
        case .hashi: HashiTutorial(onFinish: onFinish)
        }
    }
}

private struct KakuroTutorial: View {
    let onFinish: () -> Void
    @State private var run = TutorialRun(scenario: TutorialScenarios.kakuro())
    @State private var selection: Position?

    var body: some View {
        chrome(run: $run, onFinish: onFinish) {
            VStack(spacing: 12) {
                KakuroGridView(
                    puzzle: run.scenario.definition,
                    board: run.session.board,
                    selection: selection,
                    onTapEntry: { selection = $0 }
                )
                NumberPad(
                    digits: 1...9,
                    isPencilMode: false,
                    isEnabled: selection != nil,
                    onDigit: { digit in
                        guard let selection else { return }
                        run.perform(.writing(digit, at: selection, on: run.session.board))
                    },
                    onErase: {
                        guard let selection else { return }
                        run.perform(.erasing(at: selection, on: run.session.board))
                    }
                )
            }
        }
    }
}

private struct CalcudokuTutorial: View {
    let onFinish: () -> Void
    @State private var run = TutorialRun(scenario: TutorialScenarios.calcudoku())
    @State private var selection: Position?

    var body: some View {
        chrome(run: $run, onFinish: onFinish) {
            VStack(spacing: 12) {
                CalcudokuGridView(
                    puzzle: run.scenario.definition,
                    board: run.session.board,
                    selection: selection,
                    onTapCell: { selection = $0 }
                )
                NumberPad(
                    digits: 1...run.scenario.definition.side,
                    isPencilMode: false,
                    isEnabled: selection != nil,
                    onDigit: { digit in
                        guard let selection else { return }
                        run.perform(.writing(digit, at: selection, on: run.session.board))
                    },
                    onErase: {
                        guard let selection else { return }
                        run.perform(.erasing(at: selection, on: run.session.board))
                    }
                )
            }
        }
    }
}

private struct HitoriTutorial: View {
    let onFinish: () -> Void
    @State private var run = TutorialRun(scenario: TutorialScenarios.hitori())

    var body: some View {
        chrome(run: $run, onFinish: onFinish) {
            HitoriGridView(
                puzzle: run.scenario.definition,
                board: run.session.board,
                onTapCell: { position in
                    run.perform(.cycling(at: position, on: run.session.board))
                }
            )
        }
    }
}

private struct SlitherlinkTutorial: View {
    let onFinish: () -> Void
    @State private var run = TutorialRun(scenario: TutorialScenarios.slitherlink())

    var body: some View {
        chrome(run: $run, onFinish: onFinish) {
            SlitherlinkGridView(
                puzzle: run.scenario.definition,
                board: run.session.board,
                onTapEdge: { edge in
                    run.perform(.cycling(edge: edge, on: run.session.board))
                }
            )
        }
    }
}

private struct HashiTutorial: View {
    let onFinish: () -> Void
    @State private var run = TutorialRun(scenario: TutorialScenarios.hashi())

    var body: some View {
        chrome(run: $run, onFinish: onFinish) {
            HashiGridView(
                puzzle: run.scenario.definition,
                board: run.session.board,
                onTapEdge: { edge in
                    run.perform(
                        .cycling(
                            edge: edge,
                            on: run.session.board,
                            in: run.scenario.definition
                        )
                    )
                }
            )
        }
    }
}

/// Beş ekranın ortak sarmalayıcısı.
@MainActor
private func chrome<Runtime: PuzzleRuntime, Content: View>(
    run: Binding<TutorialRun<Runtime>>,
    onFinish: @escaping () -> Void,
    @ViewBuilder grid: () -> Content
) -> some View {
    TutorialChrome(
        stepNumber: run.wrappedValue.stepNumber,
        stepCount: run.wrappedValue.stepCount,
        text: run.wrappedValue.isFinished
            ? ""
            : TutorialCopy.text(for: Runtime.variant, step: run.wrappedValue.stepIndex),
        correction: run.wrappedValue.isCorrecting
            ? TutorialCopy.correction(for: Runtime.variant)
            : nil,
        isFinished: run.wrappedValue.isFinished,
        onUndo: { run.wrappedValue.undo() },
        onSkip: onFinish,
        onDone: onFinish,
        grid: grid
    )
}
