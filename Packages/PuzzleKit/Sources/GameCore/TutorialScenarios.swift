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

        return TutorialScenario(
            definition: KakuroPuzzle(cells: cells),
            solution: KakuroSolution(values: values),
            steps: [
                TutorialStep(
                    isComplete: filled(1, 1)
                ),
                TutorialStep(
                    isComplete: filled(1, 2)
                ),
                TutorialStep(
                    isComplete: filled(2, 1)
                ),
                TutorialStep(
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

        return TutorialScenario(
            definition: CalcudokuPuzzle(side: 4, cages: cages),
            solution: CalcudokuSolution(values: values),
            steps: [
                TutorialStep(
                    isComplete: filled(2)
                ),
                TutorialStep(
                    isComplete: filled(3)
                ),
                TutorialStep(
                    isComplete: filled(0)
                ),
                TutorialStep(
                    isComplete: filled(1)
                ),
                TutorialStep(
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

        return TutorialScenario(
            definition: HitoriPuzzle(values: values),
            solution: HitoriSolution(shaded: shaded),
            steps: [
                TutorialStep(
                    isComplete: isShaded(0, 3)
                ),
                TutorialStep(
                    isComplete: isShaded(1, 0)
                ),
                TutorialStep(
                    isComplete: isShaded(1, 2)
                ),
                TutorialStep(
                    isComplete: isShaded(3, 0)
                ),
                TutorialStep(
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

        return TutorialScenario(
            definition: puzzle,
            solution: SlitherlinkSolution(lines: lines),
            steps: [
                TutorialStep(
                    isComplete: { board in
                        centreEdges.allSatisfy { board[$0] == .cross }
                    }
                ),
                TutorialStep(
                    isComplete: { board in
                        (0..<3).allSatisfy { board[$0] == .line }
                    }
                ),
                TutorialStep(
                    isComplete: { board in
                        [12, 16, 20].allSatisfy { board[$0] == .line }
                    }
                ),
                TutorialStep(
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

        func bridgeCount(_ minimum: Int) -> @Sendable (HashiBoard) -> Bool {
            { board in (0..<board.edgeCount).count { board[$0] > 0 } >= minimum }
        }

        return TutorialScenario(
            definition: puzzle,
            solution: HashiSolution(counts: counts),
            steps: [
                TutorialStep(
                    isComplete: bridgeCount(1)
                ),
                TutorialStep(
                    isComplete: bridgeCount(2)
                ),
                TutorialStep(
                    isComplete: bridgeCount(3)
                ),
                TutorialStep(
                    isComplete: { board in
                        HashiRuntime.isSolved(board, in: puzzle)
                    }
                )
            ]
        )
    }
}
