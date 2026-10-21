# ADR 0005 — Izgara boyutları ve zorluk derecelendirme çerçevesi

- Tarih: 2026-10-17
- Durum: kabul edildi, seviye eşlemesi [ADR 0010](0010-hashi-uretici-ve-teknik-seviyeleri.md) ile güncellendi

## Bağlam

Brief yalnızca Calcudoku için boyut veriyor (4×4 – 9×9). Diğer dört varyantın boyut/zorluk
eşlemesi yok ve bu karar geliştiriciye bırakıldı.

Asıl kural b.6'da: zorluk, ızgara boyutuna değil çözücünün kullandığı teknik seviyesine
göre belirlenir. O zaman boyutun ne işi var? Şu: 15×15 bir Kakuro pratikte Easy olamaz —
teknik basit olsa bile tutulacak defter çok. Tersi de doğru: 5×5 Hitori'de ileri tekniğin
oluşacağı yer yok. Boyut, derecelendirme değil **çerçeve**.

İkinci kısıt okunabilirlik. Kitle 35 yaş üstü, yüksek kontrast ve geniş dokunma hedefi
bekliyor (b.7). iPhone dikey ekranda, makul punto ve ~44 pt dokunma hedefiyle, yakınlaştırma
olmadan rahat okunan üst sınır yaklaşık 13-14 sütun.

## Karar

**Boyut, zorluğun çerçevesi; derecelendirme `SolveTrace`'ten gelir.** Üretici hedef zorluğa
uygun boyut aralığında aday kurar, hat adayın gerçek zorluğunu çözücünün izinden okur ve
hedefle eşleşmeyen adayı eler (`GenerationPipeline`).

| Varyant | Easy | Medium | Hard | Expert |
|---|---|---|---|---|
| Hashi | 7×7 | 9×9 | 11×11 | 13×13 |
| Hitori | 5×5 | 7×7 | 9×9 | 11×11 |
| Calcudoku | 4×4 | 5×5 – 6×6 | 7×7 | 8×8 – 9×9 |
| Kakuro | 8×8 | 10×10 | 10×10 | 11×11 |
| Slitherlink | 6×6 | 8×8 | 10×10 | 12×12 |

> **Kakuro satırı ADR 0013 ile güncellendi.** İlk tablo 8/10/12/14 yazıyordu ve bu ölçüm
> öncesi tahmindi. 14×14'te (96 giriş hücresi) hiç benzersiz bulmaca üretilemedi, 12×12'de
> üretim süresi bütçeyi zorladı. Ölçülen boyutlar 8/10/10/11; Hard ile Expert aynı teknik
> seviyesini paylaşıp boyutla ayrılıyor.

Kakuro boyutu ipucu hücreleri dahil; oynanabilir alan daha küçük. Slitherlink boyutu hücre
sayısı (nokta ızgarası bir fazla).

**Teknik seviyeleri** `TechniqueTier` ile ortak: `basic` → Easy, `intermediate` → Medium,
`advanced` → Hard, `guessing` → Expert.

> **ADR 0010 ile güncellendi (Faz 1 ölçümü).** Son iki eşleme değişti: `guessing` artık
> hiçbir zorluğa eşlenmiyor, eleme sebebi — tek çözümü olan bir bulmaca da mantıkla
> çözülemeyebilir ve rakip analizinde en can alıcı şikâyet buydu. Expert ise `advanced`
> içinden ayrılıyor: ileri tekniğin kaç kez gerektiğine göre. Varyantlar bu ayrımı
> `PuzzleGenerator.rate` ile kendi ölçeklerine göre yapıyor. Hangi tekniğin hangi seviyeye girdiği varyanta özel
ve **her varyantın kendi ADR'sinde listelenecek** — Hashi'nin "izole ada" çıkarımı ile
Kakuro'nun "kesit toplamı kombinasyonu" aynı kutuya girmiyor.

Calcudoku'da zorluk ayrıca kafes yapısıyla ayarlanır (b.14): Easy'de yalnız `+` ve `×`,
küçük kafesler; Expert'te dört işlem ve 4+ hücreli kafesler.

## Sonuçları

- Expert'te 13×13 ve 14×14 ızgaralar iPhone'da yakınlaştırma gerektirebilir. Bulmaca ekranı
  kaydırma ve yakınlaştırma destekleyecek (b.11'in 60 fps bütçesi bunu kapsıyor), ama
  Expert oynayan kullanıcı bunu kabul etmiş sayılıyor.
- Boyut tablosu üst sınır değil hedef: hat bir boyutta hedef zorlukta benzersiz bulmaca
  bulamazsa, çözüm boyutu büyütmek değil üreticiyi düzeltmek. Boyut büyüterek zorluk
  ayarlamak tam olarak b.6'nın yasakladığı şey.
- Tablo Faz 1 ve 2'de her varyantın gerçek elenme oranı ölçüldükten sonra değişebilir;
  değişirse bu ADR güncellenir.

## Değerlendirilen alternatifler

- **Tek boyut, zorluk yalnız teknikten:** en saf okuma. Reddedildi çünkü 5×5 Hitori'de
  Expert üretmek imkânsız, 13×13'te Easy üretmek anlamsız — hat boşuna aday eliyor.
- **Zorluğu boyuta bağlamak:** b.6 bunu açıkça yasaklıyor ve gerekçesi doğru: "Expert" diye
  açılan bulmaca kolay çıkarsa kullanıcı yoruma yazıyor.
- **Kullanıcının boyutu kendi seçmesi:** zorluk seçimi ekranını ikiye katlıyor ve bu kitle
  sadeliği tercih ediyor. V2 konusu.
