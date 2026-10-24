# ADR 0018 — Yarım kalan oyun nasıl saklanıyor

- Tarih: 2026-10-24
- Durum: kabul edildi
- Dayanak: ADR 0015 (modül sınırları), ADR 0017 (saklama katmanı)

## Bağlam

Brief b.7 iki şey istiyor ve ikisi birlikte okunmalı: "Otomatik kayıt her hamlede;
uygulama kapanıp açıldığında bulmaca tam olduğu yerden devam eder" ve "Geri alma sınırsız
ve bulmaca oturumu boyunca kalıcı."

ADR 0017 bu soruyu açıkta bırakmıştı: "oturumun kendisini saklamak ayrı bir şema ve ayrı
bir karar — hamle yığınının mı yoksa tahtanın mı saklanacağı dahil."

## Karar

### 1. Tahta değil hamle dizisi saklanıyor

İki sebep var.

**Geri alma.** "Oturum boyunca kalıcı" geri alma, uygulamayı kapatıp açmakla bitmeyen bir
oturum demek; oyuncu açısından aynı bulmacaya devam ediyor. Tahta saklansaydı geri alma
yığını kaybolurdu ve oyuncu, kapatmadan önce yaptığı hamleyi geri alamazdı.

**Tekilllik.** Hamle dizisi tahtayı zaten belirliyor. İkisini birden saklamak aynı bilgiyi
iki yerde tutmak olurdu ve ikisinin birbirinden ayrılması an meselesi.

Bunun bedeli `PuzzleMove`'a `Codable` gereksinimi eklemek oldu — "bir hamle saklanabilir
olmak zorunda", varyantların isteğe bağlı eklediği bir şey değil.

### 2. Bulmacanın kendisi saklanmıyor, tohumdan yeniden üretiliyor

Tanım saklansaydı beş varyantın tanım tipinin de `Codable` olması gerekirdi ve kazancı
olmazdı: üretim belirlenimci, aynı tohum aynı bulmacayı veriyor.

Bunun bir riski var ve açıkça ele alınıyor: **algoritma sürümü değişirse aynı tohum başka
bir bulmaca verir** ve saklanan hamleler ona uymaz. Saklanan satır üretildiği sürümü de
taşıyor; sürüm tutmuyorsa satır atılıyor ve oyun baştan başlıyor. Oyuncuya yanlış tahta
göstermektense baştan başlatmak daha az kötü.

### 3. Anahtar (varyant, zorluk, tür)

Easy'ye başlamak yarım kalan Medium'u silmiyor. Alternatifi varyant başına tek kayıttı ve
o, oyuncunun ilerlemesini haberi olmadan silerdi. Onay sorarak da çözülebilirdi; sormamak
daha iyi.

Üst sınır 5 varyant × 4 zorluk + günlük = 21 satır. Saklama maliyeti sorun değil.

### 4. Kayıt her hamlede ve arka plana alınırken

Brief'in istediği gibi her hamlede. Ayrıca uygulama arka plana alınırken de kaydediliyor:
son hamleden sonra geçen süre yoksa kayboluyordu.

Her kayıt bütün geçmişi yeniden kodluyor. Ölçüm: 500 hamlelik bir geçmiş 62 KB ve 2,9 ms
(release, M serisi Mac). 500 hamle gerçekçi bir üst sınırın üstünde — bir Expert
Kakuro'da 59 giriş hücresi var. Artan maliyet görünür kalsın diye bir testle ölçülüyor.

### 5. Biten oyunun satırı siliniyor

Bulmaca çözülünce `PuzzleRecord` yazılıyor ve yarım kalan satır siliniyor; yoksa ana ekran
bitmiş bulmacayı "devam et" diye gösterirdi.

Devam ettirilen bir oyun zaten çözülmüş olabilir — oyuncu son hamlesini yapıp kayıt
yazılamadan uygulamayı kapatmış olabilir. Bu durum açılışta kontrol ediliyor ve kayıt o an
yazılıyor.

## Sonuçları

- Geri alma **ve ileri alma** uygulama yeniden başlatıldıktan sonra da çalışıyor.
- Algoritma sürümü değişince bütün yarım kalan oyunlar sessizce kayboluyor. Günlük
  bulmacanın aksine burada ileri tarihli geçiş yapılamıyor: yarım kalan oyun zaten
  kişisel ve kısa ömürlü.
- Saklanan şey hamle dizisi olduğu için bulmaca her açılışta yeniden üretiliyor. Expert
  Kakuro'da bu 1,2 saniyeye kadar çıkabilir (ADR 0013) ve devam etmek, yeni bulmaca
  başlatmak kadar sürüyor.
- `PuzzleMove: Codable` gereksinimi yeni bir varyant eklerken de geçerli; hamle tipinin
  saklanabilir kalması derleyici tarafından zorunlu.

## Değerlendirilen alternatifler

- **Tahtayı saklamak:** daha basit, daha küçük ve yeniden üretim gerektirmezdi. Geri alma
  yığınını kaybettiriyor ve brief b.7'nin "oturum boyunca kalıcı" maddesini zayıflatıyor.
- **Tahtayı ve hamleleri birlikte saklamak:** devam etmeyi hızlandırırdı (yeniden üretim
  yok). Aynı bilgiyi iki yerde tutmak ve ayrışma riski.
- **Bulmaca tanımını saklamak:** sürüm değişiminden etkilenmezdi. Beş tanım tipine
  `Codable` eklemek gerekir; kazancı, nadir bir sürüm geçişinde kaybolan yarım oyunlar.
- **Varyant başına tek kayıt:** daha az satır. Oyuncunun ilerlemesini habersiz siler.
