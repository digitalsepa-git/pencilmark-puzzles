# ADR 0017 — Saklama katmanı, şema ve sürümleme

- Tarih: 2026-10-24
- Durum: kabul edildi
- Dayanak: ADR 0008 (istatistik katmanları), ADR 0015 (modül sınırları)

## Bağlam

İstatistik ekranı veri istiyor ve brief b.9 saklamayı SwiftData olarak belirlemiş. SwiftData
Apple'a özgü, yani nereye konduğu ADR 0015'in modül sınırı kararını doğrudan ilgilendiriyor.
Bunun yanında iki soru cevapsızdı: şema nasıl sürümlenecek ve bozuk bir satır ne yapacak.

## Karar

### 1. Saklama App hedefinde, hesap GameCore'da

`StoredRecord` ve `RecordStore` App hedefinde; `PuzzleRecord`, `CalendarDay` ve
`StatsSummary` GameCore'da. SwiftData'yı pakete sokmak Linux derlemesini kırardı (ADR 0015
bu durumu öngörmüştü) ve kazancı olmazdı: SwiftData testleri zaten simülatör istiyor.

Ayrım pratik bir fayda veriyor ve asıl gerekçe bu: seri ve özet hesabı — yani yanlış olması
en muhtemel kısım — simülatör açmadan, Linux'ta 1x maliyetle sınanıyor. Saklama tarafında
sınanan şey yalnız yazma ve okuma.

### 2. Enum'lar `rawValue` olarak saklanıyor

Varyant, zorluk ve kayıt türü satırda metin olarak duruyor. `PuzzleVariantID`'nin
`rawValue`'ları zaten "kayıt şemasında kullanılıyor, sabit kalmak zorunda" diye işaretliydi;
bu karar o notu saklama tarafında da bağlayıcı kılıyor.

### 3. Tanınmayan satır atlanıyor, çökertmiyor

Okunan bir satırın varyantı, zorluğu ya da tarihi tanınmıyorsa o satır atlanıyor. Eski bir
sürümün yazdığı, bu sürümde artık olmayan bir değer olabilir. Tek bir bozuk satır yüzünden
bütün istatistiğin çökmesi kabul edilemez.

Sessizce atlamak da ideal değil — doğrusu bir günlük kaydı ve o Faz 4'ün işi. Bugünkü
tercih bilinçli: veri kaybı görünmez ama uygulama ayakta.

### 4. Şema sürümleme ilk yayından **sonra** ekleniyor

`VersionedSchema` ve `SchemaMigrationPlan` kurulumu şimdi yapılmıyor. V1'de tek bir model
var ve hiç yayınlanmadı, yani taşınacak veri yok. Kullanılmayan bir göç altyapısını bakmak,
onu yazmanın maliyetinden büyük.

**Bağlayıcı olan şu:** mağazaya ilk yükleme yapıldıktan sonra bu şemaya dokunan ilk
değişiklik, aynı PR'da sürümleme kurulumunu da getirmek zorunda. Bu ADR o anı işaretlemek
için var.

### 5. Kap kurulamazsa uygulama bellekte çalışıyor

Disk dolu ya da şema bozuksa `ModelContainer` kurulamıyor. O durumda uygulama bellek içi
bir kapla açılıyor: istatistik kaybolur ama bulmaca oynanır. Bulmaca çözmek isteyen birine
açılmayan bir uygulama göstermek daha kötü.

### 6. Yarım kalan oyun bu kararın dışında

Brief b.7 otomatik kaydı her hamlede istiyor; bu ADR yalnız **bitmiş** bulmacaların
kaydını kapsıyor. Oturumun kendisini saklamak ayrı bir şema ve ayrı bir karar — hamle
yığınının mı yoksa tahtanın mı saklanacağı dahil.

## Sonuçları

- İstatistik hesabı saklama biçiminden bağımsız: SwiftData'dan vazgeçilse `StatsSummary`
  değişmez.
- `RecordStore` araya girdiği için ekranlar `ModelContext` görmüyor; ihtiyaçları olan şey
  `PuzzleRecord` ve `StatsSummary`.
- Bozuk satırlar sayılmadığı için toplam sayılar sessizce eksik kalabilir. Ölçülebilir
  değil; günlük kaydı gelene kadar bu bir körlük.
- Üç yılda ~4.400 satır (ADR 0008'in tahmini) ve özet her çağrıda hepsini tarıyor. Bu
  hacimde önemsiz; ekranda ölçülecek.

## Değerlendirilen alternatifler

- **Saklamayı da pakete koymak:** modül şeması daha tutarlı olurdu. Linux derlemesi kırılır
  ve hedef süzmesi gerekirdi; kazancı yok.
- **Şema sürümlemeyi baştan kurmak:** ilk göçte hazır olurdu. Yayınlanmamış bir şema için
  taşınacak veri yok; kullanılmayan altyapı çürür.
- **Bozuk satırda çökmek:** hatayı görünür kılardı. Kullanıcıya düşen maliyet (istatistik
  ekranı hiç açılmıyor) hatayı görmenin değerinden büyük.
