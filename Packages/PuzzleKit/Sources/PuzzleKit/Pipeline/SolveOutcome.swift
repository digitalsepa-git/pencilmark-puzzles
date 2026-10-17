/// Benzersizlik kontrolünün üç olası sonucu.
///
/// Üretim hattının karar adımı budur (brief b.6): yalnızca `unique` kullanıcıya gider,
/// `none` ve `multiple` elenir ve yeni tohumla baştan üretilir.
public enum SolveOutcome<Solution: Sendable>: Sendable {
    /// Çözümü yok. Üretici hatalı bir aday kurdu.
    case none
    /// Tam olarak bir çözümü var. Kullanıcıya verilebilir.
    case unique(Solution)
    /// Birden fazla çözümü var. Bu kategorideki en yaygın şikâyet konusu; elenir.
    case multiple

    public var solution: Solution? {
        if case .unique(let solution) = self { return solution }
        return nil
    }

    public var isUnique: Bool {
        if case .unique = self { return true }
        return false
    }
}

extension SolveOutcome: Equatable where Solution: Equatable {}
