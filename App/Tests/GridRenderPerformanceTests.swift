import Foundation
import SwiftUI
import Testing
import PuzzleKit
@testable import Pencilmark

/// Izgara çiziminin maliyeti (brief b.11: "60 fps, kaydırma ve yakınlaştırmada kare
/// düşürmeden").
///
/// Ölçülen şey bir kare değil, **bir karenin içindeki çizim işi**: `ImageRenderer` ızgarayı
/// yerleştirip `Canvas`'ın çizim kapanışını koşturup sonucu bitmap'e yazıyor. Gerçek bir
/// karede son adım yok (çizim doğrudan GPU'ya gidiyor), yani buradaki sayı gerçek kare
/// süresinin **üst sınırı**. Alt sınır değil: asıl ölçüm cihazda yapılıyor (#66).
///
/// Eşik gevşek, tıpkı PuzzleKit'teki üretim ölçümünde olduğu gibi (ADR 0003): CI runner'ı
/// kararlı bir ölçüm vermiyor ve amaç bütçeyi doğrulamak değil, katastrofik regresyonu
/// yakalamak. Ölçülen sayılar her koşuda log'a yazılıyor.
@Suite("Izgara çizim maliyeti", .serialized)
@MainActor
struct GridRenderPerformanceTests {
    /// iPhone 16'da ızgaraya kalan alana yakın.
    private let size = CGSize(width: 360, height: 360)

    /// 60 fps'in kare bütçesi 16.6 ms; CI eşiği bunun beş katı.
    private let ceiling = Duration.milliseconds(83)

    @Test("Slitherlink 12×12, bütün kenarlar dolu")
    func slitherlinkWorstCase() throws {
        let fixture = PerformanceFixtures.denseSlitherlink(side: 12)
        for scale in [1.0, 3.0] as [CGFloat] {
            try measure("Slitherlink 12×12 · \(Int(scale)) kat", at: scale) { zoom in
                SlitherlinkGridView(
                    puzzle: fixture.puzzle,
                    board: fixture.board,
                    zoom: .constant(zoom)
                )
            }
        }
    }

    // En pahalı hücre çizimi kalem işaretleri: her boş hücre dokuz ayrı metin çiziyor.
    // 11×11 Kakuro'da bu 900'ün üzerinde metin ediyor ve gerçek bir oyunda da olabilir.
    @Test("Kakuro 11×11, bütün hücreler kalem işaretli")
    func kakuroWorstCase() throws {
        let fixture = PerformanceFixtures.pencilledKakuro(side: 11)
        for scale in [1.0, 3.0] as [CGFloat] {
            try measure("Kakuro 11×11 kalem · \(Int(scale)) kat", at: scale) { zoom in
                KakuroGridView(
                    puzzle: fixture.puzzle,
                    board: fixture.board,
                    zoom: .constant(zoom)
                )
            }
        }
    }

    @Test("Calcudoku 9×9, bütün hücreler kalem işaretli")
    func calcudokuWorstCase() throws {
        let fixture = PerformanceFixtures.pencilledCalcudoku(side: 9)
        for scale in [1.0, 3.0] as [CGFloat] {
            try measure("Calcudoku 9×9 kalem · \(Int(scale)) kat", at: scale) { zoom in
                CalcudokuGridView(
                    puzzle: fixture.puzzle,
                    board: fixture.board,
                    zoom: .constant(zoom)
                )
            }
        }
    }

    @Test("Hashi 12×12, bütün köprüler çift")
    func hashiWorstCase() throws {
        let fixture = PerformanceFixtures.denseHashi(side: 12)
        for scale in [1.0, 3.0] as [CGFloat] {
            try measure("Hashi 12×12 · \(Int(scale)) kat", at: scale) { zoom in
                HashiGridView(
                    puzzle: fixture.puzzle,
                    board: fixture.board,
                    zoom: .constant(zoom)
                )
            }
        }
    }

    @Test("Hitori 12×12")
    func hitoriWorstCase() throws {
        let fixture = PerformanceFixtures.denseHitori(side: 12)
        for scale in [1.0, 3.0] as [CGFloat] {
            try measure("Hitori 12×12 · \(Int(scale)) kat", at: scale) { zoom in
                HitoriGridView(
                    puzzle: fixture.puzzle,
                    board: fixture.board,
                    zoom: .constant(zoom)
                )
            }
        }
    }

    /// Yakınlaştırılmış ızgarada çizim işi artmamalı: ölçek `GridGeometry`'ye girdi,
    /// yani çizilen öğe sayısı aynı kalıyor, yalnız büyüğü çiziliyor.
    private func measure(
        _ name: String,
        at scale: CGFloat,
        of view: (GridZoom) -> some View
    ) throws {
        let zoom = GridZoom(scale: scale, pan: .zero)
        let content = view(zoom)
        var durations: [Duration] = []
        let clock = ContinuousClock()
        let iterations = 20

        // İlk çizim yazı tipi ve renk önbelleklerini ısıtıyor; ölçüme girmiyor.
        _ = SnapshotHarness.render(content, size: size, colorScheme: .light)

        for _ in 0..<iterations {
            durations.append(
                clock.measure {
                    _ = SnapshotHarness.render(content, size: size, colorScheme: .light)
                }
            )
        }

        durations.sort()
        let median = durations[durations.count / 2]
        let worst = durations[durations.count - 1]
        print(
            """
            [perf] \(name): ortanca \(median.milliseconds) ms · \
            en kötü \(worst.milliseconds) ms · kare bütçesi 16.67 ms · \
            CI eşiği \(ceiling.milliseconds) ms
            """
        )
        #expect(
            worst <= ceiling,
            "\(name) en kötü durumda \(worst.milliseconds) ms, eşik \(ceiling.milliseconds) ms"
        )
    }
}

/// Ölçüm bulmacaları elle kurulu, üreticiden alınmıyor — `SnapshotFixtures` ile aynı
/// gerekçe. Çözülebilir olmaları gerekmiyor: ölçülen tek şey çizim.
enum PerformanceFixtures {
    static func denseSlitherlink(side: Int) -> (puzzle: SlitherlinkPuzzle, board: SlitherlinkBoard) {
        var clues = Grid<Int?>(size: GridSize(square: side), repeating: nil)
        for position in GridSize(square: side).allPositions {
            clues[position] = (position.row + position.column) % 4
        }
        let puzzle = SlitherlinkPuzzle(clues: clues)

        var board = SlitherlinkBoard(puzzle)
        for edge in 0..<puzzle.edgeCount {
            board[edge] = edge % 2 == 0 ? .line : .cross
        }
        return (puzzle, board)
    }

    /// 11×11 Kakuro: altıncı satır ve sütun ipucu, yani kesitler 5 ve 4 uzunlukta.
    /// Toplamlar her kesit için en küçük olabilir değer (1+2+…+uzunluk); bulmaca çözülebilir
    /// olmak zorunda değil ama `KakuroPuzzle`'ın yerleşim koşullarını sağlamak zorunda.
    static func pencilledKakuro(side: Int) -> (puzzle: KakuroPuzzle, board: KakuroBoard) {
        let size = GridSize(square: side)
        var cells = Grid(size: size, repeating: KakuroCell.entry)
        for position in size.allPositions where position.row % 6 == 0 || position.column % 6 == 0 {
            cells[position] = .clue(down: nil, right: nil)
        }
        for position in size.allPositions where !cells[position].isEntry {
            let right = runLength(from: position, in: cells, rows: 0, columns: 1)
            let down = runLength(from: position, in: cells, rows: 1, columns: 0)
            cells[position] = .clue(
                down: down >= 2 ? down * (down + 1) / 2 : nil,
                right: right >= 2 ? right * (right + 1) / 2 : nil
            )
        }
        let puzzle = KakuroPuzzle(cells: cells)

        var board = KakuroBoard(puzzle)
        for position in size.allPositions where puzzle.cells[position].isEntry {
            board[position] = DigitCell(
                value: nil,
                candidates: DigitSet(Array(1...9))
            )
        }
        return (puzzle, board)
    }

    /// İpucu hücresinden sonra verilen yönde kaç giriş hücresi geliyor.
    private static func runLength(
        from position: Position,
        in cells: PuzzleKit.Grid<KakuroCell>,
        rows: Int,
        columns: Int
    ) -> Int {
        var length = 0
        var next = position.offset(byRows: rows, columns: columns)
        while cells.size.contains(next), cells[next].isEntry {
            length += 1
            next = next.offset(byRows: rows, columns: columns)
        }
        return length
    }

    /// Her kafes tek hücre: kafes sınırı çizgileri de en yoğun hâlde.
    static func pencilledCalcudoku(side: Int) -> (puzzle: CalcudokuPuzzle, board: CalcudokuBoard) {
        let cages = (0..<(side * side)).map { cell in
            CalcudokuCage(cells: [cell], target: cell % side + 1, operation: .given)
        }
        let puzzle = CalcudokuPuzzle(side: side, cages: cages)

        var board = CalcudokuBoard(puzzle)
        for position in puzzle.size.allPositions {
            board[position] = DigitCell(value: nil, candidates: DigitSet(Array(1...side)))
        }
        return (puzzle, board)
    }

    /// Adalar her iki satır/sütunda bir: komşu hücrede ada olmuyor ve köprü sayısı en
    /// yüksek.
    static func denseHashi(side: Int) -> (puzzle: HashiPuzzle, board: HashiBoard) {
        var islands: [HashiIsland] = []
        for row in stride(from: 0, to: side, by: 2) {
            for column in stride(from: 0, to: side, by: 2) {
                islands.append(
                    HashiIsland(position: Position(row: row, column: column), required: 4)
                )
            }
        }
        let puzzle = HashiPuzzle(size: GridSize(square: side), islands: islands)

        var board = HashiBoard(puzzle)
        for edge in puzzle.edges.indices {
            board[edge] = 2
        }
        return (puzzle, board)
    }

    static func denseHitori(side: Int) -> (puzzle: HitoriPuzzle, board: HitoriBoard) {
        let size = GridSize(square: side)
        var values = Grid(size: size, repeating: 1)
        for position in size.allPositions {
            values[position] = (position.row * side + position.column) % side + 1
        }
        let puzzle = HitoriPuzzle(values: values)

        var board = HitoriBoard(puzzle)
        for position in size.allPositions {
            board[position] = switch (position.row + position.column) % 3 {
            case 0: .shaded
            case 1: .marked
            default: .unknown
            }
        }
        return (puzzle, board)
    }
}

private extension Duration {
    /// Milisaniye, iki ondalık hane.
    var milliseconds: String {
        String(format: "%.2f", Double(components.attoseconds) / 1e15
            + Double(components.seconds) * 1000)
    }
}
