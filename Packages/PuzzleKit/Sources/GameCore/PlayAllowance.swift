import PuzzleKit

/// Oyuncunun katmanı. V1'de yalnız iki değer var ve `plus`'ı veren şey StoreKit; o
/// bağlantı ayrı iş (#61). Buradaki tip, kotanın ve kilidin StoreKit'ten **önce**
/// yazılabilmesi ve sınanabilmesi için var.
public enum PlayerTier: String, CaseIterable, Hashable, Sendable, Codable {
    case free
    case plus
}

/// Ücretsiz katmanın günlük sınırları (ADR 0007, brief b.8).
public enum FreeTier {
    /// Günde kaç yeni bulmaca başlatılabilir. Günlük bulmaca bunun dışında.
    public static let dailyPuzzleLimit = 3
    /// Günde kaç ipucu. Bulmaca başına değil ortak havuz: bulmaca başına sınır,
    /// oyuncuyu ipucu toplamak için bulmacayı sıfırlamaya iterdi.
    public static let dailyHintLimit = 3
}

/// Bir günün kota sayacı (ADR 0007'nin saydığı üç alan).
///
/// Başlatılan bulmacalar sayı olarak değil **kimlik** olarak tutuluyor: aynı bulmacanın
/// başlatılması günde bir kez düşmeli ve ekran yeniden kurulduğunda (örneğin üretim
/// hatasından sonra "tekrar dene") sayaç ikinci kez harcanmamalı.
public struct DailyQuota: Equatable, Sendable, Codable {
    /// En son görülen yerel gün.
    public private(set) var day: CalendarDay
    /// O gün başlatılan bulmacaların tohumları.
    public private(set) var startedSeeds: Set<UInt64>
    public private(set) var hintsUsed: Int

    public init(day: CalendarDay, startedSeeds: Set<UInt64> = [], hintsUsed: Int = 0) {
        self.day = day
        self.startedSeeds = startedSeeds
        self.hintsUsed = hintsUsed
    }

    public var startedCount: Int { startedSeeds.count }

    /// Günün değişmesiyle sıfırlanmış hâli.
    ///
    /// Geriye giden saat yok sayılıyor (ADR 0007): cihazın tarihi dünden geriye
    /// alınırsa sayaç yenilenmiyor ve saklanan gün de geri gitmiyor. İleri almak
    /// yeniliyor — kapatmak sunucu gerektirir ve V1 çevrimdışı.
    public func rolledOver(to today: CalendarDay) -> DailyQuota {
        guard today.dayNumber > day.dayNumber else { return self }
        return DailyQuota(day: today)
    }

    /// Bulmacayı başlatılmış sayıyor. Aynı tohum için ikinci çağrı bir şey değiştirmiyor.
    public func starting(seed: UInt64) -> DailyQuota {
        var copy = self
        copy.startedSeeds.insert(seed)
        return copy
    }

    public func usingHint() -> DailyQuota {
        var copy = self
        copy.hintsUsed += 1
        return copy
    }
}

/// Katman ve sayaç birlikte: "şunu yapabilir mi" sorusunun tek cevap yeri.
///
/// Saf ve saklamadan habersiz. Kuralların burada olmasının sebebi, yanlış olması en
/// muhtemel kısmın (kotanın ne zaman düştüğü, neyin muaf olduğu) simülatör açmadan
/// sınanabilmesi — ADR 0017'nin saklama ile hesabı ayırırken kullandığı gerekçe.
public struct PlayAllowance: Equatable, Sendable {
    public let tier: PlayerTier
    public let quota: DailyQuota

    public init(tier: PlayerTier, quota: DailyQuota) {
        self.tier = tier
        self.quota = quota
    }

    public var isUnlimited: Bool { tier == .plus }

    /// Kalan bulmaca hakkı; `nil` sınırsız demek.
    public var remainingPuzzles: Int? {
        guard !isUnlimited else { return nil }
        return max(FreeTier.dailyPuzzleLimit - quota.startedCount, 0)
    }

    /// Kalan ipucu; `nil` sınırsız demek.
    public var remainingHints: Int? {
        guard !isUnlimited else { return nil }
        return max(FreeTier.dailyHintLimit - quota.hintsUsed, 0)
    }

    public func isUnlocked(_ difficulty: Difficulty) -> Bool {
        isUnlimited || difficulty.isFreeTier
    }

    /// Yeni bir bulmaca başlatılabilir mi.
    ///
    /// Günlük bulmaca kotadan muaf (ADR 0007: ücretsiz oyuncu günde 4 bulmaca oynuyor;
    /// günlük bulmaca alışkanlık motoru ve paylaşım kartının çalışması ona bağlı).
    /// Yarım kalan bulmacaya dönmek de harcamıyor: hak zaten başlatılırken düşmüştü.
    public func canStart(
        _ difficulty: Difficulty,
        kind: PuzzleRecord.Kind,
        isResuming: Bool
    ) -> Bool {
        guard isUnlocked(difficulty) else { return false }
        guard kind != .daily, !isResuming else { return true }
        return (remainingPuzzles ?? 1) > 0
    }

    public var canUseHint: Bool { (remainingHints ?? 1) > 0 }
}
