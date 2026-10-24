/// Rakam giren varyantların (Kakuro, Calcudoku) hücre durumu.
///
/// Kalem işareti ve kesin giriş aynı hücrede birlikte bulunmaz: kullanıcı kesin değer
/// yazdığında adaylar gizlenir ama silinmez — bu kitle kesin değeri geri alıp adaylara
/// dönmeyi bekliyor, bu yüzden adaylar her durumda saklanıyor.
public struct DigitCell: Hashable, Sendable, Codable {
    public var value: Int?
    public var candidates: DigitSet

    public init(value: Int? = nil, candidates: DigitSet = .empty) {
        self.value = value
        self.candidates = candidates
    }

    public static let empty = DigitCell()

    public var isEmpty: Bool { value == nil && candidates.isEmpty }

    public var isFilled: Bool { value != nil }
}

/// Hitori'nin hücre durumu: karala / beyaz bırak / karar verilmedi.
public enum ShadeState: UInt8, Hashable, Sendable, CaseIterable, Codable {
    case unknown
    case shaded
    case marked

    /// Brief b.7'deki dokunma döngüsü: karala → işaretle → boş.
    public var next: ShadeState {
        switch self {
        case .unknown: .shaded
        case .shaded: .marked
        case .marked: .unknown
        }
    }
}

/// Slitherlink'in kenar durumu: çizgi / çarpı / karar verilmedi.
public enum EdgeState: UInt8, Hashable, Sendable, CaseIterable, Codable {
    case unknown
    case line
    case cross

    /// Brief b.7'deki dokunma döngüsü: çizgi → çarpı → boş.
    public var next: EdgeState {
        switch self {
        case .unknown: .line
        case .line: .cross
        case .cross: .unknown
        }
    }
}
