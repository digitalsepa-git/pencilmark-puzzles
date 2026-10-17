/// Varyant başına dört zorluk (brief b.5).
public enum Difficulty: String, CaseIterable, Hashable, Sendable, Codable {
    case easy
    case medium
    case hard
    case expert

    /// Ücretsiz katmanda açık olan zorluklar (brief b.8).
    public var isFreeTier: Bool {
        self == .easy || self == .medium
    }
}

/// Beş varyantın kimliği. Kayıt şemasında ve günlük bulmaca tohumunda kullanılıyor,
/// bu yüzden `rawValue` değerleri sabit kalmak zorunda.
public enum PuzzleVariantID: String, CaseIterable, Hashable, Sendable, Codable {
    case kakuro
    case calcudoku
    case slitherlink
    case hashi
    case hitori

    /// Arayüzde görünen ad. Markalı adlar (KenKen, KenDoku) asla kullanılmaz — brief b.4.
    public var displayName: String {
        switch self {
        case .kakuro: "Kakuro"
        case .calcudoku: "Calcudoku"
        case .slitherlink: "Slitherlink"
        case .hashi: "Hashi"
        case .hitori: "Hitori"
        }
    }
}
