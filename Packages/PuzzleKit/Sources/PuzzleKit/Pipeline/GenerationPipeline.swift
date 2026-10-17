/// Doğrulanmış bir bulmaca. Yalnızca `GenerationPipeline` üretebilir.
///
/// `init` paket içine kapalı: bu tipe sahip olmak "benzersizlik kontrolünden geçti"
/// demek. Doğrulamayı atlayan bir yol bırakmamak için tek giriş noktası hat.
public struct GeneratedPuzzle<Definition: Sendable, Solution: Sendable>: Sendable {
    public let variant: PuzzleVariantID
    public let difficulty: Difficulty
    public let definition: Definition
    public let solution: Solution
    public let seed: UInt64
    /// Kaç aday elendikten sonra bulundu. Üretici kalitesinin ölçüsü; performans
    /// testlerinde ve ADR'lerde bu sayı kullanılıyor.
    public let attempts: Int

    // Kurucu bilinçli olarak yazılmadı: Swift'te public bir yapının sentezlenen
    // memberwise kurucusu `internal`'dır, yani bu tipi yalnızca PuzzleKit kurabilir.
    // Buraya `public init` eklemek doğrulamayı atlayan bir yol açar — eklenmeyecek.
}

/// Beş varyantın tamamında aynı işleyen üretim hattı (brief b.6).
///
/// ```
/// tohum → üret → çöz → BENZERSİZ Mİ? → evet: zorluk doğru mu? → evet: ver
///                         └─ hayır: ele, yeni alt tohumla baştan
/// ```
///
/// Benzersizlik kontrolü burada, hattın içinde. Varyantlar hattı kullanmak zorunda
/// (`GeneratedPuzzle` başka yerde kurulamıyor), hat da kontrolü atlayamıyor. Brief
/// b.11'deki "bu kontrol sürüm derlemesinde de açık kalır" maddesi bu yüzden bir
/// derleme bayrağı değil, tip sisteminin sonucu — `#if DEBUG` ile kapatılabilecek
/// bir yer yok.
public struct GenerationPipeline<Generator: PuzzleGenerator>: Sendable {
    public typealias Definition = Generator.Definition
    public typealias Solution = Generator.Solution

    public let generator: Generator
    /// Deneme üst sınırı. Aşılırsa hata; sessizce yanlış zorlukta bulmaca dönmez.
    public let maxAttempts: Int

    public init(generator: Generator, maxAttempts: Int = 500) {
        precondition(maxAttempts > 0, "Deneme sayısı pozitif olmalı")
        self.generator = generator
        self.maxAttempts = maxAttempts
    }

    /// Verilen tohumdan hedef zorlukta, benzersiz çözümlü bulmaca üretir.
    ///
    /// Aynı tohum her zaman aynı bulmacayı verir — günlük bulmacanın dayanağı bu.
    public func generate(
        difficulty: Difficulty,
        seed: UInt64
    ) throws -> GeneratedPuzzle<Definition, Solution> {
        let base = SeededGenerator(seed: seed)
        var unsolvable = 0
        var ambiguous = 0
        var wrongDifficulty = 0
        var unrated = 0

        for attempt in 1...maxAttempts {
            // Her deneme kendi alt akışından besleniyor; elenen denemenin tükettiği
            // bit sayısı sonraki denemeyi etkilemesin (bkz. SeededGenerator.substream).
            var rng = base.substream(attempt)
            let candidate = try generator.makeCandidate(difficulty: difficulty, using: &rng)

            switch try generator.solver.uniquenessCheck(candidate) {
            case .none:
                unsolvable += 1
            case .multiple:
                ambiguous += 1
            case .unique(let solution):
                let trace = try generator.solver.trace(of: candidate)
                guard let rated = generator.rate(trace, of: candidate) else {
                    // Varyant bu izi kabul edilemez buldu — örneğin bulmaca tek çözümlü
                    // olduğu halde mantıkla çözülemiyor.
                    unrated += 1
                    continue
                }
                guard rated == difficulty else {
                    wrongDifficulty += 1
                    continue
                }
                return GeneratedPuzzle(
                    variant: generator.variant,
                    difficulty: difficulty,
                    definition: candidate,
                    solution: solution,
                    seed: seed,
                    attempts: attempt
                )
            }
        }

        throw GenerationError.attemptsExhausted(
            variant: generator.variant,
            difficulty: difficulty,
            attempts: maxAttempts,
            rejectedUnsolvable: unsolvable,
            rejectedAmbiguous: ambiguous,
            rejectedWrongDifficulty: wrongDifficulty,
            rejectedUnrated: unrated
        )
    }
}
