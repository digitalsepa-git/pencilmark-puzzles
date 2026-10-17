import PuzzleKit

// Test amaçlı oyuncak varyant: n×n Latin karesi, bazı hücreleri verilmiş.
//
// Beş gerçek varyanttan hiçbiri değil ve ürüne girmiyor. İşi, üretim hattının
// (üret → çöz → benzersiz mi → ele/ver) gerçek bir varyant yazılmadan önce
// uçtan uca doğrulanmasını sağlamak. Faz 1'de Hashi geldiğinde bu dosya kalacak:
// hat değişirse en hızlı geri bildirimi burası veriyor.

struct MiniLatinDefinition: Sendable, Hashable {
    let side: Int
    let givens: Grid<Int?>

    var givenCount: Int { givens.elements.count { $0 != nil } }
}

struct MiniLatinSolver: PuzzleSolver {
    typealias Definition = MiniLatinDefinition
    typealias Solution = Grid<Int>

    func findSolutions(of definition: MiniLatinDefinition, upTo limit: Int) throws -> [Grid<Int>] {
        var board = Grid(size: definition.givens.size, repeating: 0)
        for position in board.allPositions {
            board[position] = definition.givens[position] ?? 0
        }
        var found: [Grid<Int>] = []
        search(&board, side: definition.side, index: 0, limit: limit, found: &found)
        return found
    }

    // Oyuncak varyantta derecelendirme verilen hücre sayısından türüyor; gerçek
    // varyantlarda çözücünün kullandığı teknik seviyesinden türeyecek (brief b.6).
    func trace(of definition: MiniLatinDefinition) throws -> SolveTrace {
        var trace = SolveTrace()
        let tier: TechniqueTier
        switch definition.givenCount {
        case 11...: tier = .basic
        case 10: tier = .intermediate
        case 9: tier = .advanced
        default: tier = .guessing
        }
        trace.record("givenCount", tier: tier)
        return trace
    }

    private func search(
        _ board: inout Grid<Int>,
        side: Int,
        index: Int,
        limit: Int,
        found: inout [Grid<Int>]
    ) {
        guard found.count < limit else { return }
        guard index < side * side else {
            found.append(board)
            return
        }
        let position = Position(row: index / side, column: index % side)
        guard board[position] == 0 else {
            search(&board, side: side, index: index + 1, limit: limit, found: &found)
            return
        }
        for value in 1...side where isAvailable(value, at: position, on: board, side: side) {
            board[position] = value
            search(&board, side: side, index: index + 1, limit: limit, found: &found)
            board[position] = 0
            if found.count >= limit { return }
        }
    }

    private func isAvailable(_ value: Int, at position: Position, on board: Grid<Int>, side: Int) -> Bool {
        for c in 0..<side where c != position.column && board[position.row, c] == value {
            return false
        }
        for r in 0..<side where r != position.row && board[r, position.column] == value {
            return false
        }
        return true
    }
}

struct MiniLatinGenerator: PuzzleGenerator {
    typealias Definition = MiniLatinDefinition
    typealias Solution = Grid<Int>

    let variant: PuzzleVariantID = .calcudoku
    let solver = MiniLatinSolver()
    let side: Int

    init(side: Int = 4) {
        self.side = side
    }

    func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> MiniLatinDefinition {
        let full = randomLatinSquare(using: &rng)
        var givens = full.map { Optional($0) }
        var positions = givens.allPositions
        positions.shuffle(using: &rng)
        for position in positions.prefix(removalCount(for: difficulty)) {
            givens[position] = nil
        }
        return MiniLatinDefinition(side: side, givens: givens)
    }

    // Kaldırılan hücre sayısı MiniLatinSolver.trace'teki eşiklerle eşleşmek zorunda;
    // eşleşmezse hat her adayı "yanlış zorluk" diye eler ve denemeler tükenir.
    private func removalCount(for difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy: 5
        case .medium: 6
        case .hard: 7
        case .expert: 8
        }
    }

    private func randomLatinSquare(using rng: inout SeededGenerator) -> Grid<Int> {
        var rowOrder = Array(0..<side)
        var columnOrder = Array(0..<side)
        var symbols = Array(1...side)
        rowOrder.shuffle(using: &rng)
        columnOrder.shuffle(using: &rng)
        symbols.shuffle(using: &rng)

        var grid = Grid(size: GridSize(square: side), repeating: 0)
        for r in 0..<side {
            for c in 0..<side {
                let base = (rowOrder[r] + columnOrder[c]) % side
                grid[r, c] = symbols[base]
            }
        }
        return grid
    }
}

/// Her zaman çok çözümlü aday üreten bozuk üretici.
///
/// Hattın karar adımının gerçekten kapı olduğunu kanıtlamak için var: bu üreticiyle
/// hat asla bulmaca döndürmemeli, denemeleri tüketip hata atmalı.
struct AmbiguousGenerator: PuzzleGenerator {
    typealias Definition = MiniLatinDefinition
    typealias Solution = Grid<Int>

    let variant: PuzzleVariantID = .calcudoku
    let solver = MiniLatinSolver()

    func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> MiniLatinDefinition {
        // Tamamen boş 4×4: 576 Latin karesi çözüm olarak geçerli.
        MiniLatinDefinition(side: 4, givens: Grid(size: GridSize(square: 4), repeating: nil))
    }
}
