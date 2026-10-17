# ADR 0006 — Günlük bulmaca: tohum, saat dilimi, varyant eşlemesi

- Tarih: 2026-10-17
- Durum: kabul edildi

## Bağlam

Günlük bulmaca tek organik yayılma kanalımız (b.7): çözüm sonrası paylaşım kartı. Kartın
anlamı "aynı bulmacayı sen de çözdün mü" olduğu için, "herkes aynı bulmacayı görür"
gereksinimi pazarlama metni değil teknik şart.

Üç ayrı soru cevapsızdı: "bugün" hangi saat dilimine göre, üretici algoritması değişirse
geçmiş günlere ne olur, ve 5 varyant 7 güne nasıl dağılır.

## Karar

**Gün = cihazın yerel takvim günü.** Kullanıcının kendi gecesi yarısında yeni bulmaca
açılıyor. Aynı yerel tarihte dünyanın her yerinde aynı bulmaca görünüyor; değişen yalnızca
geçiş anı.

**Tohum** `Seed.daily` ile: `FNV-1a("daily" | "v{sürüm}" | varyant | "YYYY-M-D")`.
Bileşenler arasında ayraç var; olmasa "2026-1-12" ile "2026-11-2" çakışırdı (testle korunuyor).

**Üretici algoritması sürümlenir ve yayınlandıktan sonra donar.** Algoritma değişirse yeni
bir sürüm numarası alır ve **ileri bir tarihten itibaren** yürürlüğe girer; o tarihe kadarki
günler eski sürümle üretilmeye devam eder. Tarih → sürüm eşlemesi uygulama katmanında,
PuzzleKit'te değil (motor Foundation'a bağımlı değil, tarih bilmiyor).

**Varyant eşlemesi** haftanın gününe sabit:

| Pzt | Sal | Çar | Per | Cum | Cmt | Paz |
|---|---|---|---|---|---|---|
| Kakuro | Calcudoku | Slitherlink | Hashi | Hitori | Kakuro | Calcudoku |

Hafta sonu Kakuro ve Calcudoku'ya gidiyor: arama talebi en yüksek ikisi (35.447 ve 29.402 —
b.2) ve kalem işareti derinliği olan ikisi, hafta sonu oturumları da daha uzun.

**Zorluk sabit Medium**, ücretsiz kullanıcı oynayabiliyor.

## Sonuçları

- Saat dilimi değiştiren bir kullanıcı (uçuş) aynı günü iki kez görebilir veya bir günü
  atlayabilir. Seri sayımı yerel günlere göre; atlanan gün seriyi kırar. Sunucusuz bir
  üründe bunun temiz çözümü yok, kabul edildi.
- **Güncellemeyen kullanıcı** bir sürüm geçişinden sonra başkalarından farklı bulmaca görür.
  Paylaşım kartı bulmacanın kendisini göstermediği (varyant, tarih, süre, ipucu işareti)
  için bu neredeyse görünmez. Alternatifi algoritmayı sonsuza kadar dondurmaktı — Faz 1'de
  performans bütçesi tutmazsa gereken algoritma değişikliğini imkânsız kılardı.
- Günlük bulmaca ücretsiz katmanın 3 bulmaca kotasından sayılmıyor (ADR 0007).
- Varyant eşlemesi sabit olduğu için Hashi'yi arayıp gelen kullanıcı günlük bulmacada
  Hashi'yi yalnızca perşembe görüyor; varyant kartından her zaman serbest oyun oynanabiliyor.

## Değerlendirilen alternatifler

- **UTC'ye göre gün:** geçiş anı herkes için aynı, "aynı bulmaca" iddiası daha temiz. Kabul
  edilmedi: ABD batı kıyısında bulmaca akşam 17:00'de değişir, bu kullanıcı için kafa
  karıştırıcı — kitle sabah kahvesiyle bulmaca çözen kitle.
- **Algoritmayı sonsuza dondurmak:** cross-sürüm tutarlılığı tam olurdu, performans
  iyileştirmesini bloke ederdi.
- **Sürüm geçişini anında uygulamak:** geçiş günü güncelleyen ve güncellemeyen kullanıcılar
  arasında fark yaratır; ileri tarihli geçiş bu farkı güncelleme penceresi kadar erteliyor.
- **Günlükte varyant rotasyonunu rastgeleleştirmek:** b.14 sabit eşlemeyi varsayılan aldı ve
  sabit eşleme alışkanlık kuruyor ("perşembe Hashi günü").
