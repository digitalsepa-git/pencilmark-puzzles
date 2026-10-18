import Testing
import PuzzleKit

@Suite("Hitori modeli")
struct HitoriModelTests {
    @Test("Gruplar aynı satır ve sütundaki tekrarlardan kuruluyor")
    func groupsComeFromRowAndColumnDuplicates() {
        let puzzle = HitoriFixture.parse("""
        1 2 1
        3 4 5
        1 6 7
        """)
        // Satır 0'da iki tane 1, sütun 0'da iki tane 1 → iki grup.
        #expect(puzzle.groups.count == 2)
        let sizes = puzzle.groups.map(\.count).sorted()
        #expect(sizes == [2, 2])
    }

    @Test("Tek üyeli gruplar tutulmuyor")
    func singletonGroupsAreDropped() {
        let puzzle = HitoriFixture.parse("""
        1 2
        3 4
        """)
        #expect(puzzle.groups.isEmpty)
    }

    @Test("Hücre → grup eşlemesi en fazla iki grup veriyor")
    func cellBelongsToAtMostTwoGroups() {
        let puzzle = HitoriFixture.handmade4x4
        let counts = puzzle.groupsOfCell.map(\.count)
        #expect(counts.allSatisfy { $0 <= 2 })
        // (0,0) hem satırında hem sütununda tekrar ediyor.
        #expect(puzzle.groupsOfCell[puzzle.index(of: pos(0, 0))].count == 2)
    }

    @Test("Komşuluk listesi ızgara sınırında kırpılıyor")
    func neighborsAreClippedAtBorder() {
        let puzzle = HitoriFixture.parse("""
        1 2 3
        4 5 6
        7 8 9
        """)
        #expect(puzzle.neighbors[puzzle.index(of: pos(0, 0))].count == 2)
        #expect(puzzle.neighbors[puzzle.index(of: pos(1, 1))].count == 4)
        #expect(puzzle.neighbors[puzzle.index(of: pos(2, 1))].count == 3)
    }

    @Test("İndeks ve konum dönüşümü tersine çevrilebilir")
    func indexAndPositionRoundTrip() {
        let puzzle = HitoriFixture.handmade4x4
        for position in puzzle.size.allPositions {
            #expect(puzzle.position(of: puzzle.index(of: position)) == position)
        }
    }

    @Test("Grup sırası tanımdan deterministik türüyor")
    func groupOrderIsDeterministic() {
        // Aynı tohumun aynı bulmacayı vermesi grup indekslerinin kararlı olmasına bağlı.
        #expect(HitoriFixture.handmade4x4.groups == HitoriFixture.handmade4x4.groups)
        #expect(HitoriFixture.handmade4x4 == HitoriFixture.handmade4x4)
    }
}

@Suite("Hitori hamle ve geri alma")
struct HitoriMoveTests {
    @Test("Dokunma döngüsü karala → işaretle → boş")
    func tapCycleFollowsBrief() {
        let puzzle = HitoriFixture.handmade4x4
        var board = HitoriBoard(puzzle)
        let position = pos(1, 1)

        for expected in [ShadeState.shaded, .marked, .unknown] {
            let move = HitoriMove.cycling(at: position, on: board)
            #expect(move.next == expected)
            move.apply(to: &board)
            #expect(board[position] == expected)
        }
    }

    @Test("apply ve undo simetrik")
    func applyAndUndoAreSymmetric() {
        let puzzle = HitoriFixture.handmade4x4
        var board = HitoriBoard(puzzle)
        let original = board

        let moves = [
            HitoriMove(position: pos(0, 0), previous: .unknown, next: .shaded),
            HitoriMove(position: pos(1, 2), previous: .unknown, next: .shaded),
            HitoriMove(position: pos(2, 1), previous: .unknown, next: .marked)
        ]
        for move in moves { move.apply(to: &board) }
        #expect(board != original)
        for move in moves.reversed() { move.undo(on: &board) }
        #expect(board == original)
    }

    // Oyuncu yalnız karalayarak bitirebiliyor; her beyaz hücreyi ayrıca işaretlemek
    // zorunda değil. `marked` oyuncunun kendi notu, kuralların gereği değil.
    @Test("Karar verilmemiş hücre beyaz sayılıyor")
    func unknownCountsAsWhite() {
        let puzzle = HitoriFixture.handmade4x4
        var board = HitoriBoard(puzzle)
        #expect(board.isWhite(at: pos(0, 1)))
        #expect(!board.isComplete)

        board[pos(0, 1)] = .shaded
        #expect(!board.isWhite(at: pos(0, 1)))
        board[pos(0, 1)] = .marked
        #expect(board.isWhite(at: pos(0, 1)))
    }
}
