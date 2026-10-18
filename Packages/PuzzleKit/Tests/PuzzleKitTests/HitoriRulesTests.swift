import Testing
import PuzzleKit

@Suite("Hitori kural doğrulayıcı")
struct HitoriRulesTests {
    private let rules = HitoriRules()

    // Hashi'nin tersi: orada kesişen köprü fiziksel imkânsızlıktı ve engelleniyordu.
    // Burada iki komşu hücreyi karalamak mümkün, yalnız yanlış — hatalar violations'ta.
    @Test("Her hamle kurallara uygun, komşu karalama bile")
    func everyMoveIsLegal() {
        let puzzle = HitoriFixture.handmade4x4
        var board = HitoriBoard(puzzle)
        let first = HitoriMove(position: pos(0, 0), previous: .unknown, next: .shaded)
        #expect(rules.isLegal(first, on: board, in: puzzle))
        first.apply(to: &board)

        let adjacent = HitoriMove(position: pos(0, 1), previous: .unknown, next: .shaded)
        #expect(rules.isLegal(adjacent, on: board, in: puzzle))
    }

    @Test("Izgara dışı ve eski değeri tutmayan hamle engelleniyor")
    func invalidMovesAreRejected() {
        let puzzle = HitoriFixture.handmade4x4
        let board = HitoriBoard(puzzle)
        #expect(!rules.isLegal(
            HitoriMove(position: pos(9, 9), previous: .unknown, next: .shaded),
            on: board, in: puzzle
        ))
        #expect(!rules.isLegal(
            HitoriMove(position: pos(0, 0), previous: .shaded, next: .marked),
            on: board, in: puzzle
        ))
    }

    @Test("Komşu karalı hücreler ihlal")
    func adjacentShadedIsReported() {
        let puzzle = HitoriFixture.handmade4x4
        var board = HitoriBoard(puzzle)
        board[pos(0, 0)] = .shaded
        #expect(rules.violations(on: board, in: puzzle).isEmpty)

        board[pos(0, 1)] = .shaded
        let reported = rules.violations(on: board, in: puzzle)
        #expect(reported.contains(pos(0, 0)))
        #expect(reported.contains(pos(0, 1)))
        #expect(rules.hasAdjacentShaded(board, in: puzzle))
    }

    // İki hücreyi *işaretlemek* oyuncunun "ikisi de beyaz kalacak" iddiası; aynı grupta
    // ikisi birden beyaz kalamayacağı için bu kesin hata. Karar verilmemiş hücreler
    // bildirilmiyor: onlar hâlâ karalanabilir.
    @Test("Aynı gruptaki iki işaretli hücre ihlal, karar verilmemişler değil")
    func twoMarkedCellsInGroupAreReported() {
        let puzzle = HitoriFixture.handmade4x4
        var board = HitoriBoard(puzzle)
        #expect(rules.violations(on: board, in: puzzle).isEmpty)

        board[pos(0, 0)] = .marked
        board[pos(0, 2)] = .marked
        let reported = rules.violations(on: board, in: puzzle)
        #expect(reported.contains(pos(0, 0)))
        #expect(reported.contains(pos(0, 2)))
    }

    @Test("Amaçlanan karalama deseni çözüm sayılıyor")
    func intendedShadingIsSolved() {
        let puzzle = HitoriFixture.handmade4x4
        var board = HitoriBoard(puzzle)
        for position in [pos(0, 0), pos(1, 2), pos(3, 3)] {
            board[position] = .shaded
        }
        #expect(rules.isSolved(board, in: puzzle))
        #expect(rules.violations(on: board, in: puzzle).isEmpty)
    }

    @Test("Boş tahta çözüm değil: gruplarda iki beyaz kalıyor")
    func emptyBoardIsNotSolved() {
        let puzzle = HitoriFixture.handmade4x4
        let board = HitoriBoard(puzzle)
        #expect(rules.hasDuplicateWhite(board, in: puzzle))
        #expect(!rules.isSolved(board, in: puzzle))
    }

    @Test("Beyaz bölge kopuksa çözüm değil")
    func disconnectedWhiteRegionIsNotSolved() {
        // Köşeyi beyaz bırakıp iki komşusunu karalamak o köşeyi ayırıyor.
        let puzzle = HitoriFixture.parse("""
        1 2 3
        4 5 6
        7 8 9
        """)
        var board = HitoriBoard(puzzle)
        board[pos(0, 1)] = .shaded
        board[pos(1, 0)] = .shaded
        #expect(!rules.hasDuplicateWhite(board, in: puzzle))
        #expect(!rules.hasAdjacentShaded(board, in: puzzle))
        #expect(!rules.isSolved(board, in: puzzle))

        board[pos(2, 2)] = .marked
        board[pos(0, 2)] = .marked
        board[pos(2, 0)] = .marked
        board[pos(1, 1)] = .marked
        board[pos(1, 2)] = .marked
        board[pos(2, 1)] = .marked
        board[pos(0, 0)] = .marked
        // Tahta tamamlandı ve (0,0) kopuk kaldı: artık kesin hata.
        #expect(board.isComplete)
        #expect(rules.violations(on: board, in: puzzle).contains(pos(0, 0)))
    }
}
