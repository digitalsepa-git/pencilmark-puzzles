/// Oyuncunun tek hamlesi.
///
/// Hamle kendi geri alma bilgisini taşır: `apply` öncesindeki değer hamlenin içinde.
/// Geri alma yığını bu sayede yalnızca hamle dizisi; ızgara anlık görüntüsü tutmak
/// gerekmiyor. Sınırsız geri alma/ileri alma (brief b.7) buna dayanıyor.
/// Hamle **saklanabilir** olmak zorunda: brief b.7 otomatik kaydı her hamlede istiyor ve
/// yarım kalan oyun hamle dizisi olarak saklanıyor (ADR 0018). `Codable` bu yüzden
/// protokolün bir gereksinimi, varyantların isteğe bağlı eklediği bir şey değil.
public protocol PuzzleMove: Equatable, Sendable, Codable {
    associatedtype Board: Sendable

    func apply(to board: inout Board)
    func undo(on board: inout Board)
}
