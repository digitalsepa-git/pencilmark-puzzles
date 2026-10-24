/// Oyuncunun Calcudoku tahtası: hücre başına kesin değer ve kalem işaretleri.
///
/// `DigitCell` kullanıyor, yani kalem işareti modelin içinde. Brief b.7: "Kakuro ve
/// Calcudoku'da zorunlu; bu kitle onsuz oynamaz." Rakip analizinde (PR #10) en somut ürün
/// fırsatı da buradaydı — kalem işareti kalitesine dair beş ayrı şikâyet.
public struct CalcudokuBoard: Hashable, Sendable {
    public private(set) var cells: Grid<DigitCell>

    public init(_ puzzle: CalcudokuPuzzle) {
        self.cells = Grid(size: puzzle.size, repeating: .empty)
    }

    public init(cells: Grid<DigitCell>) {
        self.cells = cells
    }

    public subscript(position: Position) -> DigitCell {
        get { cells[position] }
        set { cells[position] = newValue }
    }

    public func value(at position: Position) -> Int? {
        cells[position].value
    }

    public var isComplete: Bool {
        cells.elements.allSatisfy(\.isFilled)
    }

    public var isEmpty: Bool {
        cells.elements.allSatisfy(\.isEmpty)
    }

    /// Kesin değerlerin ızgarası; boş hücreler `nil`.
    public func values() -> Grid<Int?> {
        cells.map(\.value)
    }
}

/// Tamamlanmış ve doğrulanmış değer dizilimi.
public struct CalcudokuSolution: Hashable, Sendable {
    public let values: Grid<Int>

    public init(values: Grid<Int>) {
        self.values = values
    }

    public func board() -> CalcudokuBoard {
        CalcudokuBoard(cells: values.map { DigitCell(value: $0) })
    }
}

/// Tek hücrenin durumunu değiştiren hamle.
///
/// Hücrenin eski ve yeni halini bütünüyle taşıyor; kesin değer yazmak, silmek ve kalem
/// işareti değiştirmek aynı tipin özel halleri. Geri alma bu sayede tek bir kurala
/// indi ve kalem işaretleri de geri alınabilir oldu — rakiplerde eksik olan şey bu.
public struct CalcudokuMove: PuzzleMove, Codable {
    public typealias Board = CalcudokuBoard

    public let position: Position
    public let previous: DigitCell
    public let next: DigitCell

    public init(position: Position, previous: DigitCell, next: DigitCell) {
        self.position = position
        self.previous = previous
        self.next = next
    }

    public func apply(to board: inout CalcudokuBoard) {
        board[position] = next
    }

    public func undo(on board: inout CalcudokuBoard) {
        board[position] = previous
    }

    /// Kesin değer yazma. Brief b.7: "Hücre seç, grid boyutuna göre rakam çubuğu".
    ///
    /// Adaylar silinmiyor, saklanıyor: kullanıcı kesin değeri geri alıp adaylara dönmeyi
    /// bekliyor (bkz. `DigitCell`).
    public static func writing(
        _ value: Int,
        at position: Position,
        on board: CalcudokuBoard
    ) -> CalcudokuMove {
        let current = board[position]
        return CalcudokuMove(
            position: position,
            previous: current,
            next: DigitCell(value: value, candidates: current.candidates)
        )
    }

    public static func erasing(at position: Position, on board: CalcudokuBoard) -> CalcudokuMove {
        let current = board[position]
        return CalcudokuMove(
            position: position,
            previous: current,
            next: DigitCell(value: nil, candidates: current.candidates)
        )
    }

    /// Kalem işareti ekleme/çıkarma.
    public static func togglingCandidate(
        _ digit: Int,
        at position: Position,
        on board: CalcudokuBoard
    ) -> CalcudokuMove {
        let current = board[position]
        var candidates = current.candidates
        candidates.toggle(digit)
        return CalcudokuMove(
            position: position,
            previous: current,
            next: DigitCell(value: current.value, candidates: candidates)
        )
    }

    /// Satır veya sütunda bir rakam kesinleştiğinde o rakamı adaylardan silme.
    ///
    /// Rakip analizindeki (PR #10) doğrudan özellik isteği: "satır/sütunda bir rakam
    /// kullanılınca adaylar kendiliğinden güncellenmiyor". Hamle olarak modellendi, çünkü
    /// geri alınabilir olması gerekiyor.
    public static func clearingCandidate(
        _ digit: Int,
        at position: Position,
        on board: CalcudokuBoard
    ) -> CalcudokuMove? {
        let current = board[position]
        guard current.candidates.contains(digit) else { return nil }
        var candidates = current.candidates
        candidates.remove(digit)
        return CalcudokuMove(
            position: position,
            previous: current,
            next: DigitCell(value: current.value, candidates: candidates)
        )
    }
}
