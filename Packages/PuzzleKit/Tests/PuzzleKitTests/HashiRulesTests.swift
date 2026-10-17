import Testing
import PuzzleKit

@Suite("Hashi kural doğrulayıcı")
struct HashiRulesTests {
    private let rules = HashiRules()

    @Test("Kesişen köprü engelleniyor")
    func crossingBridgeIsIllegal() {
        let puzzle = HashiFixture.crossing5x5
        var board = HashiBoard(puzzle)

        let first = HashiMove(edge: 0, previous: 0, next: 1)
        #expect(rules.isLegal(first, on: board, in: puzzle))
        first.apply(to: &board)

        // İkinci kenar birinciyle kesişiyor: iki köprü aynı hücreden geçemez.
        let second = HashiMove(edge: 1, previous: 0, next: 1)
        #expect(!rules.isLegal(second, on: board, in: puzzle))
    }

    @Test("Kapasite aşan hamle engelleniyor")
    func exceedingCapacityIsIllegal() {
        let puzzle = HashiFixture.parse("1 . 3")
        let board = HashiBoard(puzzle)
        #expect(!rules.isLegal(HashiMove(edge: 0, previous: 0, next: 2), on: board, in: puzzle))
        #expect(rules.isLegal(HashiMove(edge: 0, previous: 0, next: 1), on: board, in: puzzle))
    }

    @Test("Eski değeri tutmayan hamle engelleniyor")
    func staleMoveIsIllegal() {
        let puzzle = HashiFixture.loop3x3
        let board = HashiBoard(puzzle)
        #expect(!rules.isLegal(HashiMove(edge: 0, previous: 2, next: 1), on: board, in: puzzle))
    }

    // Adaya gereğinden fazla köprü çekmek kurallara uygun ama yanlış: engellenmiyor,
    // hata kontrolünde gösteriliyor. Oyunun kendisi bu.
    @Test("Adaya fazla köprü çekmek kurallara uygun, ama ihlal olarak görünüyor")
    func overfillingIsLegalButReported() {
        let puzzle = HashiFixture.parse("""
        2 . 2
        . . .
        2 . 2
        """)
        var board = HashiBoard(puzzle)
        let top = HashiFixture.edge(puzzle, from: pos(0, 0), to: pos(0, 2))
        let left = HashiFixture.edge(puzzle, from: pos(0, 0), to: pos(2, 0))

        let move = HashiMove(edge: top, previous: 0, next: 2)
        #expect(rules.isLegal(move, on: board, in: puzzle))
        move.apply(to: &board)
        #expect(rules.violations(on: board, in: puzzle).isEmpty)

        HashiMove(edge: left, previous: 0, next: 1).apply(to: &board)
        // Sol üst adanın derecesi artık 3, gereken 2.
        #expect(rules.violations(on: board, in: puzzle).contains(pos(0, 0)))
    }

    @Test("Dereceler tam ama ağ kopuksa ihlal bildiriliyor")
    func disconnectedCompleteNetworkIsReported() {
        let puzzle = HashiFixture.loop3x3
        var board = HashiBoard(puzzle)
        let top = HashiFixture.edge(puzzle, from: pos(0, 0), to: pos(0, 2))
        let bottom = HashiFixture.edge(puzzle, from: pos(2, 0), to: pos(2, 2))

        board[top] = 2
        board[bottom] = 2

        // Bütün adaların derecesi tam, kesişim yok — ama iki ayrı ağ var.
        #expect(rules.degreesAreComplete(board, in: puzzle))
        #expect(!rules.hasCrossing(board, in: puzzle))
        #expect(!rules.isSolved(board, in: puzzle))
        let reported = rules.violations(on: board, in: puzzle)
        #expect(reported.count == 2)
        #expect(reported.contains(pos(2, 0)))
        #expect(reported.contains(pos(2, 2)))
    }

    @Test("Eksik köprü ihlal değil, tamamlanmamışlık")
    func incompleteBoardHasNoViolations() {
        let puzzle = HashiFixture.loop3x3
        var board = HashiBoard(puzzle)
        board[0] = 1
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
        #expect(!rules.isSolved(board, in: puzzle))
    }

    @Test("Kare döngü çözüm sayılıyor")
    func squareLoopIsSolved() {
        let puzzle = HashiFixture.loop3x3
        var board = HashiBoard(puzzle)
        for edge in puzzle.edges.indices {
            board[edge] = 1
        }
        #expect(rules.isSolved(board, in: puzzle))
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
    }

    @Test("Boş tahta çözüm değil")
    func emptyBoardIsNotSolved() {
        let puzzle = HashiFixture.loop3x3
        #expect(!rules.isSolved(HashiBoard(puzzle), in: puzzle))
    }

    @Test("Tek adadan oluşan ağda gezinme kendisini buluyor")
    func reachabilityFromIsolatedIsland() {
        let puzzle = HashiFixture.loop3x3
        let board = HashiBoard(puzzle)
        #expect(rules.reachableIslands(from: 0, on: board, in: puzzle) == [0])
    }
}
