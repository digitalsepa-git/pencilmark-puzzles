# ADR 0011 — Hitori üretici algoritması ve teknik seviyeleri

- Tarih: 2026-10-18
- Durum: kabul edildi
- Dayanak: ADR 0005 (boyutlar, zorluk çerçevesi), ADR 0010 (zorluk eşlemesi, `guessing` kararı)

## Bağlam

Faz 2'nin ilk varyantı. Hashi'de kurulan yaklaşım — bulmacayı değil çözümü kur, benzersizliğe
hat karar versin — tekrar kullanıldı. Ama Hitori'de yapısal bir fark var ve çözücü yazılırken
ortaya çıktı (PR #19):

**Hitori'nin kuralları yalnız beyazlarda tekrarı yasaklıyor; karalı hücrenin tekrar olması
zorunlu değil.** Yani hiçbir gruba girmeyen bir hücre, komşuluk ve bağlılık izin verdiği
sürece serbestçe karalanabilir. Elle kurulan 4×4 bir bulmaca tam bu yüzden beş çözümlü çıktı.

Sonuç: **Hitori'de benzersizlik ipucu değerlerinden değil karalama deseninin sıkılığından
geliyor.** Hashi'de ada dereceleri çözümü belirliyordu; burada deseni belirleyen şey
desenin kendi geometrisi.

## Karar

### 1. Karalama deseni maksimal kuruluyor

Hücreler rastgele sırada taranıyor; karalı komşusu olmayan her hücre karalanıyor, beyazlar
kopacaksa geri alınıyor. Geçiş bittiğinde **her beyaz hücre ya karalı bir komşuya sahip ya da
beyaz bölgenin kesme noktası** — ikisi de o hücrenin karalanmasını imkânsız kılıyor.

Maksimallik iki işi birden yapıyor: fazladan karalamayı imkânsız kılıyor, ve bir karalıyı
beyaza çevirip onun yerine bir beyazı karalama takasını da engelliyor.

Ölçülen karalı oran **%28-30** — yayınlanmış Hitori bulmacalarının tipik aralığı.

### 2. Beyazların değerleri Latin karesinden, karalıların değerleri bir beyazı tekrarlıyor

Latin karesi beyazların satır ve sütunlarda tekrarsızlığını kurulum gereği garanti ediyor.
Karalı hücreler, satır veya sütunlarındaki bir beyazın değerini alıyor: aksi halde o hücreyi
karalamak için sebep kalmıyor.

### 3. Zorluğun kolu üçlü deseni

İlk sürümde zorluk kolu "karalı hücrenin değerini komşu bir beyazdan kopyalama olasılığı"ydı
ve **hiç işe yaramadı** — her zorlukta bulmacaların %98'i Expert çıktı. Sebebi ölçümle
anlaşıldı: **iki üyeli bir grup hiçbir çıkarım vermiyor.** "Biri beyaz kalmak zorunda" demek,
hangisi olduğunu söylemiyor.

Çıkarım ancak grup üç üyeye çıktığında başlıyor. Beyazlar bir Latin karesinden geldiği için
bir satırda aynı değerde en fazla bir beyaz var; demek ki üç üyeli grup = bir beyaz + iki
karalı. Bu desen `karalı · beyaz · karalı` dizilimi, yani **klasik üçlü**: yan yana üç aynı
sayıda ortadaki beyaz, dıştakiler karalı.

Üretici bu dizilimi arıyor ve `triplePercent` olasılığıyla kuruyor. Çözücü ilk hamlesini
buradan buluyor; o karalılar komşularını beyaz yapıp çıkarım zincirini başlatıyor.

### 4. Easy ayrıca tam komşuluk istiyor

Yalnız bağlılıkla tutturulmuş bir beyaz ("karalasam bölge kopar") bulmacayı en az orta
seviye yapıyor. Temel tekniklerle açılan bir bulmaca için desen **bütün** beyazları
komşulukla tutturmak zorunda. Easy yerleşimi böyle bir desen bulunana kadar 40 kez deniyor;
bulamazsa elde olanla devam ediyor ve hat o adayı zorluk eşleşmesinde eliyor.

### 5. Teknik seviyeleri (Hitori'ye özel liste)

| Seviye | Teknik | Ne yapıyor |
|---|---|---|
| `basic` | komşuluk | Karalı hücrenin bütün komşuları beyaz |
| `basic` | grup | Beyaz kalan hücrenin grubundaki diğerleri karalı |
| `basic` | komşu ikili | Aynı gruptaki iki hücre komşuysa biri beyaz kalmak zorunda, gruptaki geri kalanlar karalı. Klasik "üçlü" kuralı bunun sonucu |
| `intermediate` | beyaz bölge bağlı mı | Kesinleşmiş beyazlar mümkün beyazlar üzerinden birbirine ulaşamıyorsa çelişki |
| `intermediate` | kopuk beyaz adacığı | Kesinleşmiş beyaz içermeyen bölgenin tamamı karalı |
| `intermediate` | **kesme noktası** | Karalanması beyaz bölgeyi koparacak hücre beyaz kalmak zorunda |
| `advanced` | tek adım varsayım | Bir hücreye durum varsayılıp çelişki aranıyor |
| `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor |

**Kesme noktası kuralı Hitori'nin asıl çalışan tekniği ve ilk sürümde eksikti.** Yalnız bölge
düzeyindeki kurallar vardı; "şu hücreyi karalasam ayrılır" çıkarımı varsayım tekniğine
kalıyordu ve üretilen her bulmaca ileri seviye çıkıyordu — yani Easy, Medium ve Hard hiç
üretilemiyordu.

Kesme noktaları **tek geçişte** bulunuyor (Tarjan, her alt ağaçtaki kesinleşmiş beyaz
sayısıyla birlikte). İlk uygulama her karar verilmemiş hücre için ayrı bir gezinme yapıyordu
ve Hard'da en kötü üretim süresini 280 ms'ye çıkarıyordu.

### 6. Zorluk eşlemesi ve sabitler

ADR 0010'daki kararlar aynen geçerli: **`guessing` reddediliyor**, Expert `advanced` içinden
varsayım sayısıyla ayrılıyor (eşik 2). `GenerationPipeline.maxAttempts` = 2500,
`HitoriSolver.hypothesisBudget` = 64 hücre.

| Zorluk | Izgara | Üçlü % | Komşu tekrar % | Tam komşuluk şartı |
|---|---|---|---|---|
| Easy | 5×5 | 100 | 90 | **var** |
| Medium | 7×7 | 70 | 60 | yok |
| Hard | 9×9 | 30 | 30 | yok |
| Expert | 11×11 | 0 | 10 | yok |

## Ölçüm

Apple Silicon, release. Yerleşim başına 400 aday, hat başına 20 üretim.

| Zorluk | Benzersiz | basic | intermediate | adv×1 | adv≥2 | guessing | Karalı oran |
|---|---|---|---|---|---|---|---|
| Easy | 344/400 | 173 | 150 | 13 | 8 | **0** | %30 |
| Medium | 298/400 | 0 | 258 | 26 | 14 | **0** | %28 |
| Hard | 223/400 | 0 | 194 | 21 | 8 | **0** | %28 |
| Expert | 224/400 | 0 | 194 | 24 | 6 | **0** | %28 |

| Zorluk | Deneme ort. | Deneme en kötü | Süre ortanca | Süre en kötü |
|---|---|---|---|---|
| Easy | 2 | 7 | 3,65 ms | 7,22 ms |
| Medium | 1 | 4 | 0,45 ms | 1,01 ms |
| Hard | 22 | 78 | 18,60 ms | 40,24 ms |
| Expert | 29 | 117 | 25,63 ms | **92,53 ms** |

Bütçe 2.000 ms; ölçülen en kötü 92,53 ms — **yirmi kat pay.** Hashi'de bu pay 65 kattı.

## Sonuçları

- **Teknik seviyesi dağılımı yalnız üreticinin değil çözücünün de testi.** Her bulmacanın
  ileri seviye çıkması, üreticinin kusuru değil çözücünün eksik olduğunun işaretiydi. Faz 2'nin
  kalan üç varyantında bu ölçüm aynı amaçla kullanılacak: dağılım tek seviyede yığılıyorsa
  önce çözücüye bakılacak.
- **Hitori'nin payı Hashi'den dar** (20 kat / 65 kat) ve asıl maliyet kesme noktası
  taramasında. Payın daralmasının sebebi algoritma değil kuralların doğası: Hashi'de ada
  dereceleri çözümü büyük ölçüde belirliyor, Hitori'de belirleyen şey geometri.
- **`basic` yalnız Easy yerleşiminde üretilebiliyor.** Medium ve üstü yerleşimler hiç temel
  seviye vermiyor; iki rejim gerçekten farklı. Tam komşuluk şartı olmasa Easy de üretilemezdi.
- **Easy'nin tam komşuluk şartı her zaman sağlanamıyor.** Desen 40 denemede bulunamazsa elde
  olanla devam ediliyor; hat o adayı eliyor. Easy'de kabul oranı buna rağmen %43.
- **`guessing` yine sıfır** (1.600 adayda). ADR 0010'un `guessing`'i eleme kararı iki varyantta
  da bedelsiz. Slitherlink'te tersi beklenmeli.
- **Hard ve Expert ince aralıkta** (%5,3 ve %1,5 kabul oranı), Hashi'deki gibi. Yerleşim
  parametreleri değişirse bu ölçüm tekrarlanmalı; `HitoriPropertyTests` en kötü deneme
  sayısını 1500'ün altında tutmayı test ediyor.

## Değerlendirilen alternatifler

- **Hitori için eşlemeyi kaydırmak** (`intermediate` → Easy, `advanced` → Medium…).
  `PuzzleGenerator.rate` buna izin veriyor ve kesme noktası kuralı eklenmeden önce tek çıkış
  yolu gibi görünüyordu. Reddedildi: tam komşuluk şartı `basic`'i üretilebilir kıldı ve
  zorluk etiketleri varyantlar arasında karşılaştırılabilir kaldı.
- **Karalı hücrelere tekrar değeri vermemek:** kurallar gereği geçerli, ama o zaman karalamak
  için sebep kalmıyor ve adayların neredeyse tamamı çok çözümlü çıkıyor.
- **Maksimal olmayan, seyrek desen:** fazladan karalama serbest kalıyor; ölçümde benzersizlik
  oranı kullanılamaz düzeye düşüyor.
- **Kesme noktası taramasını hücre başına gezinmeyle yapmak:** doğru ama Hard'da en kötü
  süreyi 280 ms'ye çıkarıyor — bütçeye göre rahatsız edici bir pay. Tek geçişli Tarjan aynı
  çıkarımı 36 ms'de veriyor.
- **Kesme noktası kuralını `advanced` saymak:** çözücü aynı sonucu varsayımla da buluyor, ama
  o zaman bütün bulmacalar ileri seviye oluyor ve dört seviyeli ölçek çöküyor. Kural klasik bir
  Hitori tekniği; oyuncu da aynı akıl yürütmeyi yapıyor.
