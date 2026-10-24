# ADR 0016 — Anlık görüntü referansları nerede üretiliyor

- Tarih: 2026-10-24
- Durum: kabul edildi
- Dayanak: ADR 0004 (sıfır bağımlılık ve anlık görüntü testi), ADR 0015 (macOS CI işi)

## Bağlam

ADR 0004 anlık görüntü harness'ını kendimiz yazmaya karar vermişti ve bir şart koymuştu:
"macOS CI işi **sabit bir simülatör runtime'ıyla** koşacak; runtime değişimi bilinçli bir
PR olacak." Şart doğru ama uygulanabilir olup olmadığı o gün bakılmamıştı. Bakınca
çıkan şey şu:

| Yer | Kurulu iOS simülatör çalışma zamanları |
|---|---|
| Geliştirme makinesi (Xcode 27.1) | 18.2, 26.2, 26.5 |
| CI runner (`macos-15`, Xcode 16.4) | 18.5, 18.6 |

**Ortak çalışma zamanı yok.** Piksel karşılaştırması sürüme duyarlı — metin yerleşimi ve
kenar yumuşatması sürümden sürüme oynuyor — dolayısıyla yerelde üretilen bir referans
CI'da tutmaz. ADR 0015 bu yüzden çalışma zamanı sabitini "referanslar geldiğinde"ye
ertelemişti; bu ADR o borcu kapatıyor.

## Karar

### 1. Referanslar CI'da üretiliyor, geliştirme makinesinde değil

Elle tetiklenen bir iş akışı (`.github/workflows/snapshots.yml`) testleri
`SNAPSHOT_RECORD=1` ile koşuyor, harness karşılaştırma yapmadan referansları yazıyor ve iş
onları artifact olarak yüklüyor. Artifact indirilip repoya commit'leniyor.

İki tur sürüyor ve bu kabul edildi, çünkü alternatifler daha kötü:

- **iOS 18.6 çalışma zamanını geliştirme makinesine indirmek** (~8 GB): makineye kalıcı
  bir yük ve Xcode 27 güncellendiğinde yine kayabilir.
- **Referansları yerelde üretip CI'da toleransı gevşetmek:** sürümler arası metin farkını
  yutacak bir tolerans, gerçek bir yerleşim regresyonunu da yutar. O zaman test hiçbir şey
  korumaz.
- **Anlık görüntü testini CI dışına almak:** brief b.11 her PR'da istiyor.

### 2. Sabit çalışma zamanı iOS 18.6, iki yerde birden kontrol ediliyor

`xcodebuild` hedefi bu sürüme sabitlenmiş durumda. Ayrıca macOS işi, çalışma zamanının
imajda **var olduğunu** ayrıca kontrol ediyor ve yoksa anlaşılır bir mesajla kırılıyor.
Bu kontrol gereksiz görünüyor ama değil: `-destination` sürümü bulamazsa xcodebuild'in
hatası okunaksız, ve asıl tehlike testlerin sessizce atlanması.

### 3. Çalışma zamanı eşleşmiyorsa testler atlanıyor, geçmiyor

Geliştirme makinesinde anlık görüntü testleri `.enabled(if:)` ile devre dışı. Yeşil değil
**atlandı** görünüyorlar; "yerelde geçti" yanılgısı olmuyor.

Bedeli açık: geliştirme makinesinde anlık görüntü testinden geri bildirim alınmıyor, kapı
yalnız CI'da. Bunu bir ölçüde telafi eden şey, harness'ın **kendi** testlerinin her
çalışma zamanında koşması — karşılaştırıcı, tolerans, karanlık mod ve Dynamic Type
yayılımı referansa ihtiyaç duymadan sınanıyor. Karşılaştırıcı bozulursa anlık görüntü
testleri sessizce yeşile döner ve bunu yakalayan tek şey o testlerdir.

### 4. Bulmacalar elle kurulu, üreticiden alınmıyor

Anlık görüntü sabitleri (`SnapshotFixtures`) beş varyantın bulmacasını elle kuruyor.
Sabit tohumla üreticiden alsaydık, üretici algoritmasındaki her değişiklik bütün arayüz
referanslarını geçersiz kılardı ve kırmızı bir test "çizim bozuldu" mu "üretici değişti"
mi söyleyemezdi.

### 5. Kapsam

| Referans | Ne koruyor |
|---|---|
| Beş varyantın ızgarası × açık/karanlık mod | Çizim ve tema |
| Varyant kartı × açık/karanlık mod | Liste yerleşimi |
| Varyant kartı × `accessibility1` | Dynamic Type |

Dynamic Type referansı ızgaranın değil kartın, çünkü ızgaradaki rakamlar Dynamic Type ile
değil hücreyle büyüyor (gerekçesi `GridStyle`'da). Izgaranın Dynamic Type referansı
standart olanla birebir aynı olurdu ve hiçbir şey korumazdı.

## Sonuçları

- **Runner imajı güncellenip iOS 18.6'yı düşürdüğünde CI kırılacak** ve düzeltmek
  referansları yeniden üretmek demek. Bu, ADR 0004'ün istediği "bilinçli bir PR" tam
  olarak bu; maliyeti iki CI turu.
- Referanslar repoda ikili dosya olarak duruyor (13 PNG, toplam birkaç yüz kilobayt).
  Diff'leri okunamıyor; değişimi anlamanın yolu fark görüntüsü, o da CI artifact'i.
- Tolerans iki sayıyla tanımlı: kanal başına 8/255 sapma ve farklı piksel oranı %0,2.
  İkisi de harness'ın kendi testleriyle korunuyor.

## Değerlendirilen alternatifler

- **Referansları çalışma zamanı başına ayrı tutmak** (`__Snapshots__/18.2/`, `18.6/`):
  yerelde de geri bildirim verirdi. Her referansın iki yerde güncellenmesi gerekir ve
  biri unutulduğunda fark edilmez; tek kaynak tercih edildi.
- **Algısal karşılaştırma** (piksel yerine yapısal benzerlik): sürüm farklarını yutardı
  ama kendi yazacağımız algısal karşılaştırıcı, piksel karşılaştırıcısından çok daha zor
  doğrulanır. ADR 0004 zaten pikseli seçmişti.
- **Self-hosted runner:** sabit çalışma zamanını garanti eder ve yerelle aynı olabilir.
  ADR 0003'te aynı gerekçeyle reddedilmişti: tek kişilik projede makine bakımı gereksiz
  yük.
