# ADR 0028 — Zorluk satırları ne istediğini söylüyor

- Tarih: 2026-10-31
- Durum: kabul edildi
- Dayanak: #100, brief b.6 (zorluk tanımı), brief b.7 (ekranlar), ADR 0007 (ücretsiz katman),
  ADR 0018 (yarım kalan oyun), ADR 0027 (ana ekran satırları)

## Bağlam

ADR 0027 ana ekranda satırların ne verdiğini söylemesini sağladı. Bir sonraki ekranda aynı
boşluk duruyordu: zorluk ekranında dört satır var ve hiçbiri ne sunduğunu söylemiyor —
"Kolay", "Orta", "Zor", "Uzman". Oyuncu hangisini seçeceğini bilmiyor; kilitli olan ikisi
için neyin kaçırıldığı da okunamıyor, oysa kilitli satır bilerek gizlenmiyor.

Brief b.6 zorluğun ne demek olduğunu zaten tanımlamış: ızgara boyutu ya da ipucu sayısı
değil, **bulmacayı bitirmek için gereken en ileri teknik**. `TechniqueTier` bunu dört
seviyeyle kodda tutuyor ve üretim hattı her bulmacayı buna göre kabul ediyor. Ekranda
yazmayan tek şey buydu.

## Karar

### 1. Her satır o seviyenin ne isteyeceğini söylüyor

Ada bir cümle ekleniyor; dördü de `TechniqueTier`'ın tanımlarının oyuncu tarafındaki
karşılığı:

| Zorluk | Seviye | Satır |
| --- | --- | --- |
| Easy | `basic` | Every square is forced on its own |
| Medium | `intermediate` | Some squares only give way together |
| Hard | `advanced` | Chains and contradictions, several moves deep |
| Expert | `guessing` | Logic runs out; you test a branch |

Dört cümle birbirinden farklı, bu yüzden satır başına yazılıyorlar. ADR 0027'de varyant
cümlesi bölüm altbilgisine çıkmıştı; sebebi beş satırda aynı şeyi beş kez okutmaktı, burada
o sebep yok.

Expert'in cümlesi süslenmiyor: o seviyede mantığın bittiği bir nokta geliyor ve bir dal
deneniyor. "Uzman" diye açılıp beklediğini bulamayan oyuncu bunu yoruma yazıyor ve yorum
bizim tek sıralama varlığımız.

Eşleme `VariantPresentationTests` ile kapıya bağlandı: dört seviye dört zorluğu birebir
karşılamazsa test düşüyor. Ekranda duran cümlenin derecelendirmeyle ters düşmesi, kimsenin
fark etmeyeceği türden bir hata.

### 2. Izgara boyutu gösterilmiyor

Değerlendirildi ve çıkarıldı. Üç sebep:

- Kakuro'da Orta ve Zor **ikisi de 10×10**. Yan yana yazıldığında "fark yok" diyorlar, oysa
  fark tam olarak tekniğin kendisi.
- Boyut zaten bir dokunuş sonra görünüyor; cümle hiçbir yerde görünmüyordu.
- Boyutu doğru göstermek beş üreticinin yerleşimini uygulama katmanına açmak demekti;
  elle yazılan bir tablo ise ilk ayar değişikliğinde sessizce yalan söylerdi.

### 3. Devam eden oyun ayrı duruyor

"Devam ediyor" satırı tanıtım cümlesinin yerini almıyor, altına geliyor ve mürekkep
renginde — ana ekrandaki varyant satırıyla aynı ayrım (ADR 0027): tanıtım ikincil gri,
durum mürekkep. Kilitli satırdaki "Plus" etiketi ikincil gri kalıyor, çünkü o bir durum
değil, etiket.

### 4. Kalan hak cümlesi Türkçede büyük harfle başlıyor

"bugün 2 ücretsiz bulmaca kaldı" küçük, "Bugün ücretsiz bulmaca kalmadı." büyük harfle
başlıyordu. Aynı altbilginin üç hâli; üçü de büyük harfle başlıyor.

## Sonuçları

- Satır `DifficultyRow` olarak ekrandan ayrıldı: ortam bağımlılığı olmadan anlık görüntü
  referansı alınabiliyor. Referans dört hâli birden tutuyor.
- Satırlar iki, devam eden ve kilitli hâllerde üç satır metne çıktı; dokunma hedefi
  asgarisi zaten daha küçüktü.
- VoiceOver satırı bir bütün olarak okuyor, yani artık seviyenin ne isteyeceğini de
  söylüyor.
- Dört yeni dizgi Türkçeye çevrildi; dil bütünlüğü kapısı (ADR 0025) bunu zaten şart
  koşuyor.

## Değerlendirilen alternatifler

- **Izgara boyutu.** Yukarıda; en somut görünen veri ama Kakuro'da ayrım anlatmıyor.
- **Tipik çözüm süresi.** Dürüst görünüyor ama ölçümü oyuncuya göre değişiyor ve elimizde
  yalnız üretim süresi var, çözüm süresi değil. Yanlış beklenti kurardı.
- **Cümleyi bölüm altbilgisine almak.** ADR 0027'nin çözümü ama orada tek cümle beş satırı
  anlatıyordu; burada her satırın kendi cümlesi var.
- **Yalnız kilitli satırlara açıklama.** Kilidi satmak olurdu; oyuncunun asıl sorusu
  "hangisinden başlayayım".
