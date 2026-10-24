import PuzzleKit

/// Bir varyantın oyun oturumuna bakan yüzü.
///
/// `PuzzleKit` varyantları birbirine benzemiyor: üçü hücre oynuyor, ikisi kenar; biri rakam
/// yazıyor, biri karalıyor, biri köprü sayıyor. Oturum katmanının bu farkları bilmesi
/// gerekmiyor — ihtiyacı olan beş şey var ve hepsi burada.
///
/// Tip silme (`any`) kullanılmıyor: oturum varyant üzerinde jenerik, böylece yanlış hamlenin
/// yanlış tahtaya uygulanması derleme hatası oluyor.
public protocol PuzzleRuntime: Sendable {
    associatedtype Definition: Sendable
    associatedtype Solution: Sendable
    associatedtype Board: Sendable
    associatedtype Move: PuzzleMove where Move.Board == Board
    /// Oyuncunun dokunduğu şey: hücre konumu ya da kenar indeksi.
    associatedtype Location: Hashable, Sendable

    /// Varyantın kimliği. Tohum türetmek ve ekran başlığı için.
    static var variant: PuzzleVariantID { get }

    /// Hedef zorlukta, benzersiz çözümlü bir bulmaca.
    ///
    /// Üretim de burada, çünkü her varyantın hattı ayrı bir tip ve uygulama katmanının
    /// beş tipi birbirinden ayırt etmesi için hiçbir sebep yok: oturumu kuran kod zaten
    /// bu protokol üzerinden jenerik. Hat kullanılıyor, yani benzersizlik kontrolü yine
    /// atlanamıyor (`GeneratedPuzzle` başka yerde kurulamaz).
    static func generate(
        difficulty: Difficulty,
        seed: UInt64
    ) throws -> GeneratedPuzzle<Definition, Solution>

    static func emptyBoard(for definition: Definition) -> Board
    static func isSolved(_ board: Board, in definition: Definition) -> Bool
    static func location(of move: Move) -> Location

    /// Çözümle çelişen yerler. "Henüz doldurulmamış" hata değil (brief b.7: hata kontrolü,
    /// eksik kontrolü değil).
    static func mistakes(
        in board: Board,
        against solution: Solution,
        in definition: Definition
    ) -> Set<Location>

    /// Tek bir hücreyi veya kenarı çözümdeki haline getiren hamle (brief b.7).
    ///
    /// Seçim belirlenimci: ilk yanlış ya da boş yer. Rastgele seçmek testi zorlaştırır ve
    /// oyuncuya bir şey kazandırmaz.
    static func hintMove(
        for board: Board,
        toward solution: Solution,
        in definition: Definition
    ) -> Move?

    /// Bir hamlenin kendiliğinden tetiklediği hamleler; hamleyle **aynı** geri alma öbeğine
    /// giriyorlar. Varsayılan boş: yalnız rakam yazan varyantların işi.
    static func companionMoves(
        after move: Move,
        on board: Board,
        in definition: Definition
    ) -> [Move]
}

extension PuzzleRuntime {
    public static func companionMoves(
        after move: Move,
        on board: Board,
        in definition: Definition
    ) -> [Move] {
        []
    }
}
