import Foundation
import GameCore
import PuzzleKit

/// Ücretsiz katmanın günlük kotasını tutan ve saklayan katman (ADR 0007).
///
/// Sayaç `UserDefaults`'ta, SwiftData'da değil. Saklanan şey tek bir satır: gün, o gün
/// başlatılan tohumlar ve kullanılan ipucu sayısı. Geçmişi yok, sorgulanmıyor ve her gün
/// üzerine yazılıyor — `Preferences`'ın kendi gerekçesiyle aynı durum. SwiftData'ya
/// koymak bir şema girişi ve ilk yayından sonra bir göç adımı (ADR 0017) getirirdi,
/// karşılığında hiçbir şey vermeden.
///
/// Katman (`tier`) burada sabit `free`: Plus'ı veren şey StoreKit ve o bağlantı ayrı iş
/// (#61). `update(tier:)` o işin bağlanacağı yer; kota ve kilit mantığı StoreKit'ten
/// bağımsız yazılıp sınanabilsin diye şimdiden ayrı duruyor.
@MainActor
@Observable
final class PlayLimits {
    private enum Key {
        static let quota = "kota.gunluk"
    }

    private let defaults: UserDefaults

    private(set) var tier: PlayerTier
    private(set) var quota: DailyQuota {
        didSet { persist() }
    }

    var allowance: PlayAllowance { PlayAllowance(tier: tier, quota: quota) }

    init(
        defaults: UserDefaults = .standard,
        tier: PlayerTier = .free,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.tier = tier
        let today = LocalCalendar.today(now: now, calendar: calendar)
        let stored = defaults.data(forKey: Key.quota)
            .flatMap { try? JSONDecoder().decode(DailyQuota.self, from: $0) }
        self.quota = stored?.rolledOver(to: today) ?? DailyQuota(day: today)
    }

    /// Günün değişip değişmediğini yeniden okuyor. Gece yarısını geçen bir oturum da
    /// yeni günü görmeli; ana ekran uygulama öne geldiğinde çağırıyor (ADR 0006).
    func refresh(now: Date = Date(), calendar: Calendar = .current) {
        let today = LocalCalendar.today(now: now, calendar: calendar)
        let rolled = quota.rolledOver(to: today)
        if rolled != quota {
            quota = rolled
        }
    }

    /// Yeni bir bulmaca başlatıldı. Günlük bulmaca kotadan muaf (ADR 0007); yarım kalan
    /// oyuna dönüş zaten burayı çağırmıyor.
    func noteStart(seed: UInt64, kind: PuzzleRecord.Kind) {
        guard kind != .daily else { return }
        let charged = quota.starting(seed: seed)
        if charged != quota {
            quota = charged
        }
    }

    func noteHint() {
        quota = quota.usingHint()
    }

    /// StoreKit katmanı bağlandığında (#61) yetkinin girdiği yer.
    func update(tier: PlayerTier) {
        self.tier = tier
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(quota) else { return }
        defaults.set(data, forKey: Key.quota)
    }
}
