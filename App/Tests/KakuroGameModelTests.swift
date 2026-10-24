import Testing
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("Kakuro oyun modeli")
@MainActor
struct KakuroGameModelTests {
    private func started(_ difficulty: Difficulty = .easy, seed: UInt64 = 41) async -> KakuroGameModel {
        let model = KakuroGameModel(difficulty: difficulty, seed: seed)
        await model.start()
        return model
    }

    @Test("Üretim bitince bulmaca oynanabilir")
    func startProducesAPlayablePuzzle() async {
        let model = await started()
        #expect(model.phase == .playing)
        #expect(model.session != nil)
        #expect(!model.isSolved)
        #expect(!model.canUndo)
    }

    @Test("Seçili hücre yokken rakam girilmiyor")
    func digitsNeedASelection() async {
        let model = await started()
        model.enter(5)
        #expect(!model.canUndo)
    }

    @Test("Seçili hücreye rakam yazılıyor ve geri alınabiliyor")
    func digitGoesIntoTheSelectedCell() async throws {
        let model = await started()
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

    // Kalem kipi aynı düğmeleri aday girişine çeviriyor; brief b.7 Kakuro'da kalem
    // işaretini zorunlu tutuyor.
    @Test("Kalem kipinde rakam aday olarak giriliyor")
    func pencilModeWritesCandidates() async throws {
        let model = await started()
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
        let model = await started()
        let session = try #require(model.session)
        let position = session.definition.position(of: session.definition.entryCells[0])

        model.select(position)
        model.enter(3)
        model.erase()
        #expect(model.session?.board.value(at: position) == nil)
    }

    @Test("Kontrol yanlış girişi işaretliyor")
    func checkFlagsAWrongEntry() async throws {
        let model = await started()
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
        let model = await started()
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
        let model = await started()
        let session = try #require(model.session)
        let entries = session.definition.entryCells.count

        for _ in 0..<entries {
            if model.isSolved { break }
            model.hint()
        }

        #expect(model.isSolved)
        #expect(model.hintCount == entries)
    }
}
