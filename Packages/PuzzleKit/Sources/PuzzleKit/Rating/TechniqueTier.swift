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
    /// Kullanılan tekniklerin adları. Varyant başına sabit dizgeler; testlerde ve
    /// derecelendirme hatalarının ayıklanmasında okunabilir çıktı veriyor.
    public private(set) var techniques: Set<String>
    /// Kullanılan en ileri teknik seviyesi. Zorluk doğrudan bundan türüyor.
    public private(set) var highestTier: TechniqueTier
    /// Çıkarım adımı sayısı. Aynı seviyede kalan iki bulmacayı ayırmak için ipucu.
    public private(set) var stepCount: Int

    public init() {
        self.techniques = []
        self.highestTier = .basic
        self.stepCount = 0
    }

    public mutating func record(_ technique: String, tier: TechniqueTier) {
        techniques.insert(technique)
        if tier > highestTier {
            highestTier = tier
        }
        stepCount += 1
    }

    public var difficulty: Difficulty { highestTier.difficulty }
}
