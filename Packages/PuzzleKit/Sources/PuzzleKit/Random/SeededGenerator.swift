/// Tohumdan türeyen, sürümler ve platformlar arası sabit sözde rastgele üretici.
///
/// Swift'in `SystemRandomNumberGenerator`'ı tohumlanamaz, `Hasher` ise süreç başına
/// rastgele tohumlanır — ikisi de günlük bulmaca için kullanılamaz. Günlük bulmacada
/// "herkes aynı bulmacayı görür" gereksinimi (brief b.5) üreticinin bit bit aynı diziyi
/// vermesine bağlı, bu yüzden algoritma burada sabitlendi: SplitMix64.
///
/// SplitMix64 seçimi: sabitleri yayınlanmış ve değişmez, durumu tek `UInt64`, adım başına
/// birkaç komut. İstatistiksel kalitesi bulmaca üretimi için fazlasıyla yeterli; kriptografik
/// kullanım için değil ve öyle kullanılmayacak.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Aynı tohumdan bağımsız alt akışlar türetir.
    ///
    /// Üretim hattı her denemede yeni bir aday üretiyor; denemeler aynı akıştan devam
    /// etse elenen denemenin tükettiği bit sayısı sonraki denemeyi etkilerdi ve hattın
    /// çıktısı deneme sayısına bağlı hale gelirdi. Alt akış bunu ayırıyor.
    public func substream(_ index: Int) -> SeededGenerator {
        var mixer = SeededGenerator(seed: state ^ (UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9))
        _ = mixer.next()
        return mixer
    }
}
