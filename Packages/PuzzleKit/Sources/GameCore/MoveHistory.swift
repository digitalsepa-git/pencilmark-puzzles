import PuzzleKit

/// Geri alma ve ileri alma yığını.
///
/// Brief b.7 geri almayı **sınırsız** istiyor, bu yüzden üst sınır yok. Maliyeti düşük:
/// `PuzzleMove` kendi geri alma bilgisini taşıyor (hamleden önceki değer hamlenin içinde),
/// yani tahtanın anlık görüntüsünü saklamak gerekmiyor — yığın yalnız hamle dizisi.
///
/// Yığın tek tek hamleleri değil **hamle öbeklerini** tutuyor. Sebebi, oyuncunun tek
/// hareketinin birden çok hamle üretebilmesi: Kakuro'da bir rakam yazmak aynı kesitteki
/// hücrelerin adaylarından o rakamı da siliyor (rakip analizindeki doğrudan istek, PR #10).
/// Bunlar ayrı ayrı geri alınabilseydi oyuncu tek dokunuşla yaptığı şeyi beş dokunuşla
/// geri almak zorunda kalırdı.
public struct MoveHistory<Move: PuzzleMove>: Sendable, Codable {
    private var past: [[Move]] = []
    private var future: [[Move]] = []

    public init() {}

    public var canUndo: Bool { !past.isEmpty }
    public var canRedo: Bool { !future.isEmpty }

    /// Oyuncunun yaptığı hareket sayısı — hamle sayısı değil, öbek sayısı.
    public var actionCount: Int { past.count }

    /// Yeni bir öbek kaydediyor.
    ///
    /// İleri yığını temizleniyor: geri alıp başka bir hamle yapan oyuncunun eski ileri
    /// dalı artık ulaşılabilir bir durum değil.
    public mutating func record(_ group: [Move]) {
        guard !group.isEmpty else { return }
        past.append(group)
        future.removeAll(keepingCapacity: true)
    }

    /// Geri alınacak öbeği **kaydedildiği sırayla** veriyor; çağıran ters sırada geri alır.
    ///
    /// Sıra çağırana bırakılıyor çünkü tersine çevrilmiş bir dizi döndürmek, çağrı yerinde
    /// görünmeyen bir sözleşme olurdu.
    public mutating func undo() -> [Move]? {
        guard let group = past.popLast() else { return nil }
        future.append(group)
        return group
    }

    /// İleri alınacak öbeği kaydedildiği sırayla veriyor.
    public mutating func redo() -> [Move]? {
        guard let group = future.popLast() else { return nil }
        past.append(group)
        return group
    }

    /// Kaydedilmiş hamleleri sırayla boş bir tahtaya uyguluyor.
    ///
    /// Yarım kalan oyun tahta olarak değil hamle dizisi olarak saklanıyor (ADR 0018);
    /// tahtayı geri getiren şey bu. Yığının içini dışarı açmadan: `past` ve `future`
    /// kapalı kalıyor, çağıran yalnız sonucu alıyor.
    public func replay(onto board: inout Move.Board) {
        for group in past {
            for move in group {
                move.apply(to: &board)
            }
        }
    }

    public mutating func removeAll() {
        past.removeAll()
        future.removeAll()
    }
}
