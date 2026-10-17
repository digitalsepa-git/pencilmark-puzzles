/// Metinden sabit tohum türetme.
///
/// `Hasher`/`hashValue` kullanılamaz: süreç başına rastgele tohumlanır, aynı metin iki
/// açılışta farklı değer verir. Günlük bulmaca buna bağlı olduğu için algoritma burada
/// sabit: FNV-1a 64 bit. Sabitleri yayınlanmış, uygulaması beş satır, platformdan bağımsız.
public enum Seed {
    private static let offsetBasis: UInt64 = 0xCBF2_9CE4_8422_2325
    private static let prime: UInt64 = 0x0000_0100_0000_01B3

    /// Üretim hattının sürüm etiketi.
    ///
    /// Tohuma dahil ediliyor. Üretici algoritması değişirse bu sayı artar ve o tarihten
    /// sonraki günlük bulmacalar yeni algoritmanın çıktısı olur; geçmiş günler eski
    /// bulmacayı artık üretemez. Bu bilinçli kabul — ayrıntı ADR 0006'da.
    public static let algorithmVersion = 1

    /// Bileşenleri birleştirip tohum üretir. Sıra anlamlıdır.
    public static func make(_ components: [String]) -> UInt64 {
        var hash = offsetBasis
        for (index, component) in components.enumerated() {
            if index > 0 {
                hash = mix(hash, byte: 0x1F)
            }
            for byte in component.utf8 {
                hash = mix(hash, byte: byte)
            }
        }
        return hash
    }

    public static func make(_ components: String...) -> UInt64 {
        make(components)
    }

    /// Günlük bulmacanın tohumu.
    ///
    /// Tarih bileşenleri `Date` değil `Int` olarak geliyor: hangi takvim ve hangi saat
    /// dilimine göre "bugün" olduğuna karar vermek uygulama katmanının işi (cihaz yerel
    /// saati — ADR 0006), motorun değil. PuzzleKit bu sayede Foundation'dan bağımsız kalıyor.
    public static func daily(
        variant: PuzzleVariantID,
        year: Int,
        month: Int,
        day: Int
    ) -> UInt64 {
        make([
            "daily",
            "v\(algorithmVersion)",
            variant.rawValue,
            "\(year)-\(month)-\(day)"
        ])
    }

    /// Serbest oyun tohumu. Günlük bulmacayla aynı tohum uzayına düşmemesi için
    /// ayrı önek alıyor; aksi halde kullanıcı günlük bulmacayı serbest oyunda görebilir.
    public static func free(
        variant: PuzzleVariantID,
        difficulty: Difficulty,
        counter: UInt64
    ) -> UInt64 {
        make([
            "free",
            "v\(algorithmVersion)",
            variant.rawValue,
            difficulty.rawValue,
            "\(counter)"
        ])
    }

    private static func mix(_ hash: UInt64, byte: UInt8) -> UInt64 {
        (hash ^ UInt64(byte)) &* prime
    }
}
