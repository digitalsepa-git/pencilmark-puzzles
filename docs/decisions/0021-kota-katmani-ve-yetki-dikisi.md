# ADR 0021 — Kota katmanı ve yetki dikişi

- Tarih: 2026-10-25
- Durum: kabul edildi
- Dayanak: ADR 0007 (ücretsiz katman mekaniği), brief b.8 (paywall kuralları),
  ADR 0017 (saklama katmanı), ADR 0006 (yerel gün)

## Bağlam

ADR 0007 ücretsiz katmanın **ne** olduğunu karara bağlamıştı: günde 3 bulmaca + günlük
bulmaca, Easy ve Medium, günde 3 ipucu, geriye giden saat yok sayılıyor. Uygulamada
hiçbiri yoktu.

Yazarken dört soru çıktı ve hiçbirinin cevabı ADR 0007'de yoktu: Plus'ı veren şey henüz
yokken (StoreKit #61'de) katman nereden okunacak, sayaç nereye yazılacak, hak tam olarak
hangi anda düşecek ve sınıra çarpan oyuncu ne görecek.

## Karar

### 1. Katman ayrı bir değer; StoreKit'in bağlanacağı yer bugünden belli

`PlayerTier` (`free` / `plus`) GameCore'da, `PlayLimits.update(tier:)` App'te. Bugün
katman sabit `free`; #61 StoreKit yetkisini oraya yazacak.

Alternatif, kota ve kilit kodunu StoreKit gelene kadar hiç yazmamaktı. Reddedildi: kota
mantığının yanlış olması en muhtemel kısmı (neyin muaf olduğu, hakkın ne zaman düştüğü)
satın almayla ilgisiz ve bugün sınanabilir. StoreKit'i beklemek, iki işi tek PR'da
birleştirip ikisini de denetlenemez yapardı.

### 2. Kural GameCore'da, sayaç App'te

`PlayAllowance` saf bir değer: katman + günün sayacı, "şunu yapabilir mi" sorusunun tek
cevap yeri. Saklama `PlayLimits`'te. Ayrım ADR 0017 §1'in aynısı ve aynı faydayı veriyor:
kuralların tamamı Linux'ta 1x maliyetle sınanıyor, simülatörde sınanan şey yalnız yazma
ve okuma.

### 3. Sayaç `UserDefaults`'ta, SwiftData'da değil

Saklanan şey tek bir satır: gün, o gün başlatılan tohumlar, kullanılan ipucu. Geçmişi
yok, sorgulanmıyor, her gün üzerine yazılıyor — `Preferences`'ın kendi gerekçesiyle aynı
durum. SwiftData'ya koymak bir şema girişi ve ilk yayından sonra bir göç adımı getirirdi
(ADR 0017 §4), karşılığında hiçbir şey vermeden. Kaybolması da zararsız: en kötü
ihtimalle oyuncu bir gün fazladan oynar.

### 4. Hak, zorluk ekranında değil bulmaca ekranında düşüyor

Kota "başlatma" üzerinden sayılıyor (ADR 0007) ve başlatılan şey bulmaca ekranı. Sayaç
`PuzzleScaffold`'ta, yarım kalan oyun **benimsenemediğinde** düşüyor; benimsendiğinde
düşmüyor, çünkü o hak zaten başlatılırken gitmişti.

Sayma kimlik üzerinden: o gün başlatılan tohumlar bir kümede duruyor. Sayı tutsaydı aynı
ekranın ikinci kez kurulması (üretim hatasından sonra "tekrar dene") hakkı ikinci kez
harcardı.

### 5. Kilitli satır gizlenmiyor, kapalı düğme kullanılmıyor

Kilitli zorluk listede kalıyor: soluk, kilit simgeli ve "Plus" etiketli. Gizlenen bir şey
açıklanamaz ve oyuncu neyi kaçırdığını göremez.

İpucu düğmesi hak bitince **kapanmıyor**; dokunulduğunda sebebi anlatılıyor. Kapalı bir
düğme oyuncuya neyin neden olmadığını söylemiyor. Aynı sebeple kalan hak sayı olarak
görünüyor: zorluk ekranında "2 free puzzles left today", ipucu düğmesinde "Hint (2)".
Sınır ancak çarpmadan önce görülürse adil.

### 6. Sınıra çarpınca görünen şey paywall değil

Brief b.8: "paywall, kullanıcı en az 3 bulmaca bitirmeden gösterilmez" ve "erken paywall
bu kategoride silinme sebebi". Bu PR'daki `PlayLimitSheet` bir bilgi ekranı: fiyat yok,
satın alma düğmesi yok, abonelik şartları yok. Ne olduğunu ve ne zaman geri geleceğini
söylüyor.

Paywall #61'in işi ve kendi ekranı olacak; b.8'in "3 bulmaca bitirilmeden gösterilmez"
kuralı orada uygulanacak.

## Sonuçlar

- Kota sayacı `UserDefaults`'ta olduğu için uygulamayı silip kurmak kotayı sıfırlıyor.
  ADR 0007'nin saat ileri alma boşluğuyla aynı sınıfta: kapatmak sunucu gerektirir.
- Oyuncu bir bulmacaya girip hemen çıkarsa hak gidiyor (ADR 0007 bunu zaten kabul
  etmişti). Yarım kalan oyun bunu yumuşatıyor: aynı bulmacaya dönmek bedava.
- `PlayLimits` ortamdan geliyor; bulmaca ekranını kuran her yerin onu vermesi gerekiyor.
  Öğretici ekranı bulmaca ekranını kullanmadığı için etkilenmiyor.
- Plus yolunun arayüzü yalnız testlerle doğrulandı; cihazda görülmesi #61'e kalıyor.
