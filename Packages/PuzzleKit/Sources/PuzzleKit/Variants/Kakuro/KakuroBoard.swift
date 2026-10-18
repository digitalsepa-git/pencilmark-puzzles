/// Oyuncunun Kakuro tahtası: giriş hücrelerinde kesin değer ve kalem işaretleri.
///
/// Calcudoku'daki tahtayla aynı desen (`DigitCell`): brief b.7 kalem işaretini Kakuro ve
/// Calcudoku'da zorunlu tutuyor. İpucu hücrelerinin tahtada karşılığı var ama hep boş kalıyor;
/// indekslemeyi bulmacayla aynı tutmak, çözücüde ve arayüzde dönüşüm yapmaktan ucuz.
public struct KakuroBoard: Hashable, Sendable {
    public private(set) var cells: Grid<DigitCell>

    public init(_ puzzle: KakuroPuzzle) {
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

    public func isComplete(in puzzle: KakuroPuzzle) -> Bool {
        puzzle.entryCells.allSatisfy { cells.elements[$0].isFilled }
    }

    public func isEmpty(in puzzle: KakuroPuzzle) -> Bool {
        puzzle.entryCells.allSatisfy { cells.elements[$0].isEmpty }
    }
}

/// Tamamlanmış ve doğrulanmış rakam dizilimi. İpucu hücrelerinde 0.
public struct KakuroSolution: Hashable, Sendable {
    public let values: Grid<Int>

    public init(values: Grid<Int>) {
        self.values = values
    }

    public func board() -> KakuroBoard {
        KakuroBoard(cells: values.map { $0 == 0 ? DigitCell.empty : DigitCell(value: $0) })
    }
}

/// Tek giriş hücresinin durumunu değiştiren hamle.
///
/// Calcudoku'daki `CalcudokuMove` ile aynı yapı ve aynı gerekçe: hücrenin eski ve yeni halini
/// bütünüyle taşıyor, böylece kesin değer yazmak, silmek ve kalem işareti değiştirmek aynı
/// tipin özel halleri oluyor ve geri alma tek bir kurala iniyor.
public struct KakuroMove: PuzzleMove {
    public typealias Board = KakuroBoard

    public let position: Position
    public let previous: DigitCell
    public let next: DigitCell

    public init(position: Position, previous: DigitCell, next: DigitCell) {
        self.position = position
        self.previous = previous
        self.next = next
    }

    public func apply(to board: inout KakuroBoard) {
        board[position] = next
    }

    public func undo(on board: inout KakuroBoard) {
        board[position] = previous
    }

    /// Kesin değer yazma. Adaylar saklanıyor (bkz. `DigitCell`).
    public static func writing(
        _ value: Int,
        at position: Position,
        on board: KakuroBoard
    ) -> KakuroMove {
        let current = board[position]
        return KakuroMove(
            position: position,
            previous: current,
            next: DigitCell(value: value, candidates: current.candidates)
        )
    }

    public static func erasing(at position: Position, on board: KakuroBoard) -> KakuroMove {
        let current = board[position]
        return KakuroMove(
            position: position,
            previous: current,
            next: DigitCell(value: nil, candidates: current.candidates)
        )
    }

    public static func togglingCandidate(
        _ digit: Int,
        at position: Position,
        on board: KakuroBoard
    ) -> KakuroMove {
        let current = board[position]
        var candidates = current.candidates
        candidates.toggle(digit)
        return KakuroMove(
            position: position,
            previous: current,
            next: DigitCell(value: current.value, candidates: candidates)
        )
    }

    /// Kesitte bir rakam kesinleştiğinde o rakamı adaylardan silme.
    ///
    /// Rakip analizindeki (PR #10) doğrudan özellik isteği, Real Kakuro'ya gelen şikâyet:
    /// "satır veya sütunda bir rakam kullanılınca adaylar kendiliğinden güncellenmiyor".
    public static func clearingCandidate(
        _ digit: Int,
        at position: Position,
        on board: KakuroBoard
    ) -> KakuroMove? {
        let current = board[position]
        guard current.candidates.contains(digit) else { return nil }
        var candidates = current.candidates
        candidates.remove(digit)
        return KakuroMove(
            position: position,
            previous: current,
            next: DigitCell(value: current.value, candidates: candidates)
        )
    }
}
