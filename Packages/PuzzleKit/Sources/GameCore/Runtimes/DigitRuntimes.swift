import PuzzleKit

/// Kakuro ve Calcudoku'nun ortak yanı: rakam yazılan hücreler ve kalem işareti. Ayrıldıkları
/// yer komşuluk tanımı — Kakuro'da kesit, Calcudoku'da satır ve sütun.
public enum KakuroRuntime: PuzzleRuntime {
    public typealias Definition = KakuroPuzzle
    public typealias Solution = KakuroSolution
    public typealias Board = KakuroBoard
    public typealias Move = KakuroMove
    public typealias Location = Position

    public static var variant: PuzzleVariantID { .kakuro }

    public static func generate(
        difficulty: Difficulty,
        seed: UInt64
    ) throws -> GeneratedPuzzle<Definition, Solution> {
        try KakuroGenerator.pipeline().generate(difficulty: difficulty, seed: seed)
    }

    public static func emptyBoard(for definition: KakuroPuzzle) -> KakuroBoard {
        KakuroBoard(definition)
    }

    public static func isSolved(_ board: KakuroBoard, in definition: KakuroPuzzle) -> Bool {
        KakuroRules().isSolved(board, in: definition)
    }

    public static func location(of move: KakuroMove) -> Position { move.position }

    public static func mistakes(
        in board: KakuroBoard,
        against solution: KakuroSolution,
        in definition: KakuroPuzzle
    ) -> Set<Position> {
        var result: Set<Position> = []
        for index in definition.entryCells {
            let position = definition.position(of: index)
            guard let value = board.value(at: position) else { continue }
            if value != solution.values[position] {
                result.insert(position)
            }
        }
        return result
    }

    public static func hintMove(
        for board: KakuroBoard,
        toward solution: KakuroSolution,
        in definition: KakuroPuzzle
    ) -> KakuroMove? {
        for index in definition.entryCells {
            let position = definition.position(of: index)
            let target = solution.values[position]
            if board.value(at: position) != target {
                return .writing(target, at: position, on: board)
            }
        }
        return nil
    }

    /// Rakam yazılınca aynı kesitteki hücrelerin adaylarından o rakamı siliyor.
    ///
    /// Rakip analizindeki (PR #10) doğrudan özellik isteği. Bir hücre, kaynak hücreyle en
    /// fazla bir kesidi paylaşabiliyor (biri yatay biri dikey), bu yüzden aynı hücre için
    /// iki hamle üretilmiyor.
    public static func companionMoves(
        after move: KakuroMove,
        on board: KakuroBoard,
        in definition: KakuroPuzzle
    ) -> [KakuroMove] {
        guard let digit = move.next.value, move.previous.value != digit else { return [] }
        let origin = definition.index(of: move.position)
        var moves: [KakuroMove] = []
        for runIndex in definition.runsOfCell[origin] {
            for cell in definition.runs[runIndex].cells where cell != origin {
                let position = definition.position(of: cell)
                if let clear = KakuroMove.clearingCandidate(digit, at: position, on: board) {
                    moves.append(clear)
                }
            }
        }
        return moves
    }
}

public enum CalcudokuRuntime: PuzzleRuntime {
    public typealias Definition = CalcudokuPuzzle
    public typealias Solution = CalcudokuSolution
    public typealias Board = CalcudokuBoard
    public typealias Move = CalcudokuMove
    public typealias Location = Position

    public static var variant: PuzzleVariantID { .calcudoku }

    public static func generate(
        difficulty: Difficulty,
        seed: UInt64
    ) throws -> GeneratedPuzzle<Definition, Solution> {
        try CalcudokuGenerator.pipeline().generate(difficulty: difficulty, seed: seed)
    }

    public static func emptyBoard(for definition: CalcudokuPuzzle) -> CalcudokuBoard {
        CalcudokuBoard(definition)
    }

    public static func isSolved(_ board: CalcudokuBoard, in definition: CalcudokuPuzzle) -> Bool {
        CalcudokuRules().isSolved(board, in: definition)
    }

    public static func location(of move: CalcudokuMove) -> Position { move.position }

    public static func mistakes(
        in board: CalcudokuBoard,
        against solution: CalcudokuSolution,
        in definition: CalcudokuPuzzle
    ) -> Set<Position> {
        var result: Set<Position> = []
        for index in 0..<definition.cellCount {
            let position = definition.position(of: index)
            guard let value = board.value(at: position) else { continue }
            if value != solution.values[position] {
                result.insert(position)
            }
        }
        return result
    }

    public static func hintMove(
        for board: CalcudokuBoard,
        toward solution: CalcudokuSolution,
        in definition: CalcudokuPuzzle
    ) -> CalcudokuMove? {
        for index in 0..<definition.cellCount {
            let position = definition.position(of: index)
            let target = solution.values[position]
            if board.value(at: position) != target {
                return .writing(target, at: position, on: board)
            }
        }
        return nil
    }

    /// Calcudoku'da komşuluk satır ve sütun; `peers` zaten ikisini birlikte veriyor.
    public static func companionMoves(
        after move: CalcudokuMove,
        on board: CalcudokuBoard,
        in definition: CalcudokuPuzzle
    ) -> [CalcudokuMove] {
        guard let digit = move.next.value, move.previous.value != digit else { return [] }
        let origin = definition.index(of: move.position)
        var moves: [CalcudokuMove] = []
        for cell in definition.peers[origin] {
            let position = definition.position(of: cell)
            if let clear = CalcudokuMove.clearingCandidate(digit, at: position, on: board) {
                moves.append(clear)
            }
        }
        return moves
    }
}
