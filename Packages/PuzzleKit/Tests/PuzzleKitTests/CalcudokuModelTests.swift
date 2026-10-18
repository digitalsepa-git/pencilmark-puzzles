import Testing
import PuzzleKit

@Suite("Calcudoku modeli")
struct CalcudokuModelTests {
    @Test("Kafes hedefi dört işlemde de doğru değerlendiriliyor")
    func cageSatisfactionCoversEveryOperation() {
        #expect(CalcudokuCage(cells: [0], target: 3, operation: .given).isSatisfied(by: [3]))
        #expect(!CalcudokuCage(cells: [0], target: 3, operation: .given).isSatisfied(by: [2]))

        let sum = CalcudokuCage(cells: [0, 1, 2], target: 9, operation: .add)
        #expect(sum.isSatisfied(by: [2, 3, 4]))
        #expect(!sum.isSatisfied(by: [2, 3, 3]))

        let product = CalcudokuCage(cells: [0, 1], target: 12, operation: .multiply)
        #expect(product.isSatisfied(by: [3, 4]))
        #expect(!product.isSatisfied(by: [3, 3]))

        let difference = CalcudokuCage(cells: [0, 1], target: 3, operation: .subtract)
        #expect(difference.isSatisfied(by: [1, 4]))
        #expect(difference.isSatisfied(by: [4, 1]), "Çıkarma sıraya duyarlı olmamalı")

        let quotient = CalcudokuCage(cells: [0, 1], target: 4, operation: .divide)
        #expect(quotient.isSatisfied(by: [1, 4]))
        #expect(quotient.isSatisfied(by: [4, 1]), "Bölme sıraya duyarlı olmamalı")
        #expect(!quotient.isSatisfied(by: [3, 4]), "Tam bölünmeyen değerler geçmemeli")
    }

    @Test("Kafes hücreleri kanonik sırada tutuluyor")
    func cageCellsAreSorted() {
        // Aynı tohumun aynı bulmacayı vermesi kafes sırasının kararlı olmasına bağlı.
        let cage = CalcudokuCage(cells: [7, 3, 5], target: 9, operation: .add)
        #expect(cage.cells == [3, 5, 7])
    }

    @Test("Komşu listesi satır ve sütunu kapsıyor, hücrenin kendisini kapsamıyor")
    func peersCoverRowAndColumn() {
        let puzzle = CalcudokuFixture.handmade4x4
        let cell = puzzle.index(of: pos(1, 2))
        // 4×4'te satırda 3, sütunda 3 komşu.
        #expect(puzzle.peers[cell].count == 6)
        #expect(!puzzle.peers[cell].contains(cell))
        #expect(puzzle.peers[cell].contains(puzzle.index(of: pos(1, 0))))
        #expect(puzzle.peers[cell].contains(puzzle.index(of: pos(3, 2))))
        #expect(!puzzle.peers[cell].contains(puzzle.index(of: pos(0, 0))))
    }

    @Test("İndeks ve konum dönüşümü tersine çevrilebilir")
    func indexAndPositionRoundTrip() {
        let puzzle = CalcudokuFixture.handmade4x4
        for position in puzzle.size.allPositions {
            #expect(puzzle.position(of: puzzle.index(of: position)) == position)
        }
    }

    @Test("Her hücre tam bir kafese ait")
    func everyCellBelongsToOneCage() {
        let puzzle = CalcudokuFixture.handmade4x4
        #expect(puzzle.cageOfCell.count == puzzle.cellCount)
        #expect(!puzzle.cageOfCell.contains(-1))
        let covered = puzzle.cages.flatMap(\.cells).sorted()
        #expect(covered == Array(0..<puzzle.cellCount))
    }

    // Kuralların gereği değil ama kafesin ekranda tek bir çerçeve olarak çizilebilmesi
    // için şart: bağlı olmayan bir kafes oyuncuya iki ayrı kafes gibi görünür.
    @Test("Bağlılık kontrolü kopuk kafesi yakalıyor")
    func connectivityCheckRejectsSplitCage() {
        #expect(CalcudokuPuzzle.isConnected([0, 1, 5], side: 4))
        #expect(CalcudokuPuzzle.isConnected([0, 4, 8], side: 4))
        #expect(!CalcudokuPuzzle.isConnected([0, 2], side: 4))
        #expect(!CalcudokuPuzzle.isConnected([0, 15], side: 4))
    }

    @Test("İşlem simgeleri ve iki hücre kısıtı")
    func operationMetadata() {
        #expect(CageOperation.add.symbol == "+")
        #expect(CageOperation.multiply.symbol == "×")
        #expect(CageOperation.given.symbol.isEmpty)
        #expect(CageOperation.subtract.requiresExactlyTwoCells)
        #expect(CageOperation.divide.requiresExactlyTwoCells)
        #expect(!CageOperation.add.requiresExactlyTwoCells)
    }
}

@Suite("Calcudoku hamle ve kalem işareti")
struct CalcudokuMoveTests {
    @Test("Kesin değer yazmak adayları silmiyor")
    func writingKeepsCandidates() {
        let puzzle = CalcudokuFixture.handmade4x4
        var board = CalcudokuBoard(puzzle)
        let position = pos(1, 1)

        CalcudokuMove.togglingCandidate(2, at: position, on: board).apply(to: &board)
        CalcudokuMove.togglingCandidate(3, at: position, on: board).apply(to: &board)
        #expect(board[position].candidates == DigitSet([2, 3]))

        CalcudokuMove.writing(3, at: position, on: board).apply(to: &board)
        #expect(board[position].value == 3)
        // Kullanıcı kesin değeri geri alıp adaylara dönmeyi bekliyor.
        #expect(board[position].candidates == DigitSet([2, 3]))
    }

    @Test("Kalem işareti ekleyip çıkarma")
    func toggleAddsAndRemovesCandidate() {
        let puzzle = CalcudokuFixture.handmade4x4
        var board = CalcudokuBoard(puzzle)
        let position = pos(0, 0)

        CalcudokuMove.togglingCandidate(4, at: position, on: board).apply(to: &board)
        #expect(board[position].candidates.contains(4))
        CalcudokuMove.togglingCandidate(4, at: position, on: board).apply(to: &board)
        #expect(!board[position].candidates.contains(4))
    }

    @Test("Silme değeri kaldırıyor, adayları bırakıyor")
    func erasingKeepsCandidates() {
        let puzzle = CalcudokuFixture.handmade4x4
        var board = CalcudokuBoard(puzzle)
        let position = pos(2, 2)

        CalcudokuMove.togglingCandidate(1, at: position, on: board).apply(to: &board)
        CalcudokuMove.writing(1, at: position, on: board).apply(to: &board)
        CalcudokuMove.erasing(at: position, on: board).apply(to: &board)
        #expect(board[position].value == nil)
        #expect(board[position].candidates == DigitSet([1]))
    }

    // Rakip analizindeki (PR #10) doğrudan özellik isteği: satır/sütunda bir rakam
    // kullanılınca adaylar kendiliğinden güncellenmeli. Geri alınabilir olması için
    // hamle olarak modellendi.
    @Test("Aday temizleme hamlesi geri alınabilir, yoksa nil dönüyor")
    func clearingCandidateIsUndoable() {
        let puzzle = CalcudokuFixture.handmade4x4
        var board = CalcudokuBoard(puzzle)
        let position = pos(3, 3)

        CalcudokuMove.togglingCandidate(2, at: position, on: board).apply(to: &board)
        #expect(CalcudokuMove.clearingCandidate(4, at: position, on: board) == nil)

        guard let move = CalcudokuMove.clearingCandidate(2, at: position, on: board) else {
            Issue.record("Aday temizleme hamlesi kurulamadı")
            return
        }
        move.apply(to: &board)
        #expect(board[position].candidates.isEmpty)
        move.undo(on: &board)
        #expect(board[position].candidates == DigitSet([2]))
    }

    @Test("apply ve undo simetrik")
    func applyAndUndoAreSymmetric() {
        let puzzle = CalcudokuFixture.handmade4x4
        var board = CalcudokuBoard(puzzle)
        let original = board

        var moves: [CalcudokuMove] = []
        moves.append(CalcudokuMove.writing(1, at: pos(0, 0), on: board))
        moves[0].apply(to: &board)
        moves.append(CalcudokuMove.togglingCandidate(3, at: pos(1, 1), on: board))
        moves[1].apply(to: &board)
        moves.append(CalcudokuMove.writing(4, at: pos(2, 3), on: board))
        moves[2].apply(to: &board)

        #expect(board != original)
        for move in moves.reversed() { move.undo(on: &board) }
        #expect(board == original)
    }
}
