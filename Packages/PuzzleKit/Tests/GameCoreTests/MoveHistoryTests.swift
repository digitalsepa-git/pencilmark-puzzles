import Testing
import GameCore

// Hamleleri temsil etmek için en basit tip: bir hücreye yazılan değer. Gerçek varyant
// hamleleri GameCore'a oyun oturumuyla birlikte gelecek (#35); yığının işi hamlenin ne
// olduğundan bağımsız.
private struct Write: Sendable, Equatable {
    let cell: Int
    let value: Int?
}

@Suite("Geri alma yığını")
struct MoveHistoryTests {
    @Test("Boş yığında geri ve ileri alma yok")
    func emptyHistoryHasNothingToUndo() {
        var history = MoveHistory<Write>()
        #expect(!history.canUndo)
        #expect(!history.canRedo)
        #expect(history.undo() == nil)
        #expect(history.redo() == nil)
    }

    @Test("Geri alma son hamlenin tersini veriyor")
    func undoReturnsTheInverseOfTheLastMove() {
        var history = MoveHistory<Write>()
        history.record(forward: Write(cell: 0, value: 5), backward: Write(cell: 0, value: nil))
        history.record(forward: Write(cell: 1, value: 7), backward: Write(cell: 1, value: nil))

        #expect(history.undo() == Write(cell: 1, value: nil))
        #expect(history.undo() == Write(cell: 0, value: nil))
        #expect(history.undo() == nil)
    }

    @Test("İleri alma geri alınan hamleyi tekrar veriyor")
    func redoReturnsTheUndoneMove() {
        var history = MoveHistory<Write>()
        history.record(forward: Write(cell: 3, value: 2), backward: Write(cell: 3, value: 9))

        #expect(history.undo() == Write(cell: 3, value: 9))
        #expect(history.canRedo)
        #expect(history.redo() == Write(cell: 3, value: 2))
        #expect(!history.canRedo)
        #expect(history.canUndo)
    }

    // Brief b.7 geri almayı sınırsız istiyor ama ileri almanın ne zaman geçersizleştiğini
    // söylemiyor. Standart davranış bu: geri alıp farklı bir hamle yapmak eski ileri dalını
    // ulaşılamaz kılıyor, dolayısıyla saklamak yanıltıcı olur.
    @Test("Yeni hamle ileri yığınını temizliyor")
    func recordingClearsTheRedoStack() {
        var history = MoveHistory<Write>()
        history.record(forward: Write(cell: 0, value: 1), backward: Write(cell: 0, value: nil))
        _ = history.undo()
        #expect(history.canRedo)

        history.record(forward: Write(cell: 5, value: 4), backward: Write(cell: 5, value: nil))
        #expect(!history.canRedo)
        #expect(history.moveCount == 1)
    }

    @Test("Geri alma sınırsız")
    func undoIsUnlimited() {
        var history = MoveHistory<Write>()
        for cell in 0..<5_000 {
            history.record(
                forward: Write(cell: cell, value: 1),
                backward: Write(cell: cell, value: nil)
            )
        }
        #expect(history.moveCount == 5_000)

        var undone = 0
        while history.undo() != nil { undone += 1 }
        #expect(undone == 5_000)
    }
}
