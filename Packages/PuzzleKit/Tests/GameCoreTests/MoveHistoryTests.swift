import Testing
import PuzzleKit
import GameCore

// Yığının işi hamlenin ne olduğundan bağımsız; en küçük gerçek hamle tipi yeterli.
private struct Write: PuzzleMove {
    typealias Board = [Int?]

    let cell: Int
    let previous: Int?
    let next: Int?

    func apply(to board: inout [Int?]) { board[cell] = next }
    func undo(on board: inout [Int?]) { board[cell] = previous }
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

    @Test("Geri alma son öbeği veriyor")
    func undoReturnsTheLastGroup() {
        var history = MoveHistory<Write>()
        history.record([Write(cell: 0, previous: nil, next: 5)])
        history.record([Write(cell: 1, previous: nil, next: 7)])

        #expect(history.undo()?.first?.cell == 1)
        #expect(history.undo()?.first?.cell == 0)
        #expect(history.undo() == nil)
    }

    @Test("Boş öbek kaydedilmiyor")
    func emptyGroupIsNotRecorded() {
        var history = MoveHistory<Write>()
        history.record([])
        #expect(!history.canUndo)
        #expect(history.actionCount == 0)
    }

    @Test("İleri alma geri alınan öbeği tekrar veriyor")
    func redoReturnsTheUndoneGroup() {
        var history = MoveHistory<Write>()
        history.record([Write(cell: 3, previous: 9, next: 2)])

        #expect(history.undo() != nil)
        #expect(history.canRedo)
        #expect(history.redo()?.first?.next == 2)
        #expect(!history.canRedo)
        #expect(history.canUndo)
    }

    // Brief b.7 geri almayı sınırsız istiyor ama ileri almanın ne zaman geçersizleştiğini
    // söylemiyor. Standart davranış bu: geri alıp farklı bir hamle yapmak eski ileri dalını
    // ulaşılamaz kılıyor, dolayısıyla saklamak yanıltıcı olur.
    @Test("Yeni öbek ileri yığınını temizliyor")
    func recordingClearsTheRedoStack() {
        var history = MoveHistory<Write>()
        history.record([Write(cell: 0, previous: nil, next: 1)])
        _ = history.undo()
        #expect(history.canRedo)

        history.record([Write(cell: 5, previous: nil, next: 4)])
        #expect(!history.canRedo)
        #expect(history.actionCount == 1)
    }

    @Test("Geri alma sınırsız")
    func undoIsUnlimited() {
        var history = MoveHistory<Write>()
        for cell in 0..<5_000 {
            history.record([Write(cell: cell, previous: nil, next: 1)])
        }
        #expect(history.actionCount == 5_000)

        var undone = 0
        while history.undo() != nil { undone += 1 }
        #expect(undone == 5_000)
    }
}
