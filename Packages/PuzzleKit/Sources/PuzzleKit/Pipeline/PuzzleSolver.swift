/// Çözücünün verebileceği hatalar.
public enum SolverError: Error, Hashable, Sendable {
    /// Arama, kendisine ayrılan düğüm bütçesini tüketti.
    ///
    /// Bir hata değil, bir karar: aramayı sonsuza kadar sürdürmek yerine "bilmiyorum"
    /// demek. `uniquenessCheck` bunu `.indeterminate` sonucuna çeviriyor ve hat adayı eliyor.
    case searchBudgetExhausted
}

/// Varyantın çözücüsü.
///
/// Tek gereken yöntem `findSolutions(of:upTo:)`. Benzersizlik kontrolü bunun üzerine
/// uzantıda kuruludur ve varyant tarafından geçersiz kılınamaz — doğrulamanın
/// "performans gerekçesiyle kapatılamaz" olması (brief b.11) kod yapısıyla sağlanıyor.
public protocol PuzzleSolver: Sendable {
    associatedtype Definition: Sendable
    associatedtype Solution: Sendable

    /// En fazla `limit` çözüm bulur ve durur.
    ///
    /// Benzersizlik için iki çözüm yeter; tüm çözüm uzayını taramak gereksiz ve pahalı.
    func findSolutions(of definition: Definition, upTo limit: Int) throws -> [Solution]

    /// Çözüm izi. Zorluk derecelendirmesi bunun üzerinden yapılır (brief b.6).
    func trace(of definition: Definition) throws -> SolveTrace
}

extension PuzzleSolver {
    /// Üretim hattının karar adımı. Elenme sebebini de taşır.
    ///
    /// Çözücü arama bütçesini tüketirse sonuç `.indeterminate`: benzersizlik kanıtlanamadı.
    /// Diğer hatalar çağırana geçiyor.
    public func uniquenessCheck(_ definition: Definition) throws -> SolveOutcome<Solution> {
        let found: [Solution]
        do {
            found = try findSolutions(of: definition, upTo: 2)
        } catch SolverError.searchBudgetExhausted {
            return .indeterminate
        }

        switch found.count {
        case 0: return .none
        case 1: return .unique(found[0])
        default: return .multiple
        }
    }
}
