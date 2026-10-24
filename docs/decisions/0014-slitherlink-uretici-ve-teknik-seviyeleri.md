# ADR 0014 — Slitherlink üretici algoritması ve teknik seviyeleri

- Tarih: 2026-10-24
- Durum: kabul edildi
- Dayanak: ADR 0005 (boyutlar), ADR 0010 (`guessing` kararı), ADR 0012 ve 0013 (ölçüm disiplini)

## Bağlam

Faz 2'nin beşinci ve son varyantı. Slitherlink diğer dördünden yapısal olarak ayrılıyor:
çözüm ızgaranın hücrelerine değil **kenarlarına** yazılıyor ve geçerli olması için kenarlar
tek bir kapalı döngü oluşturmak zorunda. Yani kısıt yerel değil — her hücre kendi dört
kenarını sayıyor ama "tek döngü" koşulu bütün tahtaya bakıyor.

Bu, üretim sırasını ters çeviriyor. Diğer varyantlarda çözüm rastgele doldurulup bulmaca
ondan türetiliyordu. Burada rastgele bir kenar kümesi neredeyse hiçbir zaman döngü olmuyor,
dolayısıyla **önce döngü kuruluyor, ipuçları ondan okunuyor.**

## Karar

### Döngü kurulumu

Bir hücre kümesinin sınırı tam olarak şu iki koşul sağlandığında tek kapalı döngü oluyor:

1. Küme bağlı **ve** tümleyeni bağlı (deliksiz — içinde boşluk kalan bir küme iki döngü
   verir),
2. Hiçbir nokta derece 4 olmuyor (köşe köşeye değen iki blok, sınırı o noktada
   dallandırır).

`SlitherlinkLoopBuilder` rastgele bir 2×2 çekirdekten başlayıp hedef büyüklüğe kadar komşu
hücre ekliyor, her eklemede bu iki koşulu kontrol ediyor. Hedef, hücre sayısının %45'i.
Sınır kenarları da "iki komşusundan tam biri içte olan kenarlar" diye okunuyor. Döngü
kurulumu ölçülebilir bir maliyet taşımıyor (hepsi toplam üretim süresinin %1'inin altında).

### İpucu seyreltme ve zorluk

İpuçların tamamı verilmiş bir Slitherlink kurallara uygun ve benzersiz ama oynanacak bir şey
bırakmıyor: her hücre kendi kenarlarını söylüyor. Üretici ipuçları rastgele sırada siliyor ve
**yalnız yayılımın bulmacayı kapatmaya devam ettiği silmeleri** tutuyor. Hedef zorluğa
ulaşılan ilk noktada kabul ediliyor, bu yüzden silme eşiği aynı zamanda ipucu yoğunluğunu
belirliyor: eşik düşükse bulmaca doğru seviyede ama gereğinden kalabalık çıkıyor.

| Zorluk | Izgara | Asgari silme | Ölçülen ipucu yoğunluğu |
|---|---|---|---|
| Easy | 6×6 | %35 | 24/36 (%67) |
| Medium | 8×8 | %45 | 33/64 (%52) |
| Hard | 10×10 | %52 | 48/100 (%48) |
| Expert | 12×12 | %58 | 61/144 (%42) |

### Teknik seviyeleri — iki sapma

**`advanced` de reddediliyor, yalnız `guessing` değil.** Diğer dört varyantta ADR 0010'un
kararı uygulanıyor: `guessing` gerektiren bulmaca servis edilmiyor, `advanced` edilir.
Slitherlink'te `advanced` de reddediliyor ve bu ölçümün sonucu. "Orta teknik yetiyor" ile
"tahmin gerekiyor" arasındaki pencere bu varyantta çok dar: yayılımın kapatmadığı **ilk**
bulmacada ölçüm %60-80 çok çözümlü çıkıyor, kalanın da çoğu doğrudan `guessing` oluyor. O
pencereyi hedeflemeyi denedim — iki fazlı silme, sonra ikinci fazın deneme sayısını
sınırlama, sonra üreticinin çözücü bütçesini daraltma — Expert üretimi 13,9 saniye ortancaya
(en kötü 89,7 saniye) çıktı ve kazancı ileri teknik gerektiren nadir bir bulmacaydı. İkinci
fazı tamamen attım.

Karşılığında kesin bir güvence veriliyor: **gönderilen her Slitherlink temel ve orta
tekniklerle çözülebilir.** Rakip analizinde (PR #10) bu kategorinin en can alıcı şikâyeti tam
olarak buydu.

Bunun ikinci bir sonucu var ve bedava geliyor: üretim yalnız yayılımla kapanan adayları kabul
ettiği için **benzersizlik kontrolü aramaya hiç inmiyor.** Dört zorlukta da
`SlitherlinkSolver(searchNodeBudget: 0)` bulmacaları çözüyor; bu, 500 bulmacalık özellik
testinde ve performans testinde ayrı ayrı korunuyor.

**Medium, Hard ve Expert aynı teknik seviyesini (`intermediate`) paylaşıyor** ve boyutla
ayrılıyor. ADR 0012 ve 0013'te Hard/Expert için alınan kararın aynısı, bir seviye genişi.
Teknik seviyesi birincil kalıyor: `basic` ile kapanan bulmaca hangi boyutta olursa olsun
Easy, boyut tek başına zorluk üretmiyor.

## Çözücüde yapılan ve bu kararı mümkün kılan şey

İlk çözücü yalnız iki kural taşıyordu — nokta paritesi (her noktanın derecesi 0 ya da 2) ve
erken döngü kapanması (bir kenarı çizmek, dışarıda kesin hat varken döngüyü kapatacaksa o
kenar çarpı). Bu kurallarla **her bulmaca `advanced` çıkıyordu**, en küçük sabit bile.

ADR 0011'in dersi burada ikinci kez işe yaradı: teknik dağılımı tek seviyede toplanıyorsa
şüphelenilecek yer üretici değil **çözücü.** Eksik olan, Slitherlink'in asıl yerel çıkarımı
oldu: bir hücrenin dört kenarının 16 durumunu tek tek deneyip hem ipucuna uyan hem de dört
köşe noktasında uygulanabilir olanları tutmak. Bu, literatürdeki açılış desenlerinin
(köşedeki 3, komşu iki 3, köşedeki 1) hepsini **türetiyor** — hiçbiri elle yazılmadı.
`block3x3` sabiti bu kuraldan sonra `advanced`'den `basic`'e indi.

## Ölçüm

Release derleme, `.serialized`, M serisi Mac. Zorluk başına 100 üretim:

| Zorluk | Ortanca | p90 | p99 | En kötü | En çok deneme |
|---|---|---|---|---|---|
| Easy | 0,98 ms | 1,66 ms | 12,4 ms | 14,5 ms | 3 |
| Medium | 25,3 ms | 72,4 ms | 119 ms | 123 ms | 7 |
| Hard | 34,8 ms | 108 ms | 198 ms | 207 ms | 5 |
| Expert | 88,0 ms | 183 ms | 291 ms | 345 ms | 3 |

Briefin 2.000 ms bütçesine karşı en kötü durumda **5,8 kat pay.** 500 bulmacalık özellik
testinde dört zorluğun hepsi hedef seviyeyi tutuyor ve en kötü deneme sayısı 9 (hat sınırı
2.500).

Beş varyantın payı: Hashi 65×, Hitori 20×, Calcudoku 11×, **Slitherlink 5,8×**, Kakuro 2×.

## Sonuçları

- Slitherlink'te `advanced` bulmaca hiç üretilmiyor. İleride zorluk merdiveni genişletilmek
  istenirse (örneğin bir "Master" seviyesi) bu kararın ölçümü yeniden yapılmalı; bugünkü
  ölçüm o pencerenin pahalı olduğunu söylüyor, imkânsız olduğunu söylemiyor.
- Expert'in payı Calcudoku'nun yarısı. Cihazda ölçüm Faz 3'ün kapısı; orada darlaşırsa
  briefin yazdığı çare (arka planda önceden üretim) Kakuro ile birlikte devreye girer.
- Zorluk ayrımının bir kısmı boyuta ve ipucu seyrekliğine dayanıyor, tekniğe değil. Bu,
  oyuncunun hissettiği zorlukla birebir örtüşmeyebilir ve Faz 4'teki oynanış denemesinde
  doğrulanacak.
