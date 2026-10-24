import PuzzleKit

/// Hitori: hücre karalanıyor, rakam yazılmıyor.
public enum HitoriRuntime: PuzzleRuntime {
    public typealias Definition = HitoriPuzzle
    public typealias Solution = HitoriSolution
    public typealias Board = HitoriBoard
    public typealias Move = HitoriMove
    public typealias Location = Position

    public static func emptyBoard(for definition: HitoriPuzzle) -> HitoriBoard {
        HitoriBoard(definition)
    }

    public static func isSolved(_ board: HitoriBoard, in definition: HitoriPuzzle) -> Bool {
        HitoriRules().isSolved(board, in: definition)
    }

    public static func location(of move: HitoriMove) -> Position { move.position }

    /// `unknown` hata değil: oyuncu her beyaz hücreyi ayrıca işaretlemek zorunda değil
    /// (bkz. `HitoriBoard.isWhite`). Hata, karar verilmiş ama çözümle çelişen hücre.
    public static func mistakes(
        in board: HitoriBoard,
        against solution: HitoriSolution,
        in definition: HitoriPuzzle
    ) -> Set<Position> {
        var result: Set<Position> = []
        for position in definition.size.allPositions {
            let state = board[position]
            guard state != .unknown else { continue }
            if (state == .shaded) != solution.shaded[position] {
                result.insert(position)
            }
        }
        return result
    }

    public static func hintMove(
        for board: HitoriBoard,
        toward solution: HitoriSolution,
        in definition: HitoriPuzzle
    ) -> HitoriMove? {
        for position in definition.size.allPositions {
            let target: ShadeState = solution.shaded[position] ? .shaded : .marked
            if board[position] != target {
                return HitoriMove(position: position, previous: board[position], next: target)
            }
        }
        return nil
    }
}

/// Hashi: kenar başına köprü sayısı.
public enum HashiRuntime: PuzzleRuntime {
    public typealias Definition = HashiPuzzle
    public typealias Solution = HashiSolution
    public typealias Board = HashiBoard
    public typealias Move = HashiMove
    public typealias Location = Int

    public static func emptyBoard(for definition: HashiPuzzle) -> HashiBoard {
        HashiBoard(definition)
    }

    public static func isSolved(_ board: HashiBoard, in definition: HashiPuzzle) -> Bool {
        HashiRules().isSolved(board, in: definition)
    }

    public static func location(of move: HashiMove) -> Int { move.edge }

    /// Çözümdekinden **az** köprü hata değil, eksik: oyuncu henüz ikinciyi çekmemiş
    /// olabilir. Fazlası hata, çünkü geri almadan düzelmiyor.
    public static func mistakes(
        in board: HashiBoard,
        against solution: HashiSolution,
        in definition: HashiPuzzle
    ) -> Set<Int> {
        var result: Set<Int> = []
        for edge in 0..<board.edgeCount where board[edge] > solution.counts[edge] {
            result.insert(edge)
        }
        return result
    }

    public static func hintMove(
        for board: HashiBoard,
        toward solution: HashiSolution,
        in definition: HashiPuzzle
    ) -> HashiMove? {
        for edge in 0..<board.edgeCount where board[edge] != solution.counts[edge] {
            return HashiMove(edge: edge, previous: board[edge], next: solution.counts[edge])
        }
        return nil
    }
}

/// Slitherlink: kenar başına çizgi / çarpı / karar verilmedi.
public enum SlitherlinkRuntime: PuzzleRuntime {
    public typealias Definition = SlitherlinkPuzzle
    public typealias Solution = SlitherlinkSolution
    public typealias Board = SlitherlinkBoard
    public typealias Move = SlitherlinkMove
    public typealias Location = Int

    public static func emptyBoard(for definition: SlitherlinkPuzzle) -> SlitherlinkBoard {
        SlitherlinkBoard(definition)
    }

    public static func isSolved(
        _ board: SlitherlinkBoard,
        in definition: SlitherlinkPuzzle
    ) -> Bool {
        SlitherlinkRules().isSolved(board, in: definition)
    }

    public static func location(of move: SlitherlinkMove) -> Int { move.edge }

    /// Çarpı da bir karar: çözümde çizgi olan kenara çarpı koymak hata. `unknown` değil.
    public static func mistakes(
        in board: SlitherlinkBoard,
        against solution: SlitherlinkSolution,
        in definition: SlitherlinkPuzzle
    ) -> Set<Int> {
        var result: Set<Int> = []
        for edge in 0..<board.edges.count {
            let state = board[edge]
            guard state != .unknown else { continue }
            if (state == .line) != solution.lines[edge] {
                result.insert(edge)
            }
        }
        return result
    }

    public static func hintMove(
        for board: SlitherlinkBoard,
        toward solution: SlitherlinkSolution,
        in definition: SlitherlinkPuzzle
    ) -> SlitherlinkMove? {
        for edge in 0..<board.edges.count {
            let target: EdgeState = solution.lines[edge] ? .line : .cross
            if board[edge] != target {
                return SlitherlinkMove(edge: edge, previous: board[edge], next: target)
            }
        }
        return nil
    }
}
