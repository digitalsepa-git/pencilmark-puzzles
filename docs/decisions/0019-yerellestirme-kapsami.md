# ADR 0019 — Yerelleştirme kapsamı

- Tarih: 2026-10-24
- Durum: kabul edildi, §3'ün borcu ADR 0025 ile kapandı
- Dayanak: brief b.5 ("yerelleştirme altyapısı hazır olsun ama çeviri V1'de yok"),
  brief b.4 (bulmaca adları), ADR 0015 (modül sınırları)

## Bağlam

V1 tek dil: İngilizce. Brief altyapının hazır olmasını istiyor — ikinci bir dil
eklemek uygulamayı yeniden yazmayı gerektirmemeli.

"Hazır" ne demek, keskinleştirilmesi gerekiyordu: bütün metinler mi, hangi katmanlar,
ve çevrilmemesi gereken bir şey var mı.

## Karar

### 1. Uygulama hedefi String Catalog kullanıyor

`App/Sources/Localizable.xcstrings`. SwiftUI'nin metin değişmezleri zaten
yerelleştirilebilir; kodda kurulan metinler `String(localized:)`'a çevrildi, yoksa
çıkarmaya hiç görünmüyorlardı.

Katalog elle değil `xcodebuild -exportLocalizations` çıktısından dolduruldu: 87 dizgi.
Elle yazmak hem yanlış hem de koda göre kayardı.

### 2. Bulmaca adları **çevrilmiyor**

`PuzzleVariantID.displayName` PuzzleKit'te kalıyor ve `String(localized:)` olmuyor.
"Kakuro", "Hitori", "Slitherlink" özel adlar; brief b.4 bulmaca adlarının jenerik
biçimlerinde kalmasını şart koşuyor ve markalı karşılıklarının kullanılmasını ret sebebi
sayıyor. Çeviriye açmak, bir çevirmenin "Hitori"yi yerel bir karşılıkla değiştirmesine
kapı açardı.

### 3. Öğretici metinleri **şimdilik çevrilemiyor** ve bu bilinçli bir borç

`TutorialScenarios` GameCore'da ve içinde İngilizce cümleler var. Oraya
`String(localized:)` sokmak, pakete Foundation'ın yerelleştirme kaynaklarını ve bir
`Bundle.module` eklemek demek; GameCore'un Linux'ta 1x maliyetle test edilmesi (ADR 0015)
bu yüzden riske girerdi.

**İkinci dil eklendiğinde yapılacak iş:** öğretici metinleri uygulama katmanına taşınacak.
**Bu borç ADR 0025 ile kapandı.**
Senaryonun yapısı (adım sırası, tamamlanma koşulu) GameCore'da kalabilir; taşınacak olan
yalnız proza. Bu ADR o işi görünür kılmak için var.

Bugün bedeli yok: V1 tek dilli.

### 4. Tarih biçimi elle yazılmıyor

Paylaşım kartındaki tarih Foundation'ın biçimlendiricisinden geçiyor. Ay adlarını elle
yazmak on iki çeviri girdisi **ve** yanlış sıralama demekti: tarih biçimi dilden dile
değişiyor ("October 24, 2026" / "24 Ekim 2026").

Burada `Date`'e dönmek ADR 0006'ya aykırı değil: hangi günde olduğumuz zaten karar
verilmiş, bu yalnız gösterim. `Date`'ten kaçınmamızın sebebi günü **belirlerken** saat
dilimi belirsizliğiydi.

## Sonuçları

- Çeviri eklemek, katalogda her dizginin yanına bir değer yazmak: kod değişmiyor.
- (ADR 0025'ten sonra: öğretici de dahil) Her kullanıcı metni çıkarmaya görünüyor; bir dizginin
  `String(localized:)` olmayı unutması sessiz bir boşluk bırakır ve bunu yakalayan
  otomatik bir kapı **yok**. Çıkarma sayısını kontrol eden test kaba bir koruma.
  Eksik **çeviriyi** yakalayan kapı ADR 0025 ile geldi.
- Katalog kaynakta duruyor ve Xcode'da derleme yapıldıkça kendiliğinden güncelleniyor;
  elle düzenlenmemeli.
- İngilizce tablo pakete giriyor (87 dizgi), yani uygulama dilini açıkça beyan ediyor.

## Değerlendirilen alternatifler

- **Hiçbir şeyi `String(localized:)` yapmamak, yalnız katalog dosyasını eklemek:**
  en ucuzu. SwiftUI değişmezleri çıkarılırdı ama kodda kurulan onlarca metin
  görünmezdi ve "altyapı hazır" iddiası yanlış olurdu.
- **GameCore'u da yerelleştirmek:** tam kapsam. Linux testlerinin maliyetini ve
  `Bundle.module` kurulumunu bugün ödemek, V1'de hiçbir karşılığı olmadan.
- **Öğretici metinlerini hemen uygulama katmanına taşımak:** borcu şimdi kapatırdı.
  Senaryo yapısını ikiye bölüyor ve ADR 0009'un çözücüyle doğrulanan testlerini
  Linux'tan simülatöre taşıyordu; ikinci dil gündeme gelene kadar karşılıksız.
