import Foundation
import GameCore
import PuzzleKit

/// Bir sonraki bulmacayı önden üretip bekleten önbellek.
///
/// Ölçüm (`docs/olcumler/uretim-darbogazi-2026-10-29.md`) üretimin maliyetinin yapısal
/// olduğunu gösterdi: Slitherlink Expert'te tek bir aday 5,5 saniye ve maliyeti düşüren
/// her fikir — toplu silme dahil — ters tepti. Önbellek o maliyeti **düşürmüyor**,
/// oyuncunun beklemesini kaldırıyor: bulmaca oyuncu bir öncekini oynarken üretiliyor.
///
/// Kapsamı bilinçli olarak dar:
///
/// - **Bellekte**, diskte değil. Üretilen şey tanım + çözüm ve beş varyantın tanım
///   tipini `Codable` yapmak ADR 0018'in bilerek kaçındığı iş. Uygulama kapanınca
///   önbellek gidiyor.
/// - **Anahtar başına bir bulmaca.** İkincisini tutmak belleği ve pili, karşılığını
///   almadan harcıyor.
/// - **İlk bulmacayı hızlandırmıyor.** Soğuk açılışta önbellek boş; oyuncu ilk
///   bulmacasını tam fiyatına bekliyor. Bunu çözen tek şey üreticinin kendisini
///   hızlandırmak.
@MainActor
@Observable
final class PuzzlePrefetcher {
    struct Key: Hashable {
        let variant: PuzzleVariantID
        let difficulty: Difficulty
    }

    /// Hazır bulmacalar. Değer `Any`: beş varyantın `Definition` ve `Solution` tipleri
    /// farklı ve hepsini saran bir varoluşsal tip, kazandırdığından çok makine getirirdi.
    /// Dışarı çıkış tek yerden (`take`) ve orada tip geri kazanılıyor.
    private var ready: [Key: Any] = [:]
    /// Üretimi süren anahtarlar; aynı bulmaca iki kez üretilmesin.
    private var inFlight: Set<Key> = []

    /// Hazır bulmacayı veriyor ve yuvayı boşaltıyor.
    ///
    /// Yuva boşaltılıyor çünkü aynı bulmacayı iki kez vermek, oyuncuya arka arkaya aynı
    /// ızgarayı göstermek demek — rakip şikâyetlerinden biri (ADR 0013).
    func take<Runtime: PuzzleRuntime>(
        _ type: Runtime.Type,
        difficulty: Difficulty
    ) -> GeneratedPuzzle<Runtime.Definition, Runtime.Solution>? {
        let key = Key(variant: Runtime.variant, difficulty: difficulty)
        guard let stored = ready[key] else { return nil }
        ready[key] = nil
        return stored as? GeneratedPuzzle<Runtime.Definition, Runtime.Solution>
    }

    func isReady<Runtime: PuzzleRuntime>(_ type: Runtime.Type, difficulty: Difficulty) -> Bool {
        ready[Key(variant: Runtime.variant, difficulty: difficulty)] != nil
    }

    /// Yuvayı doldurmaya başlıyor. Doluysa ya da üretim sürüyorsa hiçbir şey yapmıyor.
    ///
    /// Üretim `.background` önceliğinde: oyuncu o sırada bir bulmaca oynuyor ve
    /// arayüzün akıcılığı önden üretimden önemli.
    ///
    /// Dönen görev çağıran için değil **test** için: üretimin bittiğini beklemenin
    /// zamana bağlı olmayan tek yolu bu. Uygulama tarafı sonucu yok sayıyor.
    @discardableResult
    func prime<Runtime: PuzzleRuntime>(
        _ type: Runtime.Type,
        difficulty: Difficulty
    ) -> Task<Void, Never>? {
        let key = Key(variant: Runtime.variant, difficulty: difficulty)
        guard ready[key] == nil, !inFlight.contains(key) else { return nil }
        inFlight.insert(key)

        var generator = SystemRandomNumberGenerator()
        let counter = UInt64.random(in: 0..<UInt64.max, using: &generator)
        let seed = Seed.free(variant: Runtime.variant, difficulty: difficulty, counter: counter)

        return Task { [weak self] in
            let puzzle = await Task.detached(priority: .background) {
                try? Runtime.generate(difficulty: difficulty, seed: seed)
            }.value
            guard let self else { return }
            self.store(puzzle, for: key)
        }
    }

    /// Günlük bulmacanın tohumu tarihten geliyor (ADR 0006), rastgele değil.
    @discardableResult
    func primeDaily<Runtime: PuzzleRuntime>(
        _ type: Runtime.Type,
        on day: CalendarDay
    ) -> Task<Void, Never>? {
        let difficulty = DailyPuzzle.difficulty
        let key = Key(variant: Runtime.variant, difficulty: difficulty)
        guard ready[key] == nil, !inFlight.contains(key) else { return nil }
        inFlight.insert(key)

        let seed = DailyPuzzle.seed(on: day)
        return Task { [weak self] in
            let puzzle = await Task.detached(priority: .background) {
                try? Runtime.generate(difficulty: difficulty, seed: seed)
            }.value
            guard let self else { return }
            self.store(puzzle, for: key)
        }
    }

    private func store(_ puzzle: Any?, for key: Key) {
        inFlight.remove(key)
        // Üretim başarısızsa yuva boş kalıyor: oyun ekranı kendi üretimini yapar ve
        // hatayı oyuncuya orada gösterir.
        guard let puzzle else { return }
        ready[key] = puzzle
    }
}
