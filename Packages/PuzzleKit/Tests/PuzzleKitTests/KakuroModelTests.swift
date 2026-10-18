import Testing
import PuzzleKit

@Suite("Kakuro modeli")
struct KakuroModelTests {
    @Test("Kesitler ipucu hücrelerinden türetiliyor")
    func runsComeFromClueCells() {
        let puzzle = KakuroFixture.unique2x2
        #expect(puzzle.runs.count == 4)
        #expect(puzzle.entryCount == 4)

        let horizontal = puzzle.runs.filter(\.isHorizontal)
        let vertical = puzzle.runs.filter { !$0.isHorizontal }
        #expect(horizontal.map(\.sum).sorted() == [7, 16])
        #expect(vertical.map(\.sum).sorted() == [8, 15])
        #expect(puzzle.runs.allSatisfy { $0.length == 2 })
    }

    // Tek kesite ait bir giriş hücresi, o yönde tek başına kalmış demek ve o kesit tek
    // hücreli olurdu — rakam doğrudan ipucunda yazılı olurdu, bulmaca değil.
    @Test("Her giriş hücresi bir yatay ve bir dikey kesite ait")
    func everyEntryBelongsToTwoRuns() {
        for puzzle in [KakuroFixture.unique2x2, KakuroFixture.ambiguous3x3] {
            for cell in puzzle.entryCells {
                #expect(puzzle.runsOfCell[cell].count == 2)
            }
        }
    }

    @Test("Izgara ortasındaki ipucu hücreleri de okunuyor")
    func interiorClueCellsAreRead() {
        // unique2x2'de sol sütun ipucu hücreleri ızgaranın kenarında değil.
        let puzzle = KakuroFixture.unique2x2
        #expect(!puzzle.isEntry(puzzle.index(of: pos(1, 1))))
        #expect(puzzle.isEntry(puzzle.index(of: pos(1, 2))))
        let rightSums = puzzle.runs.filter(\.isHorizontal).map(\.sum).sorted()
        #expect(rightSums == [7, 16], "Ortadaki ipucu hücrelerinin yatay toplamları")
    }

    @Test("Toplam uygunluk kontrolü sınırları doğru hesaplıyor")
    func sumFeasibilityKnowsItsBounds() {
        // İki hücrede en küçük 1+2=3, en büyük 8+9=17.
        #expect(!KakuroPuzzle.isSumFeasible(2, length: 2))
        #expect(KakuroPuzzle.isSumFeasible(3, length: 2))
        #expect(KakuroPuzzle.isSumFeasible(17, length: 2))
        #expect(!KakuroPuzzle.isSumFeasible(18, length: 2))
        // Dokuz hücrede tek ihtimal 1+...+9=45.
        #expect(KakuroPuzzle.isSumFeasible(45, length: 9))
        #expect(!KakuroPuzzle.isSumFeasible(44, length: 9))
        #expect(!KakuroPuzzle.isSumFeasible(10, length: 10))
    }

    @Test("Kesit sırası tanımdan deterministik türüyor")
    func runOrderIsDeterministic() {
        #expect(KakuroFixture.unique2x2.runs == KakuroFixture.unique2x2.runs)
        #expect(KakuroFixture.unique2x2 == KakuroFixture.unique2x2)
    }

    @Test("İndeks ve konum dönüşümü tersine çevrilebilir")
    func indexAndPositionRoundTrip() {
        let puzzle = KakuroFixture.ambiguous3x3
        for position in puzzle.size.allPositions {
            #expect(puzzle.position(of: puzzle.index(of: position)) == position)
        }
    }
}

@Suite("Kakuro bileşim tablosu")
struct KakuroCombinationTests {
    // Deneyimli oyuncunun ezbere bildiği tablo; çözücünün asıl tekniği buna dayanıyor.
    @Test("Bilinen bileşimler")
    func knownCombinations() {
        #expect(KakuroCombinations.sets(length: 2, sum: 17) == [DigitSet([8, 9])])
        #expect(KakuroCombinations.sets(length: 3, sum: 24) == [DigitSet([7, 8, 9])])
        #expect(KakuroCombinations.sets(length: 2, sum: 3) == [DigitSet([1, 2])])
        #expect(KakuroCombinations.sets(length: 9, sum: 45) == [DigitSet.all])
    }

    @Test("İmkânsız toplamlar boş dönüyor")
    func impossibleSumsReturnNothing() {
        #expect(KakuroCombinations.sets(length: 2, sum: 2).isEmpty)
        #expect(KakuroCombinations.sets(length: 2, sum: 18).isEmpty)
        #expect(KakuroCombinations.sets(length: 9, sum: 44).isEmpty)
        #expect(KakuroCombinations.sets(length: 10, sum: 20).isEmpty)
    }

    @Test("Her bileşim uzunluk ve toplamı tutuyor")
    func everyCombinationMatchesItsKey() {
        for length in 1...9 {
            for sum in 1...45 {
                for set in KakuroCombinations.sets(length: length, sum: sum) {
                    #expect(set.count == length)
                    #expect(set.reduce(0, +) == sum)
                }
            }
        }
    }

    @Test("Dört hücrede 20 için on bileşim var")
    func fourCellsSumTwentyHasTenCombinations() {
        // Elle sayılabilir: 1289 1379 1469 1478 1568 2369 2378 2459 2468 3458 3467 2567
        let sets = KakuroCombinations.sets(length: 4, sum: 20)
        #expect(sets.count == 12)
        #expect(sets.allSatisfy { $0.count == 4 })
    }
}

@Suite("Kakuro hamle ve kalem işareti")
struct KakuroMoveTests {
    @Test("Kesin değer yazmak adayları silmiyor")
    func writingKeepsCandidates() {
        let puzzle = KakuroFixture.unique2x2
        var board = KakuroBoard(puzzle)
        let position = pos(1, 2)

        KakuroMove.togglingCandidate(1, at: position, on: board).apply(to: &board)
        KakuroMove.togglingCandidate(2, at: position, on: board).apply(to: &board)
        KakuroMove.writing(1, at: position, on: board).apply(to: &board)

        #expect(board[position].value == 1)
        #expect(board[position].candidates == DigitSet([1, 2]))
    }

    @Test("Aday temizleme hamlesi geri alınabilir")
    func clearingCandidateIsUndoable() {
        let puzzle = KakuroFixture.unique2x2
        var board = KakuroBoard(puzzle)
        let position = pos(2, 3)

        KakuroMove.togglingCandidate(9, at: position, on: board).apply(to: &board)
        #expect(KakuroMove.clearingCandidate(5, at: position, on: board) == nil)

        guard let move = KakuroMove.clearingCandidate(9, at: position, on: board) else {
            Issue.record("Aday temizleme hamlesi kurulamadı")
            return
        }
        move.apply(to: &board)
        #expect(board[position].candidates.isEmpty)
        move.undo(on: &board)
        #expect(board[position].candidates == DigitSet([9]))
    }

    @Test("apply ve undo simetrik")
    func applyAndUndoAreSymmetric() {
        let puzzle = KakuroFixture.unique2x2
        var board = KakuroBoard(puzzle)
        let original = board

        var moves: [KakuroMove] = []
        moves.append(KakuroMove.writing(1, at: pos(1, 2), on: board))
        moves[0].apply(to: &board)
        moves.append(KakuroMove.togglingCandidate(6, at: pos(1, 3), on: board))
        moves[1].apply(to: &board)

        #expect(board != original)
        for move in moves.reversed() { move.undo(on: &board) }
        #expect(board == original)
    }
}
