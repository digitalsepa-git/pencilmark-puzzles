/// Varyantın kural doğrulayıcısı.
///
/// Üç ayrı soruyu ayrı yöntemler cevaplıyor, çünkü arayüzde üç ayrı yerde kullanılıyor:
/// hamle anında (giriş engelleme), kontrol düğmesinde (hata gösterme) ve bitişte.
public protocol PuzzleRules: Sendable {
    associatedtype Definition: Sendable
    associatedtype Board: Sendable
    associatedtype Move: PuzzleMove where Move.Board == Board

    /// Hamle kuralların izin verdiği bir hamle mi. Doğru olup olmadığını söylemez —
    /// yanlış ama kurallara uygun hamle yapılabilir, oyunun tamamı bu.
    func isLegal(_ move: Move, on board: Board, in definition: Definition) -> Bool

    /// Mevcut tahtadaki kural ihlalleri. Hata kontrolü düğmesi (brief b.7) bunu gösterir.
    func violations(on board: Board, in definition: Definition) -> [Position]

    /// Bulmaca bitti mi. Kural ihlali yok *ve* tahta tamamen dolu demek.
    func isSolved(_ board: Board, in definition: Definition) -> Bool
}
