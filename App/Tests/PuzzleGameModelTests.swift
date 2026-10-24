import Testing
import GameCore
import PuzzleKit
@testable import Pencilmark

@MainActor
private func started<Runtime: PuzzleRuntime>(
    _ type: Runtime.Type,
    _ difficulty: Difficulty = .easy,
    seed: UInt64 = 41
) async -> PuzzleGameModel<Runtime> {
    let model = PuzzleGameModel<Runtime>(difficulty: difficulty, seed: seed)
    await model.start()
    return model
}

@Suite("Oyun modeli — ortak davranış")
@MainActor
struct PuzzleGameModelTests {
    @Test("Üretim bitince bulmaca oynanabilir")
    func startProducesAPlayablePuzzle() async {
        let model = await started(KakuroRuntime.self)
        #expect(model.phase == .playing)
        #expect(model.session != nil)
        #expect(!model.isSolved)
        #expect(!model.canUndo)
    }

    @Test("Seçili hücre yokken rakam girilmiyor")
    func digitsNeedASelection() async {
        let model = await started(KakuroRuntime.self)
        model.enter(5)
        #expect(!model.canUndo)
    }

    @Test("Seçili hücreye rakam yazılıyor ve geri alınabiliyor")
    func digitGoesIntoTheSelectedCell() async throws {
        let model = await started(KakuroRuntime.self)
        let session = try #require(model.session)
        let position = session.definition.position(of: session.definition.entryCells[0])

        model.select(position)
        model.enter(5)
        #expect(model.session?.board.value(at: position) == 5)
        #expect(model.canUndo)

        model.undo()
        #expect(model.session?.board.value(at: position) == nil)
        #expect(model.canRedo)
    }

    @Test("Kalem kipinde rakam aday olarak giriliyor")
    func pencilModeWritesCandidates() async throws {
        let model = await started(KakuroRuntime.self)
        let session = try #require(model.session)
        let position = session.definition.position(of: session.definition.entryCells[0])

        model.select(position)
        model.isPencilMode = true
        model.enter(7)

        #expect(model.session?.board.value(at: position) == nil)
        #expect(model.session?.board[position].candidates.contains(7) == true)
    }

    @Test("Silgi hücreyi boşaltıyor")
    func eraseClearsTheValue() async throws {
        let model = await started(KakuroRuntime.self)
        let session = try #require(model.session)
        let position = session.definition.position(of: session.definition.entryCells[0])

        model.select(position)
        model.enter(3)
        model.erase()
        #expect(model.session?.board.value(at: position) == nil)
    }

    @Test("Kontrol yanlış girişi işaretliyor")
    func checkFlagsAWrongEntry() async throws {
        let model = await started(KakuroRuntime.self)
        let session = try #require(model.session)
        let position = session.definition.position(of: session.definition.entryCells[0])
        let correct = session.solution.values[position]

        model.select(position)
        model.enter(correct == 9 ? 1 : correct + 1)
        #expect(model.session?.mistakes.isEmpty == true)

        model.check()
        #expect(model.session?.mistakes.contains(position) == true)
    }

    @Test("İpucu seçimi açılan hücreye taşıyor")
    func hintMovesTheSelection() async throws {
        let model = await started(KakuroRuntime.self)
        model.hint()
        let session = try #require(model.session)
        let selection = try #require(session.selection)
        #expect(session.board.value(at: selection) == session.solution.values[selection])
        #expect(model.hintCount == 1)
    }

    // Ekranın "çözüldü" durumunu tanıması tek bir yere bağlı: `GameSession.isSolved`.
    // Burada bulmacayı ipucuyla bitirip o geçişin gerçekten olduğunu doğruluyoruz.
    @Test("Bulmaca bitince model çözüldü diyor")
    func completionIsRecognised() async throws {
        let model = await started(KakuroRuntime.self)
        let session = try #require(model.session)
        let entries = session.definition.entryCells.count

        for _ in 0..<entries where !model.isSolved {
            model.hint()
        }

        #expect(model.isSolved)
        #expect(model.hintCount == entries)
    }
}

@Suite("Oyun modeli — varyanta özel giriş")
@MainActor
struct VariantInputTests {
    // Calcudoku'nun rakam aralığı ızgara kenarı kadar; Kakuro'da her zaman 1-9. Rakam
    // çubuğu bu aralığı kullanıyor, yani yanlış olursa oyuncu olmayan bir rakamı
    // yazabiliyor.
    @Test("Calcudoku rakam aralığı ızgara kenarı kadar")
    func calcudokuDigitsFollowTheGridSide() async throws {
        let model = await started(CalcudokuRuntime.self)
        let session = try #require(model.session)
        #expect(model.digits == 1...session.definition.side)
    }

    @Test("Kakuro rakam aralığı her zaman 1-9")
    func kakuroDigitsAreAlwaysOneToNine() async {
        let model = await started(KakuroRuntime.self)
        #expect(model.digits == 1...9)
    }

    @Test("Hitori dokunuşu karala → işaretle → boş döngüsünde çeviriyor")
    func hitoriCyclesThroughShadeStates() async throws {
        let model = await started(HitoriRuntime.self)
        let session = try #require(model.session)
        let position = Position(row: 0, column: 0)

        #expect(session.board[position] == .unknown)
        model.cycle(at: position)
        #expect(model.session?.board[position] == .shaded)
        model.cycle(at: position)
        #expect(model.session?.board[position] == .marked)
        model.cycle(at: position)
        #expect(model.session?.board[position] == .unknown)
    }

    @Test("Slitherlink dokunuşu çizgi → çarpı → boş döngüsünde çeviriyor")
    func slitherlinkCyclesThroughEdgeStates() async throws {
        let model = await started(SlitherlinkRuntime.self)
        let session = try #require(model.session)

        #expect(session.board[0] == .unknown)
        model.cycle(at: 0)
        #expect(model.session?.board[0] == .line)
        model.cycle(at: 0)
        #expect(model.session?.board[0] == .cross)
        model.cycle(at: 0)
        #expect(model.session?.board[0] == .unknown)
    }

    // Kapasitesi 2 olan kenarda döngü 0 → 1 → 2 → 0; kapasitesi 1 olanda 0 → 1 → 0.
    @Test("Hashi dokunuşu köprü sayısını döndürüyor")
    func hashiCyclesBridgeCounts() async throws {
        let model = await started(HashiRuntime.self)
        let session = try #require(model.session)
        let edge = try #require(session.definition.edges.firstIndex { $0.capacity == 2 })

        model.cycle(at: edge)
        #expect(model.session?.board[edge] == 1)
        model.cycle(at: edge)
        #expect(model.session?.board[edge] == 2)
        model.cycle(at: edge)
        #expect(model.session?.board[edge] == 0)
    }

    @Test("Döngü hamlesi geri alınabiliyor")
    func cyclingIsUndoable() async throws {
        let model = await started(SlitherlinkRuntime.self)
        model.cycle(at: 0)
        model.undo()
        #expect(model.session?.board[0] == .unknown)
    }

    // Her varyantın `generate` uyarlaması kendi hattına gidiyor; beşini birden
    // sınamak, bir varyantın yanlış hatta bağlanmasını yakalayan en ucuz test.
    @Test("Beş varyant da üretiliyor", arguments: PuzzleVariantID.allCases)
    func everyVariantGenerates(variant: PuzzleVariantID) async {
        switch variant {
        case .kakuro:
            let model = await started(KakuroRuntime.self)
            #expect(model.phase == .playing)
        case .calcudoku:
            let model = await started(CalcudokuRuntime.self)
            #expect(model.phase == .playing)
        case .hitori:
            let model = await started(HitoriRuntime.self)
            #expect(model.phase == .playing)
        case .slitherlink:
            let model = await started(SlitherlinkRuntime.self)
            #expect(model.phase == .playing)
        case .hashi:
            let model = await started(HashiRuntime.self)
            #expect(model.phase == .playing)
        }
    }
}
