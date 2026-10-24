/// Geri alma ve ileri alma yığını.
///
/// Brief b.7 geri almayı **sınırsız** istiyor, bu yüzden burada hiçbir üst sınır yok —
/// bulmaca oturumu boyunca her hamle saklanıyor. En büyük ızgara 12×12 ve hamleler küçük
/// değer tipleri; bir oturumun tamamı birkaç kilobayt.
///
/// Yığın hamleyi **çiftler halinde** tutuyor: ileri hamle ve onu geri alan hamle. Tersi
/// kaydı atan tarafta hesaplanıyor, çünkü bir hamlenin tersi tahtanın hamleden **önceki**
/// haline bağlı — "bu hücreye 5 yaz"ın tersi, orada ne olduğunu bilmeden yazılamaz.
/// Alternatifi her hamlede tahtanın tamamını saklamaktı; bu, 144 hücrelik bir ızgarada
/// yüzlerce hamle sonunda gereksiz bir yığın demek.
public struct MoveHistory<Move: Sendable>: Sendable {
    public struct Entry: Sendable {
        /// Hamlenin kendisi.
        public let forward: Move
        /// Aynı hamleyi geri alan hamle; kayıt anında, uygulamadan önce hesaplanıyor.
        public let backward: Move

        public init(forward: Move, backward: Move) {
            self.forward = forward
            self.backward = backward
        }
    }

    private var past: [Entry] = []
    private var future: [Entry] = []

    public init() {}

    public var canUndo: Bool { !past.isEmpty }
    public var canRedo: Bool { !future.isEmpty }

    /// Kaydedilmiş hamle sayısı. İstatistik ve test için.
    public var moveCount: Int { past.count }

    /// Yeni bir hamle kaydediyor.
    ///
    /// İleri yığını temizleniyor: geri alıp başka bir hamle yapan oyuncunun eski ileri
    /// dalı artık ulaşılabilir bir durum değil.
    public mutating func record(forward: Move, backward: Move) {
        past.append(Entry(forward: forward, backward: backward))
        future.removeAll(keepingCapacity: true)
    }

    /// Geri alınacak hamleyi veriyor; uygulamak çağıranın işi.
    public mutating func undo() -> Move? {
        guard let entry = past.popLast() else { return nil }
        future.append(entry)
        return entry.backward
    }

    /// İleri alınacak hamleyi veriyor; uygulamak çağıranın işi.
    public mutating func redo() -> Move? {
        guard let entry = future.popLast() else { return nil }
        past.append(entry)
        return entry.forward
    }

    public mutating func removeAll() {
        past.removeAll()
        future.removeAll()
    }
}
