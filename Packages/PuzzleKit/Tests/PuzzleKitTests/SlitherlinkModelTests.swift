import Testing
import PuzzleKit

@Suite("Slitherlink modeli")
struct SlitherlinkModelTests {
    @Test("Kenar ve nokta sayıları ızgaradan türüyor")
    func edgeAndDotCounts() {
        let puzzle = SlitherlinkFixture.block3x3
        // 3×3 hücre → 4×4 nokta, 4×3 yatay + 3×4 dikey kenar.
        #expect(puzzle.dotCount == 16)
        #expect(puzzle.horizontalCount == 12)
        #expect(puzzle.edgeCount == 24)
        #expect(puzzle.cellCount == 9)
    }

    @Test("Hücrenin dört kenarı üst, alt, sol, sağ sırasında")
    func cellEdgesFollowCanonicalOrder() {
        let puzzle = SlitherlinkFixture.block3x3
        let edges = puzzle.edgesOfCell[puzzle.index(of: pos(1, 1))]
        #expect(edges.count == 4)
        #expect(puzzle.isHorizontal(edges[0]), "üst kenar yatay")
        #expect(puzzle.isHorizontal(edges[1]), "alt kenar yatay")
        #expect(!puzzle.isHorizontal(edges[2]), "sol kenar dikey")
        #expect(!puzzle.isHorizontal(edges[3]), "sağ kenar dikey")
        // Üst kenarın alt komşusu, üstteki hücrenin alt kenarı olmalı.
        let above = puzzle.edgesOfCell[puzzle.index(of: pos(0, 1))]
        #expect(above[1] == edges[0])
    }

    @Test("Nokta derecesi konuma göre: köşede 2, kenarda 3, içte 4")
    func dotIncidenceDependsOnPosition() {
        let puzzle = SlitherlinkFixture.block3x3
        let stride = puzzle.size.columns + 1
        #expect(puzzle.edgesOfDot[0].count == 2, "sol üst köşe")
        #expect(puzzle.edgesOfDot[1].count == 3, "üst kenar")
        #expect(puzzle.edgesOfDot[stride + 1].count == 4, "iç nokta")
        #expect(puzzle.edgesOfDot[puzzle.dotCount - 1].count == 2, "sağ alt köşe")
    }

    @Test("Her kenarın iki ucu, o uçların kenar listesinde kenarı içeriyor")
    func endpointsAgreeWithIncidence() {
        let puzzle = SlitherlinkFixture.block3x3
        for edge in 0..<puzzle.edgeCount {
            let ends = puzzle.endpointsOfEdge[edge]
            #expect(ends.first != ends.second)
            #expect(puzzle.edgesOfDot[ends.first].contains(edge))
            #expect(puzzle.edgesOfDot[ends.second].contains(edge))
        }
    }

    @Test("Her kenar tam iki noktaya ait")
    func everyEdgeBelongsToTwoDots() {
        let puzzle = SlitherlinkFixture.block3x3
        let total = puzzle.edgesOfDot.reduce(0) { $0 + $1.count }
        #expect(total == puzzle.edgeCount * 2)
    }

    @Test("İpucu olan hücreler listelenmiş")
    func cluedCellsAreListed() {
        let puzzle = SlitherlinkFixture.ambiguous3x3
        #expect(puzzle.cluedCells == [puzzle.index(of: pos(1, 1))])
        #expect(puzzle.clue(at: puzzle.index(of: pos(1, 1))) == 2)
        #expect(puzzle.clue(at: 0) == nil)
    }

    @Test("İndeks ve konum dönüşümü tersine çevrilebilir")
    func indexAndPositionRoundTrip() {
        let puzzle = SlitherlinkFixture.block3x3
        for position in puzzle.size.allPositions {
            #expect(puzzle.position(of: puzzle.index(of: position)) == position)
        }
    }
}

@Suite("Slitherlink hamle ve geri alma")
struct SlitherlinkMoveTests {
    @Test("Dokunma döngüsü çizgi → çarpı → boş")
    func tapCycleFollowsBrief() {
        let puzzle = SlitherlinkFixture.block3x3
        var board = SlitherlinkBoard(puzzle)

        for expected in [EdgeState.line, .cross, .unknown] {
            let move = SlitherlinkMove.cycling(edge: 0, on: board)
            #expect(move.next == expected)
            move.apply(to: &board)
            #expect(board[0] == expected)
        }
    }

    @Test("apply ve undo simetrik")
    func applyAndUndoAreSymmetric() {
        let puzzle = SlitherlinkFixture.block3x3
        var board = SlitherlinkBoard(puzzle)
        let original = board

        let moves = [
            SlitherlinkMove(edge: 0, previous: .unknown, next: .line),
            SlitherlinkMove(edge: 5, previous: .unknown, next: .cross),
            SlitherlinkMove(edge: 12, previous: .unknown, next: .line)
        ]
        for move in moves { move.apply(to: &board) }
        #expect(board != original)
        for move in moves.reversed() { move.undo(on: &board) }
        #expect(board == original)
    }

    @Test("Hücre çizgi sayısı ve nokta derecesi sayılıyor")
    func countsAreDerivedFromEdges() {
        let puzzle = SlitherlinkFixture.block3x3
        var board = SlitherlinkBoard(puzzle)
        let cell = puzzle.index(of: pos(0, 0))

        #expect(board.lineCount(ofCell: cell, in: puzzle) == 0)
        #expect(board.unknownCount(ofCell: cell, in: puzzle) == 4)

        for edge in puzzle.edgesOfCell[cell].prefix(2) {
            board[edge] = .line
        }
        #expect(board.lineCount(ofCell: cell, in: puzzle) == 2)
        #expect(board.unknownCount(ofCell: cell, in: puzzle) == 2)
        // Üst ve alt kenar sol üst köşeye değmiyor; sol üst köşenin derecesi üst kenardan 1.
        #expect(board.degree(ofDot: 0, in: puzzle) == 1)
    }
}
