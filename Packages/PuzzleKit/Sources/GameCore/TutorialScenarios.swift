import PuzzleKit

/// Beş varyantın öğretici senaryoları (ADR 0009).
///
/// Izgaralar burada **sabit veri**. Hiçbiri çalışma anında üretilmiyor —
/// `GenerationPipeline` bu dosyada geçmiyor ve geçmemeli: öğretici belirli bir çıkarımı
/// belirli bir sırada göstermek zorunda, üretilmiş bulmaca bunu garanti etmiyor.
/// Benzersizlikleri `TutorialScenarioTests` içinde çözücüyle doğrulanıyor.
public enum TutorialScenarios {
    // MARK: - Kakuro

    /// 3×3: dört giriş hücresi, dört adım. Toplamlar tek bir dolgu bırakacak şekilde
    /// seçildi (3 ve 17 iki hücrede yalnız 1+2 ve 8+9 ile yapılıyor).
    public static func kakuro() -> TutorialScenario<KakuroRuntime> {
        var cells = Grid(
            size: GridSize(square: 3),
            repeating: KakuroCell.clue(down: nil, right: nil)
        )
        cells[Position(row: 0, column: 1)] = .clue(down: 9, right: nil)
        cells[Position(row: 0, column: 2)] = .clue(down: 11, right: nil)
        cells[Position(row: 1, column: 0)] = .clue(down: nil, right: 3)
        cells[Position(row: 2, column: 0)] = .clue(down: nil, right: 17)
        for row in 1...2 {
            for column in 1...2 {
                cells[Position(row: row, column: column)] = .entry
            }
        }

        var values = Grid(size: GridSize(square: 3), repeating: 0)
        values[Position(row: 1, column: 1)] = 1
        values[Position(row: 1, column: 2)] = 2
        values[Position(row: 2, column: 1)] = 8
        values[Position(row: 2, column: 2)] = 9

        func filled(_ row: Int, _ column: Int) -> @Sendable (KakuroBoard) -> Bool {
            { $0.value(at: Position(row: row, column: column)) != nil }
        }
        let wrong = "That doesn't fit the sums. Tap Undo and try another digit."

        return TutorialScenario(
            definition: KakuroPuzzle(cells: cells),
            solution: KakuroSolution(values: values),
            steps: [
                TutorialStep(
                    text: "White cells take 1 to 9. The 3 on the left is the sum of this row,"
                        + " and the 9 above is the sum of this column.",
                    correction: wrong,
                    isComplete: filled(1, 1)
                ),
                TutorialStep(
                    text: "Digits never repeat inside one sum, so the rest of this row is"
                        + " the only digit left.",
                    correction: wrong,
                    isComplete: filled(1, 2)
                ),
                TutorialStep(
                    text: "The bottom row adds up to 17. With two cells, only 8 and 9 do that.",
                    correction: wrong,
                    isComplete: filled(2, 1)
                ),
                TutorialStep(
                    text: "One cell left — the column sums tell you which digit goes where.",
                    correction: wrong,
                    isComplete: filled(2, 2)
                )
            ]
        )
    }

    // MARK: - Calcudoku

    /// 4×4. Kafes düzeni sabit veri; elle kurduğum düzenlerin hiçbiri benzersiz
    /// çıkmadığı için bu ızgara bir kez üreticiden alınıp kaynağa donduruldu. Adım sırası
    /// yine elde: ızgara sabit olduğu sürece hangi çıkarımın ne zaman gösterileceğine
    /// buradaki adımlar karar veriyor.
    public static func calcudoku() -> TutorialScenario<CalcudokuRuntime> {
        let cages = [
            CalcudokuCage(cells: [0, 1], target: 7, operation: .add),
            CalcudokuCage(cells: [2, 3], target: 2, operation: .multiply),
            CalcudokuCage(cells: [4], target: 2, operation: .given),
            CalcudokuCage(cells: [5, 6], target: 4, operation: .add),
            CalcudokuCage(cells: [7], target: 4, operation: .given),
            CalcudokuCage(cells: [8], target: 1, operation: .given),
            CalcudokuCage(cells: [9, 10], target: 7, operation: .add),
            CalcudokuCage(cells: [11], target: 2, operation: .given),
            CalcudokuCage(cells: [12], target: 4, operation: .given),
            CalcudokuCage(cells: [13, 14], target: 3, operation: .add),
            CalcudokuCage(cells: [15], target: 3, operation: .given)
        ]
        let digits = [3, 4, 2, 1, 2, 1, 3, 4, 1, 3, 4, 2, 4, 2, 1, 3]
        var values = Grid(size: GridSize(square: 4), repeating: 0)
        for (index, digit) in digits.enumerated() {
            values[Position(row: index / 4, column: index % 4)] = digit
        }

        func filled(_ cell: Int) -> @Sendable (CalcudokuBoard) -> Bool {
            { $0.value(at: Position(row: cell / 4, column: cell % 4)) != nil }
        }
        let wrong = "That digit breaks a row, a column or its cage. Tap Undo and try again."

        return TutorialScenario(
            definition: CalcudokuPuzzle(side: 4, cages: cages),
            solution: CalcudokuSolution(values: values),
            steps: [
                TutorialStep(
                    text: "Every row and column uses 1 to 4 once. A cage showing just a"
                        + " number is already solved — type it in. Start with the 2× pair.",
                    correction: wrong,
                    isComplete: filled(2)
                ),
                TutorialStep(
                    text: "Only 1 and 2 multiply to 2, so the other cell of that cage is"
                        + " settled too.",
                    correction: wrong,
                    isComplete: filled(3)
                ),
                TutorialStep(
                    text: "Now the top row has two cells left and they add up to 7.",
                    correction: wrong,
                    isComplete: filled(0)
                ),
                TutorialStep(
                    text: "Its partner follows from the same cage.",
                    correction: wrong,
                    isComplete: filled(1)
                ),
                TutorialStep(
                    text: "Keep going: every cell you fill removes a digit from its row"
                        + " and column.",
                    correction: wrong,
                    isComplete: { board in
                        (0..<16).allSatisfy {
                            board.value(at: Position(row: $0 / 4, column: $0 % 4)) != nil
                        }
                    }
                )
            ]
        )
    }

    // MARK: - Hitori

    /// 4×4. Izgara, benzersiz çözümlü olanları tarayan küçük bir aramayla bulundu ve
    /// kaynağa donduruldu; elle kurulan adaylar benzersiz çıkmıyordu.
    public static func hitori() -> TutorialScenario<HitoriRuntime> {
        let rows = [
            [3, 4, 1, 1],
            [4, 1, 3, 3],
            [4, 3, 2, 1],
            [2, 2, 1, 4]
        ]
        let shadedRows = [
            [false, false, false, true],
            [true, false, true, false],
            [false, false, false, false],
            [true, false, true, false]
        ]
        var values = Grid(size: GridSize(square: 4), repeating: 0)
        var shaded = Grid(size: GridSize(square: 4), repeating: false)
        for row in 0..<4 {
            for column in 0..<4 {
                values[Position(row: row, column: column)] = rows[row][column]
                shaded[Position(row: row, column: column)] = shadedRows[row][column]
            }
        }

        func isShaded(_ row: Int, _ column: Int) -> @Sendable (HitoriBoard) -> Bool {
            { $0[Position(row: row, column: column)] == .shaded }
        }
        let wrong = "That cell stays white in the solution. Tap it again to clear it."

        return TutorialScenario(
            definition: HitoriPuzzle(values: values),
            solution: HitoriSolution(shaded: shaded),
            steps: [
                TutorialStep(
                    text: "Tap a cell to shade it. No number may appear twice in a row or"
                        + " column — the top row has two 1s, so one of them goes.",
                    correction: wrong,
                    isComplete: isShaded(0, 3)
                ),
                TutorialStep(
                    text: "Shaded cells may never touch each other side by side. The first"
                        + " column has two 4s; only one of them can go.",
                    correction: wrong,
                    isComplete: isShaded(1, 0)
                ),
                TutorialStep(
                    text: "The second row has two 3s. Shade the one that keeps the white"
                        + " cells connected.",
                    correction: wrong,
                    isComplete: isShaded(1, 2)
                ),
                TutorialStep(
                    text: "The bottom row has two 2s — and the first column still has a"
                        + " duplicate.",
                    correction: wrong,
                    isComplete: isShaded(3, 0)
                ),
                TutorialStep(
                    text: "One duplicate left. Every white cell must stay reachable from"
                        + " every other.",
                    correction: wrong,
                    isComplete: isShaded(3, 2)
                )
            ]
        )
    }

    // MARK: - Slitherlink

    /// 3×3, çözüm dış çerçevenin tamamı. Ortadaki 0 ilk çıkarımı veriyor.
    public static func slitherlink() -> TutorialScenario<SlitherlinkRuntime> {
        let table = [[2, 1, 2], [1, 0, 1], [2, 1, 2]]
        var clues = Grid<Int?>(size: GridSize(square: 3), repeating: nil)
        for row in 0..<3 {
            for column in 0..<3 {
                clues[Position(row: row, column: column)] = table[row][column]
            }
        }
        let puzzle = SlitherlinkPuzzle(clues: clues)

        // Çözüm: dış çerçeve. Kenarın iki komşusundan tam biri ızgaranın içinde.
        var lines = [Bool](repeating: false, count: puzzle.edgeCount)
        for edge in 0..<puzzle.edgeCount {
            let endpoints = puzzle.endpointsOfEdge[edge]
            let first = puzzle.dotPosition(of: endpoints.first)
            let second = puzzle.dotPosition(of: endpoints.second)
            let onTop = first.row == 0 && second.row == 0
            let onBottom = first.row == 3 && second.row == 3
            let onLeft = first.column == 0 && second.column == 0
            let onRight = first.column == 3 && second.column == 3
            lines[edge] = onTop || onBottom || onLeft || onRight
        }

        let centreEdges = puzzle.edgesOfCell[4]
        let wrong = "That edge isn't part of the loop. Tap it again to clear it."

        return TutorialScenario(
            definition: puzzle,
            solution: SlitherlinkSolution(lines: lines),
            steps: [
                TutorialStep(
                    text: "Tap an edge once for a line, twice for a cross. The 0 in the"
                        + " middle means none of its four edges are used.",
                    correction: wrong,
                    isComplete: { board in
                        centreEdges.allSatisfy { board[$0] == .cross }
                    }
                ),
                TutorialStep(
                    text: "Each number says how many of that cell's edges the loop uses."
                        + " Draw the top edge of the grid.",
                    correction: wrong,
                    isComplete: { board in
                        (0..<3).allSatisfy { board[$0] == .line }
                    }
                ),
                TutorialStep(
                    text: "The loop never branches and never stops. Follow it down the"
                        + " left side.",
                    correction: wrong,
                    isComplete: { board in
                        [12, 16, 20].allSatisfy { board[$0] == .line }
                    }
                ),
                TutorialStep(
                    text: "Close it: one single loop, no loose ends.",
                    correction: wrong,
                    isComplete: { board in
                        SlitherlinkRuntime.isSolved(board, in: puzzle)
                    }
                )
            ]
        )
    }

    // MARK: - Hashi

    /// Dört köşe adası, her biri iki köprü istiyor. Tek çözüm dört tekli köprüden oluşan
    /// kare: çift köprüyle çözmek adaları iki parçaya ayırıyor ve bağlılık şartı düşüyor.
    public static func hashi() -> TutorialScenario<HashiRuntime> {
        let puzzle = HashiPuzzle(
            size: GridSize(square: 3),
            islands: [
                HashiIsland(position: Position(row: 0, column: 0), required: 2),
                HashiIsland(position: Position(row: 0, column: 2), required: 2),
                HashiIsland(position: Position(row: 2, column: 0), required: 2),
                HashiIsland(position: Position(row: 2, column: 2), required: 2)
            ]
        )
        let counts = [Int](repeating: 1, count: puzzle.edges.count)
        let wrong = "Every island here needs exactly two bridges. Tap the bridge to change it."

        func bridgeCount(_ minimum: Int) -> @Sendable (HashiBoard) -> Bool {
            { board in (0..<board.edgeCount).count { board[$0] > 0 } >= minimum }
        }

        return TutorialScenario(
            definition: puzzle,
            solution: HashiSolution(counts: counts),
            steps: [
                TutorialStep(
                    text: "Drag from one island to another to build a bridge. The number"
                        + " says how many bridges that island needs.",
                    correction: wrong,
                    isComplete: bridgeCount(1)
                ),
                TutorialStep(
                    text: "Bridges run straight, never diagonally, and never cross.",
                    correction: wrong,
                    isComplete: bridgeCount(2)
                ),
                TutorialStep(
                    text: "Tapping a bridge again doubles it, and once more removes it."
                        + " Here single bridges are enough.",
                    correction: wrong,
                    isComplete: bridgeCount(3)
                ),
                TutorialStep(
                    text: "One bridge left. When you're done every island must be"
                        + " reachable from every other.",
                    correction: wrong,
                    isComplete: { board in
                        HashiRuntime.isSolved(board, in: puzzle)
                    }
                )
            ]
        )
    }
}
