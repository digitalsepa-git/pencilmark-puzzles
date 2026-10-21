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
        rejectedIndeterminate: Int,
        /// Üreticinin aday kuramadığı denemeler — bkz. `attemptFailed`.
        rejectedAttemptFailed: Int
    )
    /// Üretici geçersiz bir aday kurdu; programlama hatası.
    case invalidCandidate(reason: String)
    /// Bu deneme aday üretemedi, ama başka bir tohumla üretebilir.
    ///
    /// `invalidCandidate`'ten farkı: o bir programlama hatası, bu normal bir sonuç. Kakuro'da
    /// gerekti (ADR 0013): üretici hedef zorluğu kendi yönlendirme döngüsünde arıyor ve bazı
    /// desenler o zorlukta benzersiz bulmaca vermiyor. Hat bunu eleme sayıyor ve devam ediyor.
    case attemptFailed(reason: String)
}
