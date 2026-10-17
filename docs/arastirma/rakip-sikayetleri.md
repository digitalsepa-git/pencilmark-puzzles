# Rakip şikâyet analizi

- Tarih: 17 Ekim 2026 · ABD mağazası
- Taranan: 13 uygulama, **923 yorum**, bunların **186'sı 1-3 yıldız**
- Yöntem ve betik: [`arac/rakip-yorum-tarama.py`](arac/rakip-yorum-tarama.py)

Brief b.13 Faz 0: *"Hitori liderinin App Store yorumları okunur, tekrar eden şikâyetler
`docs/` altına çıkarılır — bunlar Faz 3'te özellik listesine dönüşecek."* Tarama Hitori ile
sınırlı tutulmadı: Hitori liderinin yazılı yorum sayısı çok az (44 oy, RSS'te 4 yorum), tek
başına örneklem değil. Beş varyantın tamamındaki güçlü uygulamalar tarandı.

Yorum metinleri repoya kaydedilmedi — üçüncü parti içerik ve kişisel veri. Aşağıdaki
maddeler özetleme; betik yeniden koşturulunca sayılar güncellenir.

---

## 1. Önce bir düzeltme: briefteki lider tablosu eksik

Bu bölüm b.2 ve b.3'teki veriyle çelişiyor, o yüzden en başta. **Kapsam değişikliği
önermiyorum**, ama tablo olduğu gibi kalırsa iki varyantta rekabeti olduğundan zayıf
görüyoruz.

| Varyant | Briefteki lider | Yorum | Gerçek en güçlü uygulama | Yorum | Son güncelleme |
|---|---|---|---|---|---|
| Kakuro | Real Kakuro | 2.626 | Real Kakuro (ama bakımsız) | 2.626 | **2023-07** |
| | | | Kakuro: Number Crossword | 1.939 | 2026-07 |
| Calcudoku | Mathdoku+ | 435 | **Calcudoku · Sudoku-like Puzzle** | **1.557** | 2026-09 |
| Slitherlink | Slitherlink: Loop the Snake | 461 | aynısı | 461 | 2026-04 |
| Hashi | Hashi: Linkdoku Bridges | 32 | **Hashi: Bridges** | **1.031** | 2026-07 |
| Hitori | Hitori - Logic Puzzles | 44 | Real Hitori | 127 | 2017-09 |

Briefteki tablo muhtemelen arama sonucunun **ilk sırasını** lider saymış, en çok yorumlu
uygulamayı değil. İki yerde sonuç ciddi şekilde değişiyor:

**Hashi.** Brief "lider yalnızca 32 yorumda — kategori fiilen sahipsiz … en düşük giriş
eşiği" diyor. Gerçekte Conceptis Ltd.'nin *Hashi: Bridges* uygulaması 1.031 oy, 4,9 puan,
Temmuz 2026'da güncellenmiş ve düşük yıldızlı yorum oranı **%4** — taradığım en memnun
kullanıcı kitlesi. Hashi en kolay giriş değil, en zor giriş.

**Calcudoku.** Brief "kategori neredeyse boş, lider 435 yorumda" diyor ve bunu "en değerli
bulgu" olarak işaretliyor. Mathdoku+ gerçekten terk edilmiş (son güncelleme **2016**), ama
kategoride Matthew Murphy'nin *Calcudoku · Sudoku-like Puzzle* uygulaması 1.557 oyla duruyor
ve Eylül 2026'da güncellenmiş. KenKen marka kilidi argümanı geçerli; "kategori boş" kısmı
değil.

**Örüntü: Conceptis Ltd. tek başına üç varyantın zirvesinde** (Kakuro 1.939, Hashi 1.031,
Slitherlink 461) ve üçü de aktif bakımlı, üçü de düşük şikâyet oranlı. Brief'in "rakiplerin
yarısı terk edilmiş" tespiti Real Kakuro, Real Hitori, Mathdoku+, Kakuro Endless için doğru
— ama Conceptis için değil.

**Bu stratejiyi bozmuyor, çünkü Conceptis her bulmacayı ayrı uygulama olarak yayınlıyor.**
"Beş bulmaca tek uygulamada" farkı duruyor ve ortak ilerleme/istatistik hiçbirinde yok.
Değişen şey beklenti: Hashi'de "erken girip yorum biriktirmek" gerçekçi değil, Hitori'de
gerçekçi.

---

## 2. Şikâyet temaları, sıklığa göre

186 düşük yıldızlı yorumda:

| # | Tema | Düşük yorum | Pay | Bizim V1'de ne yapıyoruz |
|---|---|---|---|---|
| 1 | **Reklam** | 59 | %32 | Reklam yok (b.8). En büyük silinme sebebi bizde yok. |
| 2 | **Performans / çökme** | 36 | %19 | b.11 bütçeleri; üretim arka planda, arayüz kilitlenmiyor |
| 3 | Ödeme modeli | 21 | %11 | Ömür boyu seçeneği var; paywall 3 bulmaca bitmeden görünmüyor |
| 4 | İpucu davranışı | 13 | %7 | İpucu tek hücre açıyor, sayısı kaydediliyor |
| 5 | **Kalem işareti kalitesi** | 12 | %6 | Aşağıda ayrı bölüm — en somut fırsat |
| 6 | İstatistik / ilerleme yok | 12 | %6 | Ortak istatistik, seri, ücretsizde de dolu ekran (ADR 0008) |
| 7 | Bulmaca tükenmesi | 11 | %6 | Cihazda sınırsız üretim; paket yok (b.9) |
| 8 | Geri alma | 10 | %5 | Sınırsız geri/ileri alma (b.7) |
| 9 | Öğretici / kurallar | 9 | %5 | Etkileşimli öğretici (ADR 0009) |
| 10 | Okunabilirlik / kontrast | 8 | %4 | Yüksek kontrast, Dynamic Type, karanlık mod |
| 11 | Terk edilmişlik | 7 | %4 | Aktif bakım — brief'in üç farkından biri |
| 12 | İlerleme kaybı | 5 | %3 | Her hamlede otomatik kayıt (b.7) |
| 13 | Tahmin gerektirme | 2 | %1 | Aşağıda ayrı bölüm |

### Reklam: en büyük tek silinme sebebi

59 düşük yorumun neredeyse tamamı tek uygulamada (Calcudoku · Murphy) ve aynı şeyi
söylüyor: her bulmacadan sonra zorunlu, uzun, sesli tam ekran video; kapatma düğmesi
bulunamıyor; **reklamı kaldırma seçeneği yok.** Birden fazla kullanıcı reklamsız sürüm için
2-5 dolar ödemeye hazır olduğunu yazmış. Bir yorum mağaza ekran görüntülerinde reklam
görünmemesini doğrudan aldatma olarak nitelendirmiş.

İki sonuç:

1. **B.8'deki reklam kararı veriyle doğrulandı** ve gerekçesi tahmin edilenden güçlü.
2. **Paywall'ın çerçevesi önemli.** Bu kitle ödemeyi "reklamı kaldırmak" olarak tanıyor;
   bizde kaldırılacak reklam yok. Paywall metni hacim ve zorluk açmaya odaklanmalı, "reklamsız"
   vurgusu yapmamalı — yoksa kullanıcı uygulamada reklam olduğunu sanıyor.

### Performans: donmanın sebebi büyük olasılıkla üretim

Üç ayrı uygulamada aynı tarif: Real Kakuro birkaç bulmacadan sonra tekrar tekrar çöküyor;
Kakuro: Number Crossword 10-15 saniye donuyor; Hitori lideri hamleleri gecikmeyle algılıyor
ve tamamlanan bölümü birkaç hamle geriye sarıyor.

**10-15 saniyelik donma, ana iş parçacığında koşan bulmaca üretimi gibi görünüyor.** Brief
b.11 bunu zaten yasaklıyor ("üretim arayüzü kilitlemez; arka planda koşar ve ilerleme
gösterilir"). Bu madde kozmetik değil: rakiplerin en yüksek puanlı uygulamasını bile aşağı
çeken şey bu.

### Kalem işareti: var/yok değil, kalite meselesi

En somut ürün fırsatı burada. Şikâyetler tek tek özellik isteği:

| Şikâyet | Faz 3'te karşılığı |
|---|---|
| Kalem modunda olup olmadığı belli olmuyor | Mod göstergesi: araç çubuğunda durum + hücrede punto farkı |
| Satır/sütunda bir rakam kullanılınca adaylar kendiliğinden güncellenmiyor | **Otomatik aday temizleme** (ayarlardan kapatılabilir) |
| Birden çok hücreyi seçip hepsine aynı adayı yazmak mümkün değil | Çoklu hücre seçimi + toplu aday |
| Adayların hücre içindeki yerleşimi sabit değil | Aday yerleşimi rakam değerine sabitli (1 sol üst … 9 sağ alt) |
| Bir uygulamada aday notu özelliği hiç çalışmıyor | Anlık görüntü testleriyle korunacak |

Otomatik aday temizleme doğrudan talep edilmiş ve rakiplerin hiçbirinde düzgün çalışmıyor.
Kakuro ve Calcudoku'da bu kitle kalem işareti olmadan oynamıyor (b.7) — buradaki kalite
farkı tek başına bir inceleme yorumu sebebi.

### "Tahmin gerektirme" — benzersizlikten daha önemli bir ayrım

Brief b.3, güvenilir üreticiyi üç farktan biri sayıyor ve çok/çözümsüz bulmacayı *"bu
kategorideki en yaygın şikâyet konusu"* olarak tanımlıyor. **923 yorumda bu tema en az
rastlanan tema** (15 yorum, yalnız 2'si düşük yıldız). Teknik karar doğru ama rekabet
gerekçesi olduğu kadar güçlü değil.

Buna karşılık ortaya çıkan şey daha ince ve daha önemli: Slitherlink liderine gelen şikâyet
"birden fazla çözüm var" değil, **zor seviyelerde mantıkla ilerlemenin bittiği ve tahmin
gerekmeye başladığı**. Bir bulmacanın tek çözümü olabilir ve yine de mantıkla
çözülemeyebilir.

Bizim `TechniqueTier`'ımız bunu tam olarak ayırıyor: `guessing` seviyesi, mantıkla
ilerlenemeyen bulmaca demek. **Öneri: `guessing` seviyesini hiçbir zorlukta kullanıcıya
vermemek.** Expert = `advanced`, ve `guessing` eleme sebebi. Bu, ADR 0005'teki seviye →
zorluk eşlemesini değiştirir; kararı Faz 1'de Hashi'nin gerçek dağılımı ölçülünce
kesinleştireceğim.

---

## 3. Faz 3'e taşınan maddeler

Arayüz fazında özellik listesine girecekler — her biri yorum verisine dayanıyor:

- [ ] Kalem modu göstergesi (araç çubuğu durumu + hücrede punto farkı)
- [ ] Otomatik aday temizleme, ayarlardan kapatılabilir
- [ ] Çoklu hücre seçimi ve toplu aday yazma
- [ ] Aday yerleşimi rakam değerine sabit
- [ ] Üretim kesinlikle arka planda; 300 ms'den uzun sürerse ilerleme göstergesi
- [ ] Paywall metni hacim/zorluk üzerinden; "reklamsız" vurgusu yok
- [ ] Öğretici yalnızca varyant ilk kez açıldığında, bir kez; tekrar sormuyor
- [ ] Mağaza ekran görüntüleri gerçek oyun ekranı (b.12 ile aynı yöne bakıyor)
- [ ] Tema değişikliği kontrastı düşürmüyor; karanlık mod anlık görüntü testinde

Son maddenin sebebi: Hitori liderinin kullanıcılarından biri arka plan değişikliğinin
görünürlüğü bozduğunu yazmış ve puanını düşürmüş. Tema değişiklikleri bu kitlede ucuz değil.

## 4. Doğrulanan brief kararları

Veri şunları destekliyor, tartışmaya gerek yok:

- **Reklamsızlık** (b.8) — en büyük silinme sebebi
- **Ömür boyu satın alma seçeneği** (b.8) — ödeme modeli şikâyetleri abonelik direnci gösteriyor
- **Performans bütçeleri ve arka planda üretim** (b.11) — ikinci en büyük şikâyet
- **Cihazda sınırsız üretim, paket yok** (b.9) — "bulmaca tükendi" 11 düşük yorumda
- **Otomatik kayıt** (b.7) — ilerleme kaybı gerçek ve puana yansıyor
- **Aktif bakım** (b.3) — terk edilmişlik 7 düşük yorumda açıkça yazılı
