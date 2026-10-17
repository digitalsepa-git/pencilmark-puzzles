import Testing
import PuzzleKit

@Suite("Hashi modeli")
struct HashiModelTests {
    @Test("Kenarlar yalnızca komşu ada çiftleri arasında kuruluyor")
    func edgesConnectOnlyAdjacentIslands() {
        // Aynı satırda üç ada: 1-2 ve 2-3 kenar var, 1-3 yok (araya ada giriyor).
        let puzzle = HashiFixture.parse("1 . 2 . 1")
        #expect(puzzle.edges.count == 2)
        #expect(puzzle.islands.count == 3)

        let left = HashiFixture.edge(puzzle, from: pos(0, 0), to: pos(0, 2))
        let right = HashiFixture.edge(puzzle, from: pos(0, 2), to: pos(0, 4))
        #expect(left != right)
        let allHorizontal = puzzle.edges.allSatisfy(\.isHorizontal)
        #expect(allHorizontal)
    }

    @Test("Kapasite en küçük dereceye göre kısıtlanıyor")
    func capacityIsLimitedBySmallestDegree() {
        let puzzle = HashiFixture.parse("1 . 3")
        #expect(puzzle.edges.count == 1)
        // Derecesi 1 olan adaya ikinci köprü çekilemez.
        #expect(puzzle.edges[0].capacity == 1)

        let wide = HashiFixture.parse("3 . 4")
        #expect(wide.edges[0].capacity == 2)
    }

    @Test("Kesişen kenar çiftleri tespit ediliyor")
    func crossingEdgesAreDetected() {
        let puzzle = HashiFixture.crossing5x5
        #expect(puzzle.edges.count == 2)
        #expect(puzzle.crossingEdges[0] == [1])
        #expect(puzzle.crossingEdges[1] == [0])
    }

    @Test("Kesişmeyen kenarlar kesişim listesinde yok")
    func parallelEdgesDoNotCross() {
        let puzzle = HashiFixture.loop3x3
        #expect(puzzle.edges.count == 4)
        let noCrossings = puzzle.crossingEdges.allSatisfy(\.isEmpty)
        #expect(noCrossings)
    }

    @Test("Komşuluk listesi her kenarı iki adaya bağlıyor")
    func incidenceCoversEveryEdgeTwice() {
        let puzzle = HashiFixture.loop3x3
        let total = puzzle.incidentEdges.reduce(0) { $0 + $1.count }
        #expect(total == puzzle.edges.count * 2)
        let everyIslandHasTwoEdges = puzzle.incidentEdges.allSatisfy { $0.count == 2 }
        #expect(everyIslandHasTwoEdges)
    }

    @Test("Kenar sırası tanımdan deterministik türüyor")
    func edgeOrderIsDeterministic() {
        // Aynı tohumun aynı bulmacayı vermesi kenar indekslerinin kararlı olmasına bağlı.
        let first = HashiFixture.loop3x3
        let second = HashiFixture.loop3x3
        #expect(first.edges == second.edges)
        #expect(first == second)
    }

    @Test("otherIsland kenarın diğer ucunu veriyor")
    func otherIslandReturnsOppositeEnd() {
        let puzzle = HashiFixture.parse("2 . 2")
        let edge = 0
        #expect(puzzle.otherIsland(of: edge, than: puzzle.edges[edge].a) == puzzle.edges[edge].b)
        #expect(puzzle.otherIsland(of: edge, than: puzzle.edges[edge].b) == puzzle.edges[edge].a)
    }
}

@Suite("Hashi hamle ve geri alma")
struct HashiMoveTests {
    @Test("Dokunma döngüsü 0 → 1 → 2 → 0")
    func tapCycleGoesUpThenClears() {
        let puzzle = HashiFixture.loop3x3
        var board = HashiBoard(puzzle)
        let edge = 0

        for expected in [1, 2, 0] {
            let move = HashiMove.cycling(edge: edge, on: board, in: puzzle)
            #expect(move.next == expected)
            move.apply(to: &board)
            #expect(board[edge] == expected)
        }
    }

    @Test("Kapasitesi 1 olan kenarda döngü 0 → 1 → 0")
    func cycleRespectsCapacity() {
        let puzzle = HashiFixture.parse("1 . 3")
        var board = HashiBoard(puzzle)

        HashiMove.cycling(edge: 0, on: board, in: puzzle).apply(to: &board)
        #expect(board[0] == 1)
        HashiMove.cycling(edge: 0, on: board, in: puzzle).apply(to: &board)
        #expect(board[0] == 0)
    }

    @Test("apply ve undo simetrik")
    func applyAndUndoAreSymmetric() {
        let puzzle = HashiFixture.loop3x3
        var board = HashiBoard(puzzle)
        let original = board

        let moves = [
            HashiMove(edge: 0, previous: 0, next: 2),
            HashiMove(edge: 1, previous: 0, next: 1),
            HashiMove(edge: 2, previous: 0, next: 1)
        ]
        for move in moves { move.apply(to: &board) }
        #expect(board != original)
        for move in moves.reversed() { move.undo(on: &board) }
        #expect(board == original)
    }

    @Test("Derece komşu kenarların toplamı")
    func degreeSumsIncidentEdges() {
        let puzzle = HashiFixture.loop3x3
        var board = HashiBoard(puzzle)
        let corner = puzzle.island(at: pos(0, 0))!

        #expect(board.degree(ofIsland: corner, in: puzzle) == 0)
        for edge in puzzle.incidentEdges[corner] {
            board[edge] = 1
        }
        #expect(board.degree(ofIsland: corner, in: puzzle) == 2)
    }
}
