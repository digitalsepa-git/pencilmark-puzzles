import PuzzleKit

/// Rakam yazılan varyantlar (Kakuro, Calcudoku).
///
/// Brief b.7'nin giriş modeli tablosu beş varyantı iki kümeye ayırıyor ve bu ayrım
/// arayüzün değil oyunun kendisinin: bir varyantta ya bir hücreye değer yazılıyor ya da
/// bir hücre/kenar durumlar arasında döndürülüyor. İkisi burada, GameCore'da tanımlı,
/// çünkü ikisi de hamle üretiyor ve hamle üretimi test edilebilir olmalı.
public protocol DigitPuzzleRuntime: PuzzleRuntime where Location == Position {
    /// Kullanılabilir rakamlar. Kakuro'da her zaman 1-9, Calcudoku'da ızgara kenarı kadar.
    static func digits(in definition: Definition) -> ClosedRange<Int>
    /// Oyuncunun yazabildiği hücre mi. Kakuro'nun ipucu hücrelerinde yazılamıyor.
    static func isEditable(_ position: Position, in definition: Definition) -> Bool

    static func write(_ digit: Int, at position: Position, on board: Board) -> Move
    static func erase(at position: Position, on board: Board) -> Move
    static func toggleCandidate(_ digit: Int, at position: Position, on board: Board) -> Move
}

/// Dokunuşla durum döndürülen varyantlar (Hitori, Slitherlink, Hashi).
public protocol CyclingPuzzleRuntime: PuzzleRuntime {
    /// Brief b.7'deki döngüler: Hitori'de karala → işaretle → boş, Slitherlink'te
    /// çizgi → çarpı → boş, Hashi'de 0 → 1 → 2 → 0.
    static func cycle(at location: Location, on board: Board, in definition: Definition) -> Move
}

extension KakuroRuntime: DigitPuzzleRuntime {
    public static func digits(in definition: KakuroPuzzle) -> ClosedRange<Int> { 1...9 }

    public static func isEditable(_ position: Position, in definition: KakuroPuzzle) -> Bool {
        definition.cells[position].isEntry
    }

    public static func write(_ digit: Int, at position: Position, on board: KakuroBoard) -> KakuroMove {
        .writing(digit, at: position, on: board)
    }

    public static func erase(at position: Position, on board: KakuroBoard) -> KakuroMove {
        .erasing(at: position, on: board)
    }

    public static func toggleCandidate(
        _ digit: Int,
        at position: Position,
        on board: KakuroBoard
    ) -> KakuroMove {
        .togglingCandidate(digit, at: position, on: board)
    }
}

extension CalcudokuRuntime: DigitPuzzleRuntime {
    /// Calcudoku'da rakam aralığı ızgara kenarı kadar: 4×4'te 1-4, 8×8'de 1-8.
    public static func digits(in definition: CalcudokuPuzzle) -> ClosedRange<Int> {
        1...definition.side
    }

    public static func isEditable(_ position: Position, in definition: CalcudokuPuzzle) -> Bool {
        definition.size.contains(position)
    }

    public static func write(
        _ digit: Int,
        at position: Position,
        on board: CalcudokuBoard
    ) -> CalcudokuMove {
        .writing(digit, at: position, on: board)
    }

    public static func erase(at position: Position, on board: CalcudokuBoard) -> CalcudokuMove {
        .erasing(at: position, on: board)
    }

    public static func toggleCandidate(
        _ digit: Int,
        at position: Position,
        on board: CalcudokuBoard
    ) -> CalcudokuMove {
        .togglingCandidate(digit, at: position, on: board)
    }
}

extension HitoriRuntime: CyclingPuzzleRuntime {
    public static func cycle(
        at location: Position,
        on board: HitoriBoard,
        in definition: HitoriPuzzle
    ) -> HitoriMove {
        .cycling(at: location, on: board)
    }
}

extension SlitherlinkRuntime: CyclingPuzzleRuntime {
    public static func cycle(
        at location: Int,
        on board: SlitherlinkBoard,
        in definition: SlitherlinkPuzzle
    ) -> SlitherlinkMove {
        .cycling(edge: location, on: board)
    }
}

extension HashiRuntime: CyclingPuzzleRuntime {
    public static func cycle(
        at location: Int,
        on board: HashiBoard,
        in definition: HashiPuzzle
    ) -> HashiMove {
        .cycling(edge: location, on: board, in: definition)
    }
}
