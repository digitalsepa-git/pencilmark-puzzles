import PuzzleKit

/// Yarım kalan bir oturumun saklanan hali.
///
/// İçinde tahta yok, hamle dizisi var. Sebebi ADR 0018'de: hamle dizisi tahtayı zaten
/// belirliyor, ikisini birden saklamak aynı bilgiyi iki yerde tutmak olurdu ve ikisinin
/// birbirinden ayrılması an meselesi. Üstelik hamle dizisi geri alma yığınını da
/// koruyor — brief b.7 geri almayı "bulmaca oturumu boyunca kalıcı" istiyor ve
/// uygulamayı kapatıp açmak o oturumu bitirmiyor.
public struct GameSnapshot<Move: PuzzleMove>: Codable, Sendable {
    public let history: MoveHistory<Move>
    public let hintCount: Int

    public init(history: MoveHistory<Move>, hintCount: Int) {
        self.history = history
        self.hintCount = hintCount
    }
}
