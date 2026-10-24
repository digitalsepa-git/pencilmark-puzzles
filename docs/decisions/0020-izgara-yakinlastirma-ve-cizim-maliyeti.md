# ADR 0020 — Izgara yakınlaştırma, kaydırma ve çizim maliyeti

- Tarih: 2026-10-24
- Durum: kabul edildi
- Dayanak: brief b.11 ("Grid çizimi: 60 fps, kaydırma ve yakınlaştırmada kare
  düşürmeden"), brief b.9 (tek `Canvas`), brief b.7 (Hashi'de köprü sürüklemesi),
  ADR 0018 (yarım kalan oyunun saklanması)

## Bağlam

Izgara bugüne kadar ekrana sığdırılıyordu, yakınlaştırma yoktu. Sıkıştığı yerler
ölçüldü: Expert Kakuro 11×11'de hücre iPhone 16'da ~32 pt, Slitherlink 12×12'de kenar
dokunma payı ~9 pt. Apple'ın en küçük dokunma hedefi 44 pt; bu ızgaralar o eşiğin
altında.

Üç şeye birden karar vermek gerekiyordu: yakınlaştırma nasıl uygulanacak, hangi hareket
neyi yapacak ve 60 fps iddiası neyle ölçülecek.

## Karar

### 1. Yakınlaştırma bir dönüşüm değil, geometriye girdi

`GridZoom` (ölçek + kaydırma) `GridGeometry`'nin kurucusuna giriyor; hücre kenarı
ölçekle büyüyor ve ızgara büyük hâliyle yeniden çiziliyor.

Alternatif `scaleEffect`'ti ve daha az kod olurdu: `Canvas`'ın çıktısını olduğu gibi
büyütür, dokunma eşlemesi de bedavaya doğru çalışırdı (yerel koordinat uzayı dönüşümden
önce). Reddedildi çünkü `scaleEffect` hazır bitmap'i büyütüyor: 3 katta çizgiler de
rakamlar da bulanıyor. Yakınlaştırmanın bütün amacı küçük rakamı okumak; bulanık bir
büyütme o amacı karşılamıyor.

Bedeli, dokunma eşlemesinin artık bedava olmaması. Buna karşılık `GridGeometry` saf ve
`SwiftUI` bilmiyor, yani eşleme piksel karşılaştırmasıyla değil sayıyla sınanıyor
(`ZoomedGridGeometryTests`) — projenin bu dosyadaki mevcut duruşu zaten buydu.

Sınırlar: 1–3 kat. 3 kat, Expert Kakuro'nun hücresini 96 pt'ye, Slitherlink'in kenar
payını ~27 pt'ye çıkarıyor; daha fazlası ızgaranın bütününü gözden kaçırıyor.

### 2. Kaydırma kırpması çizim sırasında da uygulanıyor

Yalnız hareketin sonunda kırpmak yetmiyor: cihaz döndüğünde görüş alanı değişiyor ve
eldeki kaydırma ızgarayı ekranın dışında bırakabilir. Kırpma `GridGeometry`'nin
kurucusunda, yani her karede.

### 3. Tek parmak oynar, iki parmak yakınlaştırır — Hashi hariç

Sıkıştırma (iki parmak) her varyantta yakınlaştırıyor. Tek parmak sürüklemesi
**yalnız yakınlaştırılmışken** kaydırmaya dönüşüyor; 1 katta hareket hiç kurulmuyor, yani
varsayılan durumda dokunma davranışı bugünküyle birebir aynı ve gezinme çubuğunun geri
kaydırması bozulmuyor.

Hashi'de tek parmak sürüklemesi zaten köprü kuruyor (brief b.7). Çakışma, sürüklemenin
**başladığı hücreye** bakılarak çözülüyor: ada hücresinden başlayan sürükleme köprü,
boşluktan başlayan kaydırma. Ayrım adanın dairesi değil hücresi — köprü sürüklemesi
zaten hücre toleransıyla çalışıyordu ve iki farklı tolerans oyuncuya açıklanamaz.
Expert Hashi'de hücrelerin ~%18'inde ada var, yani sürüklemelerin çoğu kaydırma.

Reddedilen alternatif iki parmak kaydırmaydı (Procreate'in yaptığı gibi): SwiftUI'de iki
parmak sürüklemesi yok, `UIGestureRecognizerRepresentable` ise iOS 18 ve uygulamanın
dağıtım hedefi iOS 17. Hedefi bir yakınlaştırma özelliği için yükseltmek cihaz
kaybettirir.

### 4. Yakınlaştırma seviyesi saklanmıyor

`GridZoom` ekranın `@State`'i; yarım kalan oyunla birlikte **yazılmıyor** (ADR 0018'in
kaydettiği şey hamleler). Ekrandan çıkıp dönünce 1 kat.

Bilinçli: kayıt cihazlar ve yönler arasında taşınıyor, saklanmış bir kaydırma oyunu
ekranın dışında bir yerden açardı. Oyuncunun kaldığı yer hamlelerinde, görüş açısında
değil.

### 5. Metinler geçiş başına bir kez çözümleniyor

60 fps ölçülürken çıktı: `GraphicsContext.draw(Text, at:)` her çağrıda metni baştan
çözümlüyor ve ızgarada maliyetin tamamına yakını buydu. 11×11 Kakuro'nun bütün hücreleri
kalem işaretliyken kare başına 900 metin düşüyor ve çizim **43 ms** sürüyordu — kare
bütçesinin iki buçuk katı.

`GridDigitText` aynı yazı tipi ve renkteki rakamları geçiş başına bir kez çözümlüyor.
Aynı ızgara **7 ms**. Çizilen piksel aynı: `draw(Text)` içeride zaten aynı çözümlemeyi
yapıyor, bu da anlık görüntü referanslarının değişmemesiyle doğrulanıyor.

## Ölçüm

`GridRenderPerformanceTests`, iPhone 16 simülatörü, 360×360 pt ızgara, 20 çizim
(ortanca):

| Izgara | 1 kat | 3 kat |
| --- | --- | --- |
| Slitherlink 12×12, bütün kenarlar dolu | 1.2 ms | 1.2 ms |
| Kakuro 11×11, bütün hücreler kalem işaretli | 7.0 ms | 6.6 ms |
| Calcudoku 9×9, bütün hücreler kalem işaretli | 8.9 ms | 8.6 ms |
| Hashi 12×12, bütün köprüler çift | 1.0 ms | 1.1 ms |
| Hitori 12×12 | 4.1 ms | 4.1 ms |

Kare bütçesi 16.67 ms. Yakınlaştırma maliyeti artırmıyor: ölçek geometriye girdi, yani
çizilen öğe sayısı aynı kalıyor.

Ölçülen şey bir kare değil, bir karenin içindeki çizim işi: `ImageRenderer` yerleştirmeyi
ve `Canvas`'ın çizim kapanışını koşturup sonucu bitmap'e yazıyor. Gerçek karede son adım
yok, yani bu sayılar gerçek kare süresinin **üst sınırı**. Simülatör de cihaz değil;
asıl ölçüm #66'da, cihazda.

CI eşiği bütçenin beş katı (83 ms) ve amacı bütçeyi doğrulamak değil katastrofik
regresyonu yakalamak — ADR 0003'ün üretim ölçümü için koyduğu gerekçenin aynısı.

## Sonuçlar

- Izgara görünümleri artık `GridZoom` bağı alıyor ve durumu ekranda duruyor; görünümler
  girdilerinin saf fonksiyonu kaldı, testler istediği ölçeği kurabiliyor.
- 1 katta çizim bit düzeyinde değişmedi; bunun bekçisi mevcut anlık görüntü referansları.
- Görüş alanı dışında kalan öğeler hâlâ çiziliyor (kırpmayı CoreGraphics yapıyor).
  Ölçülen sayılar bütçenin altında olduğu için eleme (culling) eklenmedi; gerekirse
  `GridGeometry` üzerinden eklenebilir.
- Yakınlaştırmayı sıfırlayan bir düğme yok: ızgaranın üstüne konan bir denetim hücreleri
  örter ve dokunuş çalar, sıkıştırarak geri dönmek her zaman mümkün. VoiceOver açıkken
  sıkıştırma zaten VoiceOver'a gidiyor, yani ekran okuyucu kullanan oyuncu
  yakınlaştırılmış bir ızgarada sıkışamıyor.
