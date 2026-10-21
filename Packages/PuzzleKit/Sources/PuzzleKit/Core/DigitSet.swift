/// 1...9 aralığındaki rakam kümesi, bit maskesi olarak.
///
/// Kalem işareti (aday notu) ve çözücünün aday takibi aynı tipi kullanır. `Set<Int>`
/// yerine bit maskesi: çözücü hücre başına milyonlarca kez kesişim/birleşim alıyor,
/// bunlar tek makine komutuna iniyor ve yığın ayırması olmuyor.
public struct DigitSet: Hashable, Sendable {
    /// Bit 1 → rakam 1 ... bit 9 → rakam 9. Bit 0 kullanılmıyor.
    public private(set) var rawValue: UInt16

    public static let validRange = 1...9
    private static let validMask: UInt16 = 0b11_1111_1110

    public static let empty = DigitSet(rawValue: 0)
    public static let all = DigitSet(rawValue: validMask)

    public init(rawValue: UInt16) {
        self.rawValue = rawValue & Self.validMask
    }

    public init() {
        self.rawValue = 0
    }

    public init<S: Sequence>(_ digits: S) where S.Element == Int {
        var mask: UInt16 = 0
        for digit in digits where Self.validRange.contains(digit) {
            mask |= 1 << UInt16(digit)
        }
        self.rawValue = mask
    }

    /// 1...n aralığını içeren küme. Calcudoku'da ızgara boyutuna göre aday havuzu.
    public static func upTo(_ n: Int) -> DigitSet {
        precondition(validRange.contains(n), "n 1...9 aralığında olmalı, gelen: \(n)")
        return DigitSet(1...n)
    }

    public var isEmpty: Bool { rawValue == 0 }

    public var count: Int { rawValue.nonzeroBitCount }

    /// Kümede tek rakam varsa onu döner. Çözücüde "tek aday kaldı" kontrolünün tamamı bu.
    public var singleDigit: Int? {
        guard count == 1 else { return nil }
        return rawValue.trailingZeroBitCount
    }

    public func contains(_ digit: Int) -> Bool {
        guard Self.validRange.contains(digit) else { return false }
        return rawValue & (1 << UInt16(digit)) != 0
    }

    public mutating func insert(_ digit: Int) {
        guard Self.validRange.contains(digit) else { return }
        rawValue |= 1 << UInt16(digit)
    }

    public mutating func remove(_ digit: Int) {
        guard Self.validRange.contains(digit) else { return }
        rawValue &= ~(1 << UInt16(digit))
    }

    /// Varsa siler, yoksa ekler. Kalem işareti girişinin tamamı bu davranış.
    public mutating func toggle(_ digit: Int) {
        if contains(digit) {
            remove(digit)
        } else {
            insert(digit)
        }
    }

    public func union(_ other: DigitSet) -> DigitSet {
        DigitSet(rawValue: rawValue | other.rawValue)
    }

    public func intersection(_ other: DigitSet) -> DigitSet {
        DigitSet(rawValue: rawValue & other.rawValue)
    }

    public func subtracting(_ other: DigitSet) -> DigitSet {
        DigitSet(rawValue: rawValue & ~other.rawValue)
    }

    /// Ortak rakamı yok mu. `intersection(_:).isEmpty`'den tek fark okunabilirlik.
    public func isDisjoint(with other: DigitSet) -> Bool {
        rawValue & other.rawValue == 0
    }
}

extension DigitSet: Sequence {
    public func makeIterator() -> AnyIterator<Int> {
        var remaining = rawValue
        return AnyIterator {
            guard remaining != 0 else { return nil }
            let digit = remaining.trailingZeroBitCount
            remaining &= remaining - 1
            return digit
        }
    }
}

extension DigitSet: CustomStringConvertible {
    public var description: String {
        isEmpty ? "{}" : "{" + map(String.init).joined(separator: ",") + "}"
    }
}
