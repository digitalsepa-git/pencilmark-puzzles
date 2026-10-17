# ADR 0008 — İstatistik: ücretsiz ve Plus katmanları

- Tarih: 2026-10-17
- Durum: kabul edildi

## Bağlam

Brief iki yerde farklı şey söylüyor gibi duruyor: b.5 ve b.7 istatistik ekranını V1'in
parçası sayıyor ("varyant başına çözülen, en iyi süre, seri"), b.8 ise "istatistik geçmişi"ni
Plus özelliği olarak listeliyor. Çelişki değil, ayrımın adı konmamış: **toplam mı, geçmiş mi.**

## Karar

**Ücretsiz katman** — toplamlar ve güncel durum:

- Varyant başına çözülen bulmaca sayısı, zorluk kırılımıyla
- Varyant başına en iyi süre
- Güncel seri ve en uzun seri
- İpuçlu / ipuçsuz çözüm ayrımı (b.7: ipuçlu bulmaca çözüldü sayılır ama ayrı işaretlenir)

**Pencilmark Plus** — geçmiş ve eğilim:

- Bulmaca bazında tam geçmiş: tarih, süre, zorluk, kullanılan ipucu sayısı
- Günlük bulmaca takvimi (hangi günler çözüldü)
- Süre eğilimi: varyant ve zorluk başına zaman içinde gelişim

**Veri her katmanda eksiksiz toplanıyor ve saklanıyor; kapı yalnızca gösterimde.** Kullanıcı
üçüncü ayında Plus alırsa ilk gününden beri biriken geçmişini görüyor.

## Sonuçları

- "Verebildiğimiz veriyi verelim" kararının somut hali bu: ücretsiz katman boş bir ekran
  değil, dolu bir ekran görüyor. Rakip zayıflığı olarak işaretlenen "ilerleme sistemi yok"
  (Slitherlink lideri, b.3) ücretsiz katmanda da karşılanıyor.
- Geçmiş kaydı her bitmiş bulmaca için bir satır. Günde 4 bulmaca × 3 yıl ≈ 4.400 satır;
  SwiftData için önemsiz bir hacim, saklama maliyeti sorun değil.
- Plus iptal edilirse geçmiş silinmiyor, yalnızca gizleniyor. Veri kullanıcının.
- Paylaşım kartı (b.7) ücretsiz katmanda da çalışıyor; tek organik yayılma kanalını ödeme
  duvarının arkasına koymak intihar olurdu.

## Değerlendirilen alternatifler

- **Geçmişi yalnızca Plus alındıktan sonra kaydetmek:** saklama alanı kazandırırdı (önemsiz
  bir miktar) ve kullanıcıya "kaydedilmemiş geçmiş" olarak geri dönerdi. Abonelik satın alan
  birinin ilk gördüğü şeyin boş bir geçmiş olması, iptal sebebidir.
- **Tüm istatistiği ücretsiz yapmak:** Plus'ın üç gerekçesinden birini (b.8: sınırsız
  bulmaca, tüm zorluklar, istatistik geçmişi) siler.
- **İstatistiği V1'den çıkarmak:** b.5 kapsamında ve rakip zayıflığına doğrudan cevap.
