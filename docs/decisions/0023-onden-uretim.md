# ADR 0023 — Önden üretim

- Tarih: 2026-10-29
- Durum: kabul edildi
- Dayanak: #66 ve #78 ölçümleri (`docs/olcumler/`), brief b.5 (üretim süresi ölçütü),
  ADR 0003 (ölçüm disiplini), ADR 0018 (ne saklanıyor)

## Bağlam

Cihaz ölçümü üretim süresinin brief'in 2 saniyelik ölçütünü dört zorluk hücresinde
aştığını gösterdi. Darboğaz arandı ve bulundu: ipucu inceltme döngüsü her silme
denemesinden sonra bir yayılım çözümü koşturuyor ve ızgara seyreldikçe o çözüm 8,8
ms'den 88 ms'ye çıkıyor.

Maliyeti düşürmenin ilk fikri — toplu silme — denendi ve **ters teptiğı ölçüldü**: çağrı
sayısı 144'ten 128'e indi ama süre 5,9 saniyeden 6,7 saniyeye çıktı, çünkü toplu silme
çözücüyü daha seyrek ızgaralarla karşılaştırıyor. Kaldıraç çağrı sayısı değil, çözüm
anındaki seyreklik.

Geriye iki yol kaldı: çözücüyü seyrek ızgarada hızlandırmak (kapsamı belirsiz, çözücünün
içine girmeyi gerektiriyor) ya da maliyeti oyuncudan gizlemek.

## Karar

**Bir sonraki bulmaca, oyuncu bir öncekini oynarken üretiliyor.**

`PuzzlePrefetcher` anahtar başına (varyant + zorluk) bir bulmaca tutuyor. Bulmaca ekranı
açıldığında iki şey yapıyor: önbellekte hazır bulmaca varsa onu kullanıyor, sonra aynı
anahtar için sıradakini üretmeye başlıyor.

### Bellekte, diskte değil

Üretilen şey tanım + çözüm. Diske yazmak beş varyantın tanım tipini `Codable` yapmayı
gerektirir — ADR 0018'in bilerek kaçındığı iş ve orada "kazancı yoktu" diye yazılmıştı.
Önbellek uygulama kapanınca gidiyor; kabul edildi, çünkü kazancın büyük kısmı tek bir
oturum içinde arka arkaya oynayan oyuncuda.

### Anahtar başına bir bulmaca

İkincisini tutmak belleği ve pili karşılığını almadan harcıyor: oyuncu bir sonraki
bulmacayı oynarken üçüncüsü zaten üretiliyor.

### `.background` önceliğinde

Oyuncu o sırada bir bulmaca oynuyor; arayüzün akıcılığı önden üretimden önemli. Üretim
zaten ana iş parçacığının dışında (ADR 0013).

### Günlük bulmaca ana ekranda üretiliyor

Günün bulmacası ana ekranın ilk satırı ve tohumu tarihten belli (ADR 0006), yani hangi
üreticinin çalışacağı bugünden biliniyor. Çözülmüşse üretilmiyor.

### Alınan bulmaca yuvadan siliniyor

Aynı bulmacayı iki kez vermek, oyuncuya arka arkaya aynı ızgarayı göstermek demek —
rakip şikâyetlerinden biri (ADR 0013).

## Ne çözmüyor

**İlk bulmacayı hızlandırmıyor.** Soğuk açılışta önbellek boş; oyuncu ilk bulmacasını
tam fiyatına bekliyor. Brief'in "en zor seviyede bile 2 saniyenin altında" ölçütü bu
kararla **karşılanmıyor**; karşılanması için üreticinin kendisinin hızlanması gerekiyor.

Bu ADR o işi yapmıyor, yerini işaretliyor: yayılım çözücüsünün seyrek ızgaradaki
maliyeti.

## Sonuçlar

- Oyuncu arka arkaya oynarken bekleme kalkıyor; ilk bulmacada ve uygulamayı her yeniden
  açtığında duruyor.
- Pil: oyun sırasında arka planda bir üretim koşuyor. Expert'te bu saniyeler süren bir
  iş; `.background` önceliği ısınmayı sınırlıyor ama sıfırlamıyor.
- Yarım kalan oyuna dönerken önbellek kullanılmıyor: oyuncunun hamleleri o bulmacaya ait.
- Önbellek Plus kotasına dokunmuyor: hak hâlâ başlatmada düşüyor (ADR 0021).
