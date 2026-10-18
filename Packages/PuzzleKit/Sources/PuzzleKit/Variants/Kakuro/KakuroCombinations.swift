/// Kesit uzunluğu ve toplamı için mümkün rakam kümeleri.
///
/// Kakuro'nun asıl tekniği bu: "üç hücrede 24" demek {7,8,9} demek, başka seçenek yok.
/// Deneyimli oyuncu bu tabloyu ezbere bilir; çözücü de bilmek zorunda.
///
/// Tablo bir kez hesaplanıyor: 1-9 rakamlarının 512 altkümesi uzunluk ve toplama göre
/// gruplanıyor. Her yayılım geçişinde yeniden üretmek, kesit aramasını kullanılamaz hale
/// getirirdi.
public enum KakuroCombinations {
    /// `[uzunluk][toplam]` → o uzunlukta ve toplamda mümkün rakam kümeleri.
    private static let table: [[[DigitSet]]] = {
        var result = [[[DigitSet]]](
            repeating: [[DigitSet]](repeating: [], count: 46),
            count: 10
        )
        for mask in 1..<512 {
            let set = DigitSet(rawValue: UInt16(mask) << 1)
            let length = set.count
            let sum = set.reduce(0, +)
            guard length <= 9, sum <= 45 else { continue }
            result[length][sum].append(set)
        }
        return result
    }()

    /// Verilen uzunluk ve toplam için mümkün rakam kümeleri. Hiçbiri yoksa boş.
    public static func sets(length: Int, sum: Int) -> [DigitSet] {
        guard (1...9).contains(length), (1...45).contains(sum) else { return [] }
        return table[length][sum]
    }
}
