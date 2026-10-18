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
    /// Arama bütçesi tükendi; benzersiz olup olmadığı **bilinmiyor**.
    ///
    /// Kakuro'da ortaya çıktı (ADR 0013): benzersiz bir bulmacayı *kanıtlamak*, ikinci bir
    /// çözümün olmadığını göstermek demek ve bu arama ağacının tamamını tüketmeyi
    /// gerektiriyor. Büyük ızgaralarda bu saniyeler sürebiliyor.
    ///
    /// Böyle bir aday eleniyor. Benzersizliği kanıtlanamamış bulmaca kullanıcıya
    /// verilmiyor — brief b.11'in garantisi "benzersiz olduğunu *doğruladık*" demek,
    /// "muhtemelen benzersiz" demek değil.
    case indeterminate

    public var solution: Solution? {
        if case .unique(let solution) = self { return solution }
        return nil
    }

    public var isUnique: Bool {
        if case .unique = self { return true }
        return false
    }

    /// Benzersizlik kanıtlanamadı mı.
    public var isIndeterminate: Bool {
        if case .indeterminate = self { return true }
        return false
    }
}

extension SolveOutcome: Equatable where Solution: Equatable {}
