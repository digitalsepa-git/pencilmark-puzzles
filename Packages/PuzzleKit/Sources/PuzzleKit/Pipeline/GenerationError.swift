/// Üretim hattının hataları.
public enum GenerationError: Error, Hashable, Sendable {
    /// Verilen deneme sayısında hedef zorlukta benzersiz bulmaca bulunamadı.
    ///
    /// Elenme sayıları dahil: hangi sebepten kaç aday düştüğü, üreticinin neresinin
    /// bozuk olduğunu doğrudan gösteriyor.
    case attemptsExhausted(
        variant: PuzzleVariantID,
        difficulty: Difficulty,
        attempts: Int,
        rejectedUnsolvable: Int,
        rejectedAmbiguous: Int,
        rejectedWrongDifficulty: Int,
        /// Varyantın derecelendirmeyi reddettiği adaylar — bkz. `PuzzleGenerator.rate`.
        rejectedUnrated: Int,
        /// Benzersizliği arama bütçesi içinde kanıtlanamayan adaylar.
        rejectedIndeterminate: Int
    )
    /// Üretici geçersiz bir aday kurdu; programlama hatası.
    case invalidCandidate(reason: String)
}
