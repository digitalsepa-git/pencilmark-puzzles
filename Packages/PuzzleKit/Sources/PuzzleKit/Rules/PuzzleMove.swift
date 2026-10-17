/// Oyuncunun tek hamlesi.
///
/// Hamle kendi geri alma bilgisini taşır: `apply` öncesindeki değer hamlenin içinde.
/// Geri alma yığını bu sayede yalnızca hamle dizisi; ızgara anlık görüntüsü tutmak
/// gerekmiyor. Sınırsız geri alma/ileri alma (brief b.7) buna dayanıyor.
public protocol PuzzleMove: Equatable, Sendable {
    associatedtype Board: Sendable

    func apply(to board: inout Board)
    func undo(on board: inout Board)
}
