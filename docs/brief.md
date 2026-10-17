# Kakuro & Calcudoku Puzzles — Geliştirici Brief

> 16 Ekim 2026 · @kemal
> Bu doküman işin tek referans kaynağıdır. Orijinali: [`brief.pdf`](brief.pdf).
> Burada alınan kararların gerekçeleri `decisions/` altındaki ADR dosyalarındadır.

## 1. Özet

Tek bir iOS uygulaması içinde beş klasik mantık bulmacası: Kakuro, Calcudoku, Slitherlink,
Hashi ve Hitori. Hedef pazar ABD, arayüz dili İngilizce. Reklam bütçesi sıfır — bütün
kullanıcı kazanımı App Store araması (ASO) ve organik paylaşım üzerinden gelecek.

Bu, pazar fırsatına göre seçilmiş bir ürün. Beş varyantın hepsi App Store'da gerçek arama
talebi olan ama zirvesi zayıf kalmış kategoriler. **Varyantların kapsamdan çıkarılması ya da
değiştirilmesi o veriyi geçersiz kılar — önce konuşulur.**

## 2. Neden bu beş bulmaca

21 klasik bulmaca türünün taranmasıyla seçildi. Kriter: gerçek arama talebi olan ama
zirvedeki uygulaması zayıf kalmış kategoriler.

| Varyant | Yıllık talep | Kategori uyg. | Lider uygulama | Lider yorum |
|---|---|---|---|---|
| Kakuro | 35.447 | 17 | Real Kakuro | 2.626 |
| Calcudoku / Mathdoku | 29.402 | 3 | Mathdoku+ | 435 |
| Slitherlink | 16.614 | 23 | Slitherlink: Loop the Snake | 461 |
| Hashi (Bridges) | 11.346 | 15 | Hashi: Linkdoku Bridges | 32 |
| Hitori | 9.403 | 10 | Hitori - Logic Puzzles | 44 |

**Talep** sütunu, bulmacanın İngilizce Wikipedia maddesine son 12 ayda gelen ziyaret sayısı —
gerçek App Store arama hacmi değil, vekili. Bilinen yanlılığı var: insanlar bilmedikleri
bulmacanın kurallarına bakar, bildiklerininkine bakmaz; niş varyantlar mainstream'e göre
yüksek görünür. Varyantları birbiriyle karşılaştırmak için güvenilir, Sudoku ile değil.

**Kategori uyg.** sütunu, Apple'ın arama API'sinde o terim için dönen ilk 30 sonuçtan
kaçının adında terimin geçtiği. Veri 16 Ekim 2026 tarihli ABD mağazası anlık görüntüsü.

Karşılaştırma için kapalı kategoriler: Sudoku liderinde 1.863.911, Crossword'de 296.856,
Nonogram'da 195.731 yorum var. Bizim seçtiğimiz beşte en güçlü lider 2.626 yorumda.

**Calcudoku anomalisi — en değerli bulgu:** talep 29.402 ama kategoride yalnızca 3 uygulama
var ve lider 435 yorumda. Sebebi, "KenKen" ve "KenDoku" adlarının Nextoy LLC'nin tescilli
markası olması. New York Times her gün KenKen yayınlıyor, oyuncu kitlesi oyunu biliyor, ama
mağazada karşılığı yok. Talebi rekabet değil marka hukuku bastırıyor. "Calcudoku" ve
"Mathdoku" bu bulmacanın tescilsiz jenerik adları ve serbestçe kullanılabilir.

## 3. Rakipler ve bizim farkımız

Rakip zayıflıklarının çoğu aynı yerden geliyor: tek kişilik hobi projeleri, terk edilmiş ya
da uzun süredir bakımsız. Kakuro'da ilk beşin ikisi 2023'ten beri, Hitori'de dördün üçü bir
yıldan uzun süredir güncellenmemiş.

| Varyant | Liderin zayıf noktası | Bizim farkımız |
|---|---|---|
| Kakuro | En güçlü rakip (2.626 yorum), ama üst beşin ikisi 2023'ten beri güncellenmemiş | Aktif bakım, modern iOS arayüzü, günlük bulmaca |
| Calcudoku | Kategori neredeyse boş, lider 435 yorumda ve dar kapsamlı | Birden çok grid boyutu ve zorluk, düzgün öğretici |
| Slitherlink | Lider iyi puanlı (4,8) ama tek bulmaca, ilerleme sistemi yok | Aynı uygulamada dört bulmaca daha, ortak ilerleme |
| Hashi | Lider yalnızca 32 yorumda — kategori fiilen sahipsiz | Erken girip yorum biriktirmek; en düşük giriş eşiği |
| Hitori | Lider 44 yorum ve 3,8 puan — kullanıcılar memnun değil | Mevcut şikâyetleri çözen temiz bir uygulama |

Hitori'deki 3,8 puan tek başına fırsat sinyali: orada yalnızca boşluk değil, memnuniyetsiz
kullanıcı da var. Geliştirmeye başlamadan önce o uygulamanın yorumlarını okuyup tekrar eden
şikâyetleri çıkarmak ilk işlerden biri (Faz 0).

Rekabet üstünlüğü tek bir özellikte değil, üçün birleşiminde: **beş bulmaca tek uygulamada**
(rakiplerin hepsi tek bulmaca), **aktif bakım** (rakiplerin yarısı terk edilmiş) ve
**güvenilir üretici** (benzersiz çözümü garanti edilen bulmacalar — bu kategorideki en yaygın
şikâyet konusu).

## 4. Store kimliği ve ASO

Bu alanlar karar verilmiş durumda. Kod içinde, `Info.plist`'te ve App Store Connect'te
birebir bu şekilde kullanılmalı; değiştirmek ASO stratejisini bozar.

| Alan | Değer | Limit |
|---|---|---|
| Uygulama adı | Kakuro & Calcudoku Puzzles | 26/30 |
| Alt başlık | Slitherlink, Hashi & Hitori | 27/30 |
| Geliştirici adı | Pencilmark Games | — |
| Birincil kategori | Games → Puzzle | — |
| İkincil kategori | Games → Board | — |

Anahtar kelime alanı (virgülle ayrılmış, boşluksuz, ~95/100 karakter):

```
mathdoku,bridges,logic,brain,nurikabe,futoshiki,masyu,takuzu,binary,daily,sums,japanese
```

Ad ve alt başlıktaki kelimeler burada tekrarlanmaz; Apple onları zaten indeksler. Listedeki
`nurikabe`, `futoshiki`, `masyu` ve `takuzu`, taramada tespit edilen ama ayrı ürün olmaya
değmeyen uydu varyantlar. İleride mod olarak eklenirlerse bu kelimeler meşrulaşır (Faz 5).

Uyulması gereken iki kural:

1. **Rakip marka adları anahtar kelime alanına yazılmaz.** "KenKen", "KenDoku", "Nikoli" ve
   rakip uygulama adları Apple'ın kurallarına aykırıdır ve ret sebebidir.
2. **Uygulama içi metinlerde bulmaca adları jenerik biçimleriyle geçer:** "Calcudoku" veya
   "Mathdoku", asla "KenKen".

İsim ve geliştirici adı müsaitliği App Store Connect'ten doğrulanmış olmalı; mağaza
aramasında görünmemek müsait olduğu anlamına gelmez.

## 5. V1 kapsamı

V1'in amacı mağazada yayında olmak ve yorum biriktirmeye başlamak. Kapsam bunu geciktirecek
her şeye kapalı.

**V1'de var:**

- Beş bulmaca: Kakuro, Calcudoku, Slitherlink, Hashi, Hitori
- Her varyant için cihazda çalışan üretici; benzersiz çözüm garantili
- Varyant başına dört zorluk: Easy, Medium, Hard, Expert
- Günlük bulmaca: her gün bir varyant, tarihten türetilen sabit tohum (herkes aynı bulmacayı görür)
- Kalem işareti (aday not alma), sınırsız geri alma/ileri alma, ipucu, hata kontrolü
- Otomatik kayıt ve yarım kalan bulmacaya dönme
- İstatistik: çözülen sayısı, en iyi süre, seri
- Karanlık mod, Dynamic Type, VoiceOver desteği
- İngilizce (tek dil)

**V1'de kesinlikle yok:**

- Hesap, giriş, sunucu, bulut senkronizasyonu — V1 tamamen çevrimdışı ve cihazda
- Çok oyunculu, liderlik tablosu, arkadaş sistemi
- Reklam (b.8)
- Android, iPad'e özel düzen, Apple Watch
- Türkçe veya başka dil; yerelleştirme altyapısı hazır olsun ama çeviri V1'de yok

**Başarı kriterleri — V1 şunları yapıyorsa hazırdır:**

- Beş varyantın her biri, her zorlukta, benzersiz çözümü doğrulanmış bulmaca üretiyor
- Üretim süresi en zor seviyede bile cihazda 2 saniyenin altında
- Çökme oranı binde 1'in altında
- Uygulama App Store incelemesinden ilk gönderimde geçiyor

İlk üç ay için gerçekçi beklenti: aylık birkaç bin indirme, üç haneli yorum sayısı.

## 6. Bulmaca motoru

Beş varyantın tamamı aynı iskeleti paylaşır: ortak grid modeli, varyanta özel kural
doğrulayıcı, çözücü ve üretici. Üretim hattı her varyantta aynı işler:

```
tohum → üret → çöz → BENZERSİZ Mİ? → evet: ver
                         └─ hayır: ele, yeni tohumla baştan
```

**Kritik nokta karar adımı:** çözücü bulmacanın tam olarak bir çözümü olduğunu
doğrulayamazsa bulmaca elenir ve yeni tohumla baştan üretilir. **Bu kontrol sürüm
derlemesinde de açık kalır.**

| Varyant | Grid | Kural özeti | Üretim zorluğu |
|---|---|---|---|
| Kakuro | Değişken, bloklu | Her kesitteki rakamlar ipucu toplamını verir; kesit içinde tekrar yok; yalnızca 1-9 | Yüksek |
| Calcudoku | 4×4 – 9×9 | Her satır ve sütunda 1..n birer kez; her kafeste hedef sayı ve işlem tutar | Orta |
| Slitherlink | Nokta ızgarası | Tek kapalı döngü oluşur; sayı, çevresindeki çizgi sayısını söyler | Yüksek |
| Hashi | Ada yerleşimi | Adalar köprülerle bağlanır; iki ada arası en fazla 2 köprü; köprüler kesişmez; tüm adalar tek ağda | Düşük |
| Hitori | Kare grid | Tekrar eden sayılar karalanır; karalı hücreler komşu olamaz; beyaz hücreler bağlı kalır | Orta |

**Zorluk derecelendirme tahminle değil, çözücünün bulmacayı çözmek için kullandığı teknik
seviyesiyle belirlenir.** Çözücü yalnızca temel tekniklerle bitirdiyse Easy, ileri teknik
gerektiyse Hard. Grid boyutuna veya ipucu sayısına bakan derecelendirme bu kitleyi kızdırır.

**Geliştirme sırası** kural setinin karmaşıklığına göre:
Hashi → Hitori → Calcudoku → Kakuro → Slitherlink.
Hashi en basit kural setine sahip, hattın tamamını onunla kurup doğrulamak en hızlısı.
Slitherlink'in döngü kontrolü en zoru, en sona bırakılıyor.

## 7. Oyun deneyimi

Kitle yetişkin, çoğunlukla 35 yaş üstü, kâğıt-kalem bulmaca geçmişi olan insanlar.
Beklentileri sakin, okunaklı ve hızlı bir arayüz — animasyon, rozet ve ses efekti değil.
Tasarım yönü: kâğıt hissi, yüksek kontrast, geniş dokunma hedefleri.

**Ekranlar**

1. **Ana ekran** — beş varyant kartı, her birinde günlük bulmaca rozeti ve yarım kalan oyun varsa "devam et"
2. **Zorluk seçimi** — dört seviye, her birinde çözülen sayısı
3. **Bulmaca ekranı** — grid, giriş çubuğu, araç çubuğu (geri al, kalem, ipucu, kontrol)
4. **İstatistik** — varyant başına çözülen, en iyi süre, seri
5. **Ayarlar** — tema, dokunsal geri bildirim, otomatik hata kontrolü, satın alma geri yükleme

**Giriş modeli** varyanta göre değişir:

| Varyant | Giriş |
|---|---|
| Kakuro | Hücre seç, 1-9 rakam çubuğu |
| Calcudoku | Hücre seç, grid boyutuna göre rakam çubuğu |
| Slitherlink | Kenara dokun: çizgi → çarpı → boş döngüsü |
| Hashi | Adadan adaya sürükle; tekrar dokunmak köprüyü ikiye çıkarır, üçüncüsü siler |
| Hitori | Hücreye dokun: karala → işaretle → boş döngüsü |

**Ortak davranışlar**

- **Kalem işareti:** bir hücreye birden çok aday yazabilme, küçük punto. Kakuro ve Calcudoku'da zorunlu; bu kitle onsuz oynamaz.
- **Geri alma** sınırsız ve bulmaca oturumu boyunca kalıcı; ileri alma da var.
- **İpucu** tek bir hücreyi veya kenarı açar ve kaç ipucu kullanıldığını kaydeder. İpucu kullanılan bulmaca "çözüldü" sayılır ama istatistikte ayrı işaretlenir.
- **Hata kontrolü** iki modda: kullanıcı isterse anlık (yanlış girişi anında kızartır), varsayılan olarak manuel.
- **Otomatik kayıt** her hamlede; uygulama kapanıp açıldığında bulmaca tam olduğu yerden devam eder.

**Günlük bulmaca** tarihten türetilen sabit bir tohumla üretilir. Çözüm sonrası ekranda,
bulmacanın kendisini ele vermeyen bir **paylaşım kartı** üretilir: varyant adı, tarih, süre,
ipucu kullanıldıysa işareti. Bu tek organik yayılma kanalımız — düzgün çalışması önemli.

## 8. Monetizasyon

**Reklam yok.** Bilinçli karar: reklam geliri hacimle çalışır, bizim hacmimiz olmayacak; bu
kitle reklamdan rahatsız olur ve bunu yoruma yazar; yorum sayısı bizim tek sıralama
varlığımız. Reklam, kazandıracağından fazlasını götürür.

Model: ücretsiz oyna, sınırsızlık için öde.

| Katman | İçerik | Fiyat |
|---|---|---|
| Ücretsiz | Günde 3 bulmaca + günlük bulmaca, tüm varyantlar, Easy ve Medium | — |
| Pencilmark Plus (aylık) | Sınırsız bulmaca, tüm zorluklar, istatistik geçmişi | 2,99 USD |
| Pencilmark Plus (yıllık) | Aynısı | 14,99 USD |
| Ömür boyu | Aynısı, tek seferlik | 24,99 USD |

Ücretsiz katmanın **tüm varyantları** içermesi önemli: insanlar arama sonucundan "Hashi" diye
gelip Hashi'yi oynayamazsa hemen siler ve kötü yorum bırakır. Kısıtlama varyantta değil,
günlük hacimde ve zorlukta.

Ömür boyu seçeneği bu kitle için gerçekten gerekli — 40 yaş üstü bulmaca oyuncusu aboneliğe
dirençlidir. Yıllık fiyatın yaklaşık 1,7 katı doğru aralık.

**Uygulama kuralları**

- **Paywall, kullanıcı en az 3 bulmaca bitirmeden gösterilmez.** Erken paywall bu kategoride silinme sebebi.
- StoreKit 2 kullanılacak. Satın alma geri yükleme ayarlar ekranında zorunlu (Apple kuralı).
- Abonelik şartları, gizlilik politikası ve kullanım koşulları paywall ekranından erişilebilir olmalı; eksikliği ret sebebidir.
- Fiyatlandırma ileride değişebilir; kodda sabit değer olarak değil, App Store Connect ürün kimlikleri üzerinden okunmalı.

## 9. Teknik yığın

| Karar | Seçim | Gerekçe |
|---|---|---|
| Platform | iOS 17+ | Gelirin tamamı iOS tarafında; tek platforma odaklanmak V1'i hızlandırır |
| Dil | Swift 6, strict concurrency | Üretici/çözücü CPU yoğun; native performans gerekli |
| Arayüz | SwiftUI, grid çizimi Canvas ile | Grid'ler yüzlerce hücre; her hücre ayrı view olursa kaydırma takılır |
| Saklama | SwiftData | Yerel, hafif; sunucu yok |
| Satın alma | StoreKit 2 | — |
| Bağımlılık | Yok (SPM dahil) | Bağımlılık yüzeyi sıfır tutulur |
| Analitik | Yok (V1) | İzleme yoksa gizlilik etiketi temiz kalır ve ATT izni sorulmaz |

**Katmanlar** — modüller arası bağımlılık tek yönlü, oklar aşağı akar:

```
PuzzleKit     saf Swift, UIKit/SwiftUI bağımsız
              ├── Grid, Cell, Move, Solution (ortak model)
              ├── <Variant>Rules      kural doğrulama
              ├── <Variant>Solver     çözüm ve benzersizlik kontrolü
              └── <Variant>Generator  üretim

GameCore      oyun oturumu, geri alma yığını, ipucu, istatistik
              → PuzzleKit

Persistence   SwiftData modelleri, kayıt/yükleme
              → GameCore

Store         StoreKit 2, yetki kontrolü

App           SwiftUI ekranları, grid çizimi, paywall
              → GameCore, Persistence, Store
```

`PuzzleKit` ayrı bir SPM paketi olmalı ve arayüze hiç bağımlı olmamalı. İki sebeple:
üretici/çözücü testleri arayüz olmadan ve çok hızlı koşar; ileride Android veya ek varyant
gerekirse motor taşınabilir kalır.

**Tüm üretim cihazda, çevrimdışı çalışır.** Önceden üretilmiş bulmaca paketi gönderilmez —
paket biterse uygulama ölür ve bu rakiplerin düştüğü tuzaklardan biri.

## 10. Çalışma disiplini — GitHub akışı

**Bu bölüm bağlayıcı.** Amaç, projeyi başkasının devralabileceği ve her kararın neden
alındığının geriye dönük okunabileceği şekilde ilerletmek. **Hiçbir iş doğrudan `main`'e
yazılmaz.**

```
/Packages/PuzzleKit/      SPM paketi — motor
/App/                     Xcode projesi
/docs/decisions/          ADR dosyaları (0001-*.md)
/docs/progress.md         kronolojik iş günlüğü
/.github/                 PR şablonu, workflow
README.md                 kurulum, çalıştırma, test
```

**Her iş için döngü — istisnasız:**

1. **Issue aç.** Ne yapılacak, neden, kabul kriteri ne. Kabul kriteri yoksa issue hazır değildir.
2. **Dal aç.** `feat/kakuro-generator`, `fix/undo-stack-leak`, `chore/ci-setup`. Tek dal tek konu.
3. **Küçük commit'ler.** Conventional Commits. Commit mesajı ne yapıldığını değil, neden yapıldığını da söyler.
4. **PR aç** — issue'ya `Closes #12` ile bağlı. Şablon doldurulur.
5. **CI yeşil olmadan merge yok.**
6. Merge sonrası `docs/progress.md`'ye tek satır eklenir.

**Karar kaydı** (`docs/decisions/`) — geri dönmesi pahalı olan her teknik karar için kısa bir
ADR: başlık, bağlam, karar, sonuçları, değerlendirilen alternatifler. Yarım sayfayı geçmesin.

**İlerleme bildirimi** — her PR açıldığında üç satır: ne yaptın, neyi doğruladın, neyi
bilerek erteledin. PR linkini ekle.

## 11. Test ve kalite kapıları

Bu projede tek gerçek kalite riski üreticide. Kullanıcı kötü arayüzü affeder, çözümü olmayan
ya da iki çözümü olan bulmacayı affetmez — ve bunu tek yıldızla yazar.

**Üretici doğrulaması — pazarlık konusu değil.** Her üretilen bulmaca, kullanıcıya
verilmeden önce çözücüden geçer ve iki şey doğrulanır: en az bir çözüm var, ve birden fazla
çözüm yok. Doğrulamayı geçemeyen bulmaca atılır ve yenisi üretilir. **Bu kontrol sürüm
derlemesinde de açık kalır; performans gerekçesiyle kapatılmaz.**

| Katman | Ne test edilir | Nerede koşar |
|---|---|---|
| Birim | Kural doğrulama, hamle geçerliliği, geri alma yığını | Her PR |
| Özellik (property) | Rastgele 500 bulmaca üret → hepsi benzersiz çözümlü | Her PR |
| Çözücü | Bilinen bulmaca + bilinen çözüm eşleşmeleri | Her PR |
| Performans | Üretim süresi zorluk başına ölçülür | Her PR |
| Anlık görüntü | Grid çizimi, karanlık mod, Dynamic Type | Her PR |

**Performans bütçeleri** — aşılırsa PR geçmez:

- Bulmaca üretimi: Expert seviyede iPhone 12'de 2 saniyenin altında
- Grid çizimi: 60 fps, kaydırma ve yakınlaştırmada kare düşürmeden
- Soğuk açılış: 1,5 saniyenin altında
- Üretim arayüzü kilitlemez; arka planda koşar ve ilerleme gösterilir

**CI** — GitHub Actions, her PR'da: derleme, testler, SwiftLint, performans testleri.
Kırmızı CI ile merge yok, istisnası yok.

Üretici yavaş kalırsa çözüm, doğrulamayı kapatmak değil, algoritmayı değiştirmek ya da arka
planda önceden üretip kuyrukta tutmaktır. Bu bir ADR konusudur.

## 12. App Store uyumu

**Guideline 4.3(b) riski — projenin en ciddi tek riski.** Apple Haziran 2026'da bu kuralı
sıkılaştırdı: uygulamalar "halihazırda yaygın olarak mevcut olandan ayırt edilemez" olamaz ve
"mevcut uygulama kategorilerinin fırsatçı varyantları" doğrudan hedefte. Ceza tek bir ret
olmayabilir; doymuş kategorilerde tekrarlayan düşük efor gönderimleri geliştirici hesabının
programdan çıkarılmasına kadar gidebiliyor.

Beş bulmacayı tek uygulamada toplama kararı kısmen bu yüzden alındı. Ama tek uygulama da
yetmez, farkın görünür olması gerekir:

- Fark ilk ekran görüntüsünde okunmalı: beş bulmaca tek uygulamada, açıkça.
- Ekran görüntüleri gerçek oyun ekranları olmalı; stok görsel veya sahte arayüz değil.
- Açıklama metni ilk iki cümlede ne sunduğumuzu söylemeli, anahtar kelime doldurması yapmamalı.
- Uygulama adı ve metadata'da anahtar kelime yığını yok.

**Marka kontrolü.** Başvurudan önce USPTO'da `Kakuro`, `Calcudoku`, `Mathdoku`,
`Slitherlink`, `Hashi`, `Hitori` için arama yapılmalı. Calcudoku ve Mathdoku'nun KenKen'in
tescilsiz karşılıkları olduğu doğrulandı. Diğerleri dünya genelinde jenerik kullanılıyor
ancak bu bulmacaların çoğunu Japon yayıncı Nikoli adlandırdı ve bazı adlarda Japonya'da
hakları var. ABD pazarı için risk düşük, yine de kontrol edilmeli — on dakikalık iş, ret
maliyeti haftalar.

**Gizlilik ve inceleme hazırlığı**

- Analitik ve üçüncü parti SDK olmadığı için gizlilik etiketi "veri toplanmıyor" olmalı; ATT izni sorulmaz.
- `PrivacyInfo.xcprivacy` eksiksiz doldurulur.
- Yaş sınırı 4+.
- Abonelik ekranında şartlar, gizlilik politikası ve satın alma geri yükleme zorunlu.
- Gizlilik politikası ve destek sayfası için bir web adresi gerekli — basit bir statik sayfa yeterli.
- Onay sonrası da tetikte kalınmalı: sıkılaşan kurallar altında yeniden incelemeler ve ani kaldırmalar daha olası.

## 13. Teslim sırası

Sıra riske göre diziliyor: en belirsiz iş (üretici) en başa alınıyor. Arayüzü önce yapıp
motoru sona bırakmak, projenin en büyük riskini en geç keşfetmek demektir.

- **Faz 0 · Kurulum.** Repo, CI, PR şablonu, `PuzzleKit` iskeleti, ortak Grid modeli. Ek
  olarak rakip araştırması: Hitori liderinin App Store yorumları okunur, tekrar eden
  şikâyetler `docs/` altına çıkarılır — bunlar Faz 3'te özellik listesine dönüşecek.
- **Faz 1 · Motor ve ilk varyant.** Hashi'nin kural doğrulayıcısı, çözücüsü ve üreticisi.
  Çıktı: benzersizlik doğrulamasından geçen bulmaca üreten, testleri yeşil bir motor. **Bu
  faz bitmeden arayüze geçilmez.** Performans bütçesi burada ölçülür; tutmuyorsa algoritma
  kararı ADR olarak burada alınır.
- **Faz 2 · Kalan dört varyant.** Hitori, Calcudoku, Kakuro, Slitherlink — bu sırayla. Her
  biri kendi PR'ında, kendi test setiyle.
- **Faz 3 · Arayüz.** Beş ekran, varyanta özel giriş modelleri, kalem işareti, geri alma,
  günlük bulmaca, istatistik, paywall. Faz 0'da çıkarılan rakip şikâyetleri burada karşılanır.
- **Faz 4 · Mağaza hazırlığı.** Ekran görüntüleri, açıklama metni, gizlilik beyanı, marka
  kontrolü, TestFlight ile dış test. Bölüm 12'deki 4.3(b) kontrol listesi tek tek geçilir.

Tarihler gösterge; kayma olursa kapsam değil takvim esner. Faz 1 uzarsa bu kötü haber değil —
motorun doğru olması her şeyden önemli.

## 14. Açık kararlar

Briefte varsayılanla geçilen konular. Hepsi karara bağlandı; gerekçeler `decisions/`
altındaki ADR dosyalarında.

| Konu | Varsayılan | Not |
|---|---|---|
| Minimum iOS sürümü | 17.0 | 16'ya inmek SwiftData'yı dışlar, saklama katmanı değişir |
| Üretici algoritması | Varyant başına ayrı; önce kaba kuvvet + benzersizlik elemesi, performans yetmezse ADR ile değiştir | Faz 1'de ölçülür |
| Calcudoku grid boyutları | 4×4'ten 9×9'a | Zorluk hem boyut hem kafes yapısıyla ayarlanır |
| Zorluk derecelendirme | Çözücünün kullandığı teknik seviyesine göre | Tahmine dayalı derecelendirme kullanıcıyı kızdırır |
| Günlük bulmaca varyant sırası | Haftanın gününe sabit eşleme | Pazartesi Kakuro, Salı Calcudoku, … |
| iPad desteği | Uyumlu çalışsın, özel düzen yok | V1 kapsamı dışı |
| Gizlilik politikası adresi | Geliştirici bir yer önersin | Statik sayfa yeterli |

## 15. Sahiplik ve erişim

- Apple Developer hesabı mevcut; App Store Connect erişimi Faz 4'ten önce paylaşılacak.
- GitHub repo `digitalsepa-git` altında, private.
- **Uygulama ikonu ve görsel kimlik geliştiricide.**
- Ekran görüntüsü metinleri ve açıklama metni onayı @kemal'de.
- Alan adı henüz yok, alınacak.
- Cihaz testi @kemal'de (iPhone 14 Pro Max).

**İlk hafta beklenen çıktı:** repo kurulu, CI yeşil, `PuzzleKit` iskeleti ayakta ve bir
varyantın (Hashi) üreticisi benzersizlik doğrulamasından geçen bulmaca üretiyor. Arayüz henüz
olmasa da olur; motor doğruysa gerisi gelir.

---

Kaynak (b.12): *Apple's 2026 Crackdown on Low-Value Apps*
