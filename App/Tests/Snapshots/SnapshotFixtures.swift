import PuzzleKit

/// Anlık görüntülerin bulmacaları elle kurulu, üreticiden alınmıyor.
///
/// Sebebi izolasyon: üreticiden sabit tohumla bulmaca alsaydık, üretici algoritmasındaki
/// her değişiklik bütün arayüz referanslarını geçersiz kılardı. O zaman kırmızı bir anlık
/// görüntü testi "çizim bozuldu" mu "üretici değişti" mi söyleyemezdi. Burada yalnız çizim
/// sınanıyor.
enum SnapshotFixtures {
    /// 5×5, ortada 3×3 giriş bloğu. Kesit toplamları tutarlı:
    /// satırlar 13-11-12, sütunlar 7-6-23, ikisi de 36.
    static func kakuro() -> (puzzle: KakuroPuzzle, board: KakuroBoard) {
        var cells = Grid(size: GridSize(square: 5), repeating: KakuroCell.clue(down: nil, right: nil))
        cells[Position(row: 0, column: 1)] = .clue(down: 7, right: nil)
        cells[Position(row: 0, column: 2)] = .clue(down: 6, right: nil)
        cells[Position(row: 0, column: 3)] = .clue(down: 23, right: nil)
        cells[Position(row: 1, column: 0)] = .clue(down: nil, right: 13)
        cells[Position(row: 2, column: 0)] = .clue(down: nil, right: 11)
        cells[Position(row: 3, column: 0)] = .clue(down: nil, right: 12)
        for row in 1...3 {
            for column in 1...3 {
                cells[Position(row: row, column: column)] = .entry
            }
        }
        let puzzle = KakuroPuzzle(cells: cells)

        // Üç durum birden görünüyor: kesin değer, kalem işaretleri ve boş hücre.
        var board = KakuroBoard(puzzle)
        board[Position(row: 1, column: 1)] = DigitCell(value: 4)
        board[Position(row: 1, column: 2)] = DigitCell(value: 3)
        board[Position(row: 2, column: 1)] = DigitCell(value: nil, candidates: DigitSet([1, 2, 8]))
        board[Position(row: 3, column: 3)] = DigitCell(value: 9)
        return (puzzle, board)
    }

    /// 4×4, sekiz kafes; beş işlemin dördü temsil ediliyor.
    static func calcudoku() -> (puzzle: CalcudokuPuzzle, board: CalcudokuBoard) {
        let cages = [
            CalcudokuCage(cells: [0, 1], target: 5, operation: .add),
            CalcudokuCage(cells: [2, 3], target: 2, operation: .subtract),
            CalcudokuCage(cells: [4, 8], target: 7, operation: .add),
            CalcudokuCage(cells: [5, 6, 7], target: 24, operation: .multiply),
            CalcudokuCage(cells: [9, 10], target: 2, operation: .divide),
            CalcudokuCage(cells: [11, 15], target: 6, operation: .add),
            CalcudokuCage(cells: [12, 13], target: 5, operation: .add),
            CalcudokuCage(cells: [14], target: 3, operation: .given)
        ]
        let puzzle = CalcudokuPuzzle(side: 4, cages: cages)

        var board = CalcudokuBoard(puzzle)
        board[Position(row: 0, column: 0)] = DigitCell(value: 2)
        board[Position(row: 1, column: 1)] = DigitCell(value: nil, candidates: DigitSet([1, 3, 4]))
        board[Position(row: 3, column: 2)] = DigitCell(value: 3)
        return (puzzle, board)
    }

    /// 5×5; karalı, işaretli ve kararsız hücreler birlikte.
    static func hitori() -> (puzzle: HitoriPuzzle, board: HitoriBoard) {
        let rows = [
            [1, 3, 2, 5, 4],
            [4, 1, 1, 3, 2],
            [2, 5, 3, 4, 1],
            [3, 2, 5, 1, 5],
            [5, 4, 4, 2, 3]
        ]
        var values = Grid(size: GridSize(square: 5), repeating: 0)
        for (row, line) in rows.enumerated() {
            for (column, value) in line.enumerated() {
                values[Position(row: row, column: column)] = value
            }
        }
        let puzzle = HitoriPuzzle(values: values)

        var board = HitoriBoard(puzzle)
        board[Position(row: 1, column: 2)] = .shaded
        board[Position(row: 3, column: 4)] = .shaded
        board[Position(row: 0, column: 0)] = .marked
        board[Position(row: 4, column: 1)] = .marked
        return (puzzle, board)
    }

    /// 4×4 hücre, yani 5×5 nokta. Çizgi, çarpı ve kararsız kenar birlikte.
    static func slitherlink() -> (puzzle: SlitherlinkPuzzle, board: SlitherlinkBoard) {
        var clues = Grid<Int?>(size: GridSize(square: 4), repeating: nil)
        clues[Position(row: 0, column: 0)] = 3
        clues[Position(row: 0, column: 2)] = 1
        clues[Position(row: 1, column: 1)] = 2
        clues[Position(row: 2, column: 3)] = 0
        clues[Position(row: 3, column: 0)] = 2
        clues[Position(row: 3, column: 2)] = 3
        let puzzle = SlitherlinkPuzzle(clues: clues)

        var board = SlitherlinkBoard(puzzle)
        // Sol üst hücrenin üç kenarı çizgi, sağ kenarı çarpı: ipucu 3'ün okunabilir hali.
        let edges = puzzle.edgesOfCell[0]
        board[edges[0]] = .line
        board[edges[1]] = .line
        board[edges[2]] = .line
        board[edges[3]] = .cross
        return (puzzle, board)
    }

    /// 5×5 ızgarada altı ada; tek ve çift köprü birlikte.
    static func hashi() -> (puzzle: HashiPuzzle, board: HashiBoard) {
        let islands = [
            HashiIsland(position: Position(row: 0, column: 0), required: 3),
            HashiIsland(position: Position(row: 0, column: 2), required: 2),
            HashiIsland(position: Position(row: 0, column: 4), required: 2),
            HashiIsland(position: Position(row: 2, column: 0), required: 2),
            HashiIsland(position: Position(row: 2, column: 2), required: 1),
            HashiIsland(position: Position(row: 4, column: 4), required: 1)
        ]
        let puzzle = HashiPuzzle(size: GridSize(square: 5), islands: islands)

        var board = HashiBoard(puzzle)
        if let edge = puzzle.edges.firstIndex(where: { $0.a == 0 && $0.b == 1 }) {
            board[edge] = 2
        }
        if let edge = puzzle.edges.firstIndex(where: { $0.a == 0 && $0.b == 3 }) {
            board[edge] = 1
        }
        return (puzzle, board)
    }
}
