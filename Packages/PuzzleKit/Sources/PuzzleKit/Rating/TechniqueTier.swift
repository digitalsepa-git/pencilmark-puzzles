/// Çözüm tekniğinin seviyesi.
///
/// Zorluk, ızgara boyutuna veya ipucu sayısına değil çözücünün bulmacayı bitirmek için
/// ihtiyaç duyduğu en ileri tekniğe göre belirlenir (brief b.6). "Expert" diye açılan
/// bulmaca kolay çıkarsa kullanıcı bunu yoruma yazıyor ve yorum bizim tek sıralama
/// varlığımız — bu yüzden derecelendirme tahmine bırakılmıyor.
public enum TechniqueTier: Int, Comparable, Hashable, Sendable, CaseIterable {
    /// Tek adayın zorunlu olduğu doğrudan çıkarımlar.
    case basic = 0
    /// Birden fazla hücreyi birlikte değerlendiren çıkarımlar.
    case intermediate = 1
    /// Zincir, kümelenme ve çelişkiye dayalı ileri çıkarımlar.
    case advanced = 2
    /// Mantıkla ilerlemenin kalmadığı, deneme gerektiren noktalar.
    case guessing = 3

    public static func < (lhs: TechniqueTier, rhs: TechniqueTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Seviye → zorluk eşlemesi. Beş varyantta ortak; hangi tekniğin hangi seviyeye
    /// girdiği varyanta özel ve her varyantın kendi ADR'sinde listelenir.
    public var difficulty: Difficulty {
        switch self {
        case .basic: .easy
        case .intermediate: .medium
        case .advanced: .hard
        case .guessing: .expert
        }
    }
}

/// Çözücünün bir bulmacayı çözerken hangi teknikleri kullandığının kaydı.
public struct SolveTrace: Hashable, Sendable {
    /// Teknik adı → kaç kez gerekti.
    ///
    /// Yalnız "kullanıldı mı" değil "kaç kez" de tutuluyor: aynı seviyede kalan iki bulmaca
    /// arasındaki fark genelde o seviyenin en pahalı tekniğinin kaç kez gerektiği. Hashi'de
    /// Hard ile Expert ayrımı tam olarak buna dayanıyor (ADR 0010).
    public private(set) var counts: [String: Int]
    /// Kullanılan en ileri teknik seviyesi.
    public private(set) var highestTier: TechniqueTier

    public init() {
        self.counts = [:]
        self.highestTier = .basic
    }

    /// Tekniğin kullanıldığını kaydeder.
    ///
    /// `times` bir geçişte birden fazla çıkarım yapılan teknikler için: tek tek kaydetmek
    /// yerine sayıyı bir kerede vermek, pahalı tekniklerin her çıkarımdan sonra yayılımı
    /// baştan başlatmasını gereksiz kılıyor (ADR 0012).
    public mutating func record(_ technique: String, tier: TechniqueTier, times: Int = 1) {
        guard times > 0 else { return }
        counts[technique, default: 0] += times
        if tier > highestTier {
            highestTier = tier
        }
    }

    /// Kullanılan tekniklerin adları.
    public var techniques: Set<String> { Set(counts.keys) }

    /// Toplam çıkarım adımı sayısı.
    public var stepCount: Int { counts.values.reduce(0, +) }

    public func count(of technique: String) -> Int { counts[technique] ?? 0 }

    public var difficulty: Difficulty { highestTier.difficulty }
}
