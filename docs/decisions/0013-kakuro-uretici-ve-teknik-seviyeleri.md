# ADR 0013 — Kakuro üretici algoritması ve teknik seviyeleri

- Tarih: 2026-10-19, **gözden geçirildi 2026-10-21**
- Durum: kabul edildi
- Dayanak: ADR 0005 (boyutlar), ADR 0010 (`guessing` kararı), ADR 0012 (ölçüm disiplini)
- Not: Bu ADR'nin ilk hali üreticiyi "çözülemedi" diye kapatıyordu ve **teşhisi yanlıştı**.
  Yanlış teşhis ve nasıl düzeltildiği aşağıda duruyor; silinmedi, çünkü bu dosyanın işi
  kararın nasıl alındığını üç ay sonra okunabilir kılmak.

## Bağlam

Faz 2'nin üçüncü varyantı. Brief b.6 Kakuro'nun üretim zorluğunu "yüksek" olarak işaretliyor
ve haklı çıktı.

Beklenen zorluk desen kurulumuydu: her kesit 2-9 uzunluğunda olmak zorunda, uzun kesitleri
siyah hücreyle kırmak gerekiyor ama her kırma dik yöndeki kesidi de ikiye ayırıyor. **Bu
kısım kolay çözüldü**: ihlal miktarını ölçüp azaltan hamleleri kabul eden bir arama, dört
boyutun hepsinde geçerli desen buluyor ve maliyeti 6 ms'nin altında.

Asıl zorluk benzersizlikte çıktı. Diğer üç varyantta çalışan yaklaşım — çözümü kur, bulmacayı
ondan türet, benzersizliğe hat karar versin — Kakuro'da **hiç işlemedi**: 1.160 adayda sıfır
benzersiz.

## Yanlış teşhis ve düzeltilmesi

İlk teşhis şuydu: dört kesidi de 2 hücreli olan bir 2×2 blok, ızgaranın geri kalanından kopuk
bir denklem sistemi oluşturuyor —

```
A B      A+B = S₁   C+D = S₂
C D      A+C = S₃   B+D = S₄
```

— ve `S₁+S₂ = S₃+S₄` olduğu için dört denklem bağımsız değil; dört bilinmeyene üç bağımsız
denklem kalıyor. Matematik doğru. **Ama sebep bu değildi.**

Desen ölçütüne kapalı blok cezası eklendi, üretilen desenlerde kapalı blok sayısı sıfıra
indi, ve **benzersizlik oranı sıfırda kaldı** (540 aday, dört boyut × üç yoğunluk).

Teşhisi bulan ölçüm şu oldu: benzersiz olmayan adaylarda kesitlerin bileşim sayıları
sayıldı. Ortanca toplam 118 — yani bulmaca başına yüzden fazla serbest seçim. Asıl sorun
**desende değil toplamlarda**: rastgele bir doldurma orta değerli toplamlar üretiyor ve orta
değerli bir toplamın onlarca rakam bileşimi var.

> "İki hücrede 17" demek {8,9} demek — tek bileşim.
> "İki hücrede 9" demek {1,8},{2,7},{3,6},{4,5} demek — dört bileşim, iki de sıralama.

Kakuro'nun çözülebilirliği kesitlerin bileşim sayısına bağlı, ve yayınlanmış Kakuro'da
toplamlar bu yüzden özenle seçiliyor. Rastgele doldurma o özeni taklit etmiyor.

**Kapalı blok cezası yine de kaldı.** Teşhis olarak yanlıştı ama kural olarak doğru: kapalı
blok gerçekten serbestlik derecesi bırakıyor, yalnız tek sebep değildi.

## Karar

### 1. Doldurma, kesitlerin bileşim sayısına göre eniyileniyor

Tepe tırmanma: rastgele bir giriş hücresine kesitlerinde kullanılmayan başka bir rakam
yazılıyor, bütün kesitlerin bileşim sayısı toplamı düşüyorsa kabul ediliyor.

Ölçülen etki belirleyici — 8×8'de **%0 → %17**, maliyet ortancası 118'den 41'e:

| Eniyileme adımı | Benzersiz (60 aday) | Maliyet ortancası |
|---|---|---|
| 0 | **0** | 118 |
| 2.000 | **10** | 41 |
| 8.000 | 8 | 40 |

Maliyet artımlı hesaplanıyor: bir hücreyi değiştirmek yalnız o hücrenin iki kesidini
etkiliyor. İlk sürüm her hamlede bütün ızgarayı yeniden bölütleyip yeniden sayıyordu ve
üretim süresinin büyük kısmı oradaydı — düzeltilince Easy ortancası 30 ms'den 9 ms'ye indi.

### 2. Yönlendirme döngüsü: üretici hedef zorluğu kendisi arıyor

Üretici hedef zorluğu biliyor, o yüzden her turda deseni baştan kurmak yerine aynı desen
üzerinde doldurmayı değiştiriyor. Döngü iki şeyi birlikte arıyor: benzersizlik **ve** hedef
zorluk. Tur başına maliyet bir benzersizlik kontrolü; desen kurulumu değil.

Bulmaca çok çözümlüyse iki çözümün ayrıştığı bir hücre bozuluyor — o hücrenin iki kesidinin
toplamı değişiyor ve eski alternatif artık geçerli değil. Benzersiz ama hedef zorlukta
değilse rastgele bir hücre bozuluyor.

Sonuç: hedef zorluk **%100 tutuyor** (160 bulmacanın hepsi). Hattın elemesi nadir; hat yine
de benzersizliği bağımsız olarak kontrol ediyor ve bu bilerek böyle — brief b.11'in garantisi
iki ayrı yerde duruyor.

### 3. Zorluğun kolu: eniyileme adımı sayısı

Maliyet düştükçe kesitler uç toplamlara kayıyor, uç toplamın tek bileşimi oluyor ve bulmaca
temel tekniklerle açılıyor. Az adım, daha belirsiz toplamlar ve daha ileri teknik demek.

| Zorluk | Izgara | Eniyileme adımı | Onarım sonrası adım | Yönlendirme turu |
|---|---|---|---|---|
| Easy | 8×8 | 4.000 | 400 | 40 |
| Medium | 10×10 | 2.200 | 150 | 150 |
| Hard | 10×10 | 1.200 | 60 | 150 |
| Expert | 11×11 | 900 | 40 | 120 |

Onarım sonrası adımın zorlukla azalması önemli: her tur maliyeti düşürmek, kazanılan zorluğu
geri veriyor ve bulmaca temel seviyeye kayıyor.

### 4. Boyutlar ADR 0005'ten sapıyor

ADR 0005 Kakuro için 8/10/12/14 yazıyordu ve bu ölçüm öncesi bir tahmindi. Ölçülen:
**8/10/10/11.** 14×14'te (96 giriş hücresi) hiç benzersiz bulmaca çıkmadı ve 12×12'de üretim
bütçeyi zorluyordu. Hard ile Expert'in ayrımı Calcudoku'daki gibi boyut + mantıksal
ilerlemeye bakıyor (ADR 0012), teknik seviyesi birincil kalarak.

### 5. Benzersizlik önce yayılımla, sonra sınırlı aramayla

Yayılım sağlam: bütün hücreleri kesinleştirdiyse o tek çözüm demektir ve aramaya gerek yok.
`findSolutions` önce bunu deniyor. Temel ve orta seviyedeki bulmacalar burada kapanıyor —
benzersizlik kontrolü **0,05 ms**.

İleri seviyedeki bulmacalar mantıkla kapanmıyor ve sınırlı aramayla kabul ediliyor
(`searchNodeBudget`). Varsayım tekniği kabul kapısında kullanılmıyor: Kakuro'nun boyutlarında
tek bir varsayım geçişi yüzlerce yayılım çalıştırıyor.

Bütçe tükenirse sonuç `.indeterminate` ve aday eleniyor. **Benzersizliği kanıtlanamamış
bulmaca kullanıcıya verilmiyor** — brief b.11'in garantisi "doğruladık" demek, "muhtemelen"
demek değil.

### 6. Ortak katmana iki ekleme

- **`SolveOutcome.indeterminate`** ve `SolverError.searchBudgetExhausted` — yukarıdaki için.
- **`GenerationError.attemptFailed`** — üretici "bu tohumla olmadı, başkasını dene" diyebilmeli.
  `invalidCandidate`'ten farkı: o programlama hatası, bu normal sonuç. Hat bunu eleme sayıyor
  ve devam ediyor. Kakuro'nun yönlendirme döngüsü olmadan çalışamıyordu.

## Ölçüm

Apple Silicon, release, seri koşu. Zorluk başına 40 üretim.

| Zorluk | Giriş | Siyah | Deneme ort. | En kötü | Süre ortanca | Süre en kötü | Hedef seviye |
|---|---|---|---|---|---|---|---|
| Easy | 33 | %47 | 1 | 4 | 9,4 ms | 59 ms | basic 40/40 |
| Medium | 52 | %47 | 3 | 15 | 73 ms | 360 ms | intermediate 40/40 |
| Hard | 52 | %47 | 4 | 14 | 108 ms | 245 ms | advanced 40/40 |
| Expert | 59 | %51 | 2 | 12 | 224 ms | **1.222 ms** | advanced 40/40 |

`guessing` hiç görülmedi. 500 bulmaca özellik testinde en kötü deneme sayısı 24.

Kesit uzunluğu dağılımı Easy'de 2:652 3:139 4:75 5:16 6:32 7:53 — yayınlanmış Kakuro'nun
dağılımına benziyor (ağırlıklı 2-3 hücreli, az sayıda uzun kesit).

### Performans ölçümünün kendisi düzeltildi

Kakuro Expert'in ilk CI ölçümü **2.606 ms** verdi ve testi kırdı; aynı üretim tek başına
568 ms. Fark paralel yükten: Swift Testing testleri eşzamanlı koşturuyor ve 500 bulmaca
testleri performans ölçümünün üstüne biniyordu.

Düzeltme: performans paketleri `.serialized`, ve CI'da performans adımı özellik
testlerinden ayrı. **Paralel yük altında yapılan süre ölçümü anlamsız** — bu, diğer üç
varyantta fark edilmedi çünkü payları yüz kat genişti.

## Sonuçları

- **Kakuro bitti ve Faz 2'de dört varyantın dördü tamam.** Slitherlink kaldı.
- **Expler payı dört varyantın en darı:** en kötü 1.222 ms / 2.000 ms = 1,6 kat. (Hashi 65,
  Hitori 20, Calcudoku 11.) Faz 3'teki cihaz ölçümü asıl kapı ve iPhone 12'de bu payın
  yetmemesi muhtemel. Brief b.11 bu durumun çözümünü zaten yazıyor: "arka planda önceden
  üretip kuyrukta tutmak". O karar cihaz ölçümüyle birlikte alınacak, şimdi değil.
- **Dört varyantın hepsinde zorluk hedefi %100 tutuyor** ama Kakuro'da bunun sebebi farklı:
  diğerlerinde hat eliyor, Kakuro'da üretici kendisi arıyor. Üreticinin hedefi bilmesi
  Kakuro'da zorunluydu; diğerlerinde olsa da iyi olurdu ve V2'de düşünülebilir.
- **Yanlış teşhisin maliyeti bir tur oldu.** Kapalı blok cezası eklendi, ölçüldü, sonuç
  değişmedi, ve ancak o zaman doğru yere bakıldı. Ölçüm olmasaydı yanlış teşhis üzerine
  inşa edilmeye devam edilirdi.

## Değerlendirilen alternatifler

- **Yerel onarım döngüsü tek başına** (eniyileme olmadan): 60 turda yakınsamıyor, çünkü
  yüksek maliyetli bir doldurmada birbirinden bağımsız onlarca serbestlik derecesi var.
  Eniyilemeyle birlikte çalışıyor — ikisi birbirinin yerine değil, yanına.
- **Uç rakam yanlılığı** (hücre başına uç rakamları önce denemek): zorlanmış kesit oranını
  %12'de bırakıyor, yetmiyor. Kesit toplamını hedeflemek gerekiyor, hücre rakamını değil.
- **Yoğunluğu artırmak ya da azaltmak:** eniyileme olmadan hiçbir yoğunlukta benzersizlik
  çıkmıyor; eniyilemeyle birlikte yoğunluğun etkisi küçük.
- **Expert'i 12×12 ya da 14×14 tutmak:** 14×14'te sıfır benzersiz, 12×12'de en kötü süre
  1.951 ms. 11×11 ölçümle seçildi.
- **Varsayım tekniğini kabul kapısında kullanmak:** tek geçiş yüzlerce yayılım demek,
  saniyelere çıkıyor. Teknik çözücüde duruyor (derecelendirme için), kapıda değil.
- **Arama bütçesini büyütüp belirsizleri kabul etmek:** benzersizliği kanıtlanmamış bulmaca
  vermek demek. Brief b.11 kapalı.
