import PuzzleKit

// Calcudoku bulmacalarını testlerde kurmak için sabitler.
//
// Hashi ve Hitori'de metin biçimi vardı; Calcudoku'da kafes bölüntüsü metne iyi
// oturmuyor (aynı hücre hem değer hem kafes kimliği taşımak zorunda), o yüzden
// doğrudan kafes listesi yazılıyor.
enum CalcudokuFixture {
    /// Elle kurulmuş 4×4. Çözümü aşağıdaki Latin karesi:
    ///
    ///     1 2 3 4
    ///     2 3 4 1
    ///     3 4 1 2
    ///     4 1 2 3
    ///
    /// Sekiz kafes dört işlemin hepsini ve bir de verilmiş değeri kapsıyor.
    static var handmade4x4: CalcudokuPuzzle {
        CalcudokuPuzzle(side: 4, cages: [
            CalcudokuCage(cells: [0, 1], target: 3, operation: .add),
            CalcudokuCage(cells: [2, 3], target: 12, operation: .multiply),
            CalcudokuCage(cells: [4, 8], target: 5, operation: .add),
            CalcudokuCage(cells: [5, 6, 7], target: 8, operation: .add),
            CalcudokuCage(cells: [9, 10], target: 3, operation: .subtract),
            CalcudokuCage(cells: [11, 15], target: 5, operation: .add),
            CalcudokuCage(cells: [12, 13], target: 4, operation: .divide),
            CalcudokuCage(cells: [14], target: 2, operation: .given)
        ])
    }

    static var handmade4x4Solution: CalcudokuSolution {
        CalcudokuSolution(values: Grid(size: GridSize(square: 4), elements: [
            1, 2, 3, 4,
            2, 3, 4, 1,
            3, 4, 1, 2,
            4, 1, 2, 3
        ]))
    }

    /// Hedefi ulaşılamaz kafes: 4×4'te iki hücrenin toplamı en fazla 4+3=7.
    static var impossible4x4: CalcudokuPuzzle {
        CalcudokuPuzzle(side: 4, cages: [
            CalcudokuCage(cells: [0, 1], target: 12, operation: .add),
            CalcudokuCage(cells: [2, 3], target: 5, operation: .add),
            CalcudokuCage(cells: [4, 5, 6, 7], target: 10, operation: .add),
            CalcudokuCage(cells: [8, 9, 10, 11], target: 10, operation: .add),
            CalcudokuCage(cells: [12, 13, 14, 15], target: 10, operation: .add)
        ])
    }

    /// Her kafes bir satır ve hedefi 1+2+3+4: bütün Latin kareleri geçerli.
    /// Kafes kısıtı hiçbir şey söylemediğinde ne olduğunun testi.
    static var ambiguous4x4: CalcudokuPuzzle {
        CalcudokuPuzzle(side: 4, cages: (0..<4).map { row in
            CalcudokuCage(
                cells: (0..<4).map { row * 4 + $0 },
                target: 10,
                operation: .add
            )
        })
    }
}
