import Foundation
import Testing
import PuzzleKit
import GameCore

@Suite("Oturum anlık hali")
struct GameSnapshotTests {
    private func session() throws -> GameSession<KakuroRuntime> {
        let puzzle = try KakuroGenerator.pipeline().generate(difficulty: .easy, seed: 77)
        return GameSession<KakuroRuntime>(
            definition: puzzle.definition,
            solution: puzzle.solution
        )
    }

    @Test("Boş oturumun anlık hali boş")
    func freshSessionSnapshotIsEmpty() throws {
        let session = try session()
        #expect(session.snapshot.hintCount == 0)
        #expect(!session.snapshot.history.canUndo)
    }

    @Test("Anlık hal tahtayı geri getiriyor")
    func snapshotRestoresTheBoard() throws {
        var original = try session()
        let definition = original.definition
        let first = definition.position(of: definition.entryCells[0])
        let second = definition.position(of: definition.entryCells[1])

        original.perform(.writing(4, at: first, on: original.board))
        original.perform(.togglingCandidate(7, at: second, on: original.board))

        let restored = GameSession<KakuroRuntime>(
            definition: definition,
            solution: original.solution,
            snapshot: original.snapshot
        )

        #expect(restored.board == original.board)
    }

    // Brief b.7 geri almayı "bulmaca oturumu boyunca kalıcı" istiyor; uygulamayı kapatıp
    // açmak o oturumu bitirmiyor. Tahta saklansaydı geri alma yığını kaybolurdu.
    @Test("Geri alma yığını anlık halde korunuyor")
    func undoStackSurvivesTheSnapshot() throws {
        var original = try session()
        let definition = original.definition
        let position = definition.position(of: definition.entryCells[0])
        original.perform(.writing(4, at: position, on: original.board))
        original.perform(.writing(6, at: position, on: original.board))

        var restored = GameSession<KakuroRuntime>(
            definition: definition,
            solution: original.solution,
            snapshot: original.snapshot
        )

        #expect(restored.board.value(at: position) == 6)
        #expect(restored.canUndo)
        let undone = restored.undo()
        #expect(undone)
        #expect(restored.board.value(at: position) == 4)
    }

    @Test("İleri alma yığını da korunuyor")
    func redoStackSurvivesTheSnapshot() throws {
        var original = try session()
        let definition = original.definition
        let position = definition.position(of: definition.entryCells[0])
        original.perform(.writing(4, at: position, on: original.board))
        _ = original.undo()

        var restored = GameSession<KakuroRuntime>(
            definition: definition,
            solution: original.solution,
            snapshot: original.snapshot
        )

        #expect(restored.canRedo)
        let redone = restored.redo()
        #expect(redone)
        #expect(restored.board.value(at: position) == 4)
    }

    @Test("İpucu sayacı korunuyor")
    func hintCountSurvivesTheSnapshot() throws {
        var original = try session()
        _ = original.revealHint()
        _ = original.revealHint()

        let restored = GameSession<KakuroRuntime>(
            definition: original.definition,
            solution: original.solution,
            snapshot: original.snapshot
        )
        #expect(restored.hintCount == 2)
    }

    // Saklama katmanı anlık hali JSON olarak yazıyor; tur burada sınanıyor ki saklama
    // testlerinde kodlamanın değil yalnız yazma/okumanın sınanması yetsin.
    @Test("JSON turu kayıpsız", arguments: [Difficulty.easy, .medium])
    func snapshotSurvivesJSON(difficulty: Difficulty) throws {
        let puzzle = try KakuroGenerator.pipeline().generate(difficulty: difficulty, seed: 88)
        var original = GameSession<KakuroRuntime>(
            definition: puzzle.definition,
            solution: puzzle.solution
        )
        for index in puzzle.definition.entryCells.prefix(5) {
            let position = puzzle.definition.position(of: index)
            original.perform(.writing(3, at: position, on: original.board))
        }
        _ = original.undo()

        let data = try JSONEncoder().encode(original.snapshot)
        let decoded = try JSONDecoder().decode(
            GameSnapshot<KakuroMove>.self, from: data
        )
        let restored = GameSession<KakuroRuntime>(
            definition: puzzle.definition,
            solution: puzzle.solution,
            snapshot: decoded
        )

        #expect(restored.board == original.board)
        #expect(restored.canUndo == original.canUndo)
        #expect(restored.canRedo == original.canRedo)
    }

    @Test("Beş varyantın hamlesi de kodlanabiliyor")
    func everyVariantMoveEncodes() throws {
        let encoder = JSONEncoder()
        _ = try encoder.encode(KakuroMove(position: Position(row: 0, column: 0),
                                          previous: .empty, next: DigitCell(value: 3)))
        _ = try encoder.encode(CalcudokuMove(position: Position(row: 1, column: 1),
                                             previous: .empty, next: DigitCell(value: 2)))
        _ = try encoder.encode(HitoriMove(position: Position(row: 2, column: 2),
                                          previous: .unknown, next: .shaded))
        _ = try encoder.encode(SlitherlinkMove(edge: 4, previous: .unknown, next: .line))
        _ = try encoder.encode(HashiMove(edge: 5, previous: 0, next: 2))
    }
}

@Suite("Anlık hal maliyeti")
struct GameSnapshotCostTests {
    private func history(moves: Int) -> MoveHistory<KakuroMove> {
        var history = MoveHistory<KakuroMove>()
        for index in 0..<moves {
            history.record([
                KakuroMove(
                    position: Position(row: index % 12, column: index % 12),
                    previous: .empty,
                    next: DigitCell(value: index % 9 + 1)
                )
            ])
        }
        return history
    }

    // Otomatik kayıt her hamlede (brief b.7) ve her kayıt bütün geçmişi yeniden
    // kodluyor. Uzun bir oturumun maliyeti bu testle görünür kalıyor.
    @Test("Uzun geçmiş makul boyutta kodlanıyor")
    func longHistoryEncodesToReasonableSize() throws {
        let snapshot = GameSnapshot(history: history(moves: 500), hintCount: 0)
        let start = ContinuousClock.now
        let data = try JSONEncoder().encode(snapshot)
        let elapsed = ContinuousClock.now - start

        print("[anlık hal] 500 hamle: \(data.count) bayt, \(elapsed)")
        // 500 hamle gerçekçi bir üst sınırın üstünde; bir Expert Kakuro'da 59 giriş var.
        #expect(data.count < 200_000)

        let decoded = try JSONDecoder().decode(GameSnapshot<KakuroMove>.self, from: data)
        #expect(decoded.history.actionCount == 500)
    }
}
