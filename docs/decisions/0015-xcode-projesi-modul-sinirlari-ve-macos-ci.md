# ADR 0015 — Xcode projesi, modül sınırları ve macOS CI işi

- Tarih: 2026-10-24
- Durum: kabul edildi
- Dayanak: ADR 0002 (iOS 17), ADR 0003 (CI topolojisi), ADR 0004 (sıfır bağımlılık)

## Bağlam

Faz 3 arayüzü getiriyor ve bunun için ilk kez bir Xcode projesi gerekiyor. Üç şey
kararsızdı: proje dosyası nasıl tutulacak, brief b.9'un katman şeması paketlere nasıl
bölünecek, ve macOS CI işi ne zaman koşacak. Çalışırken dördüncü bir şey çıktı: elimizdeki
Xcode ile iOS 17 simülatörü kurulamıyor.

## Karar

### 1. `.xcodeproj` elle yazılıyor, senkronize klasör gruplarıyla

Proje dosyası repoda, `App/Pencilmark.xcodeproj/project.pbxproj`. Üretici araç
(XcodeGen, Tuist) kullanılmıyor: ADR 0004 sıfır bağımlılık kuralını test hedeflerine
genişletirken gerekçesini "bakım ve denetim yüzeyi" diye koymuştu ve bir proje üreticisi
tam olarak o yüzey — üstelik CI'da da kurulması gerekirdi.

Elle yazılan `pbxproj`'un bilinen acısı birleştirme çakışması: iki dal aynı anda dosya
eklerse proje dosyası çakışır. Bu acı **senkronize klasör gruplarıyla** (objectVersion 77,
`PBXFileSystemSynchronizedRootGroup`) ortadan kalkıyor: `App/Sources` ve `App/Tests`
klasörleri projeye klasör olarak bağlı, içlerine Swift dosyası eklemek proje dosyasına hiç
dokunmuyor. Proje dosyası ancak hedef, yapılandırma ya da paket bağımlılığı değişince
düzenleniyor — yılda birkaç kez.

### 2. Modüller ayrı paketler değil, aynı paketin hedefleri

Brief b.9 beş katman sayıyor (PuzzleKit, GameCore, Persistence, Store, App). Bunların her
biri ayrı bir SPM paketi olabilirdi; olmuyor. `GameCore` bu kararın ilk örneği:
`Packages/PuzzleKit/Package.swift` içinde ikinci bir hedef ve ikinci bir ürün.

Üç sebep:

- **CI kapısı tek kuralda kalıyor.** Ayrı paketler `.package(path:)` ile birbirine
  bağlanırdı; o zaman bağımlılık kapısının "yerel yol serbest, uzak yasak" diye ayrım
  yapması gerekirdi. Açılan her kapı, sonradan genişletilen kapıdır. Şimdi kural tek
  cümle: **hiçbir `Package.swift`'te `.package(` geçmez.**
- **Linux'ta 1x maliyetle test.** GameCore arayüze bağlı olmadığı için geri alma yığını ve
  oyun oturumu mantığı macOS runner'ına hiç uğramadan test ediliyor.
- **Tek manifest.** Beş paket beş manifest, beş platform listesi ve beş Swift sürümü
  ayarı demek; hepsinin aynı kalması elle sürdürülen bir disipline bağlı olurdu.

Paketin adı `PuzzleKit` kalıyor ama artık iki ürün veriyor. Dizin adını değiştirmek on dört
ADR'deki yolları geçersiz kılardı; kazancı yoktu.

### 3. macOS CI işi yalnız arayüze dokunan PR'larda

ADR 0003 macOS dakikasının private repoda 10x sayıldığını ve işin Faz 3'te ekleneceğini
yazmıştı. İş eklendi ve `App/`, `Package.swift` ya da `ci.yml` değişmediyse koşmuyor.
Hangi dosyanın değiştiğini `git diff` söylüyor, hazır bir action değil — action da
denetlenmesi gereken bir bağımlılık (lint işindeki aynı gerekçe).

Simülatör çalışma zamanı **henüz sabitlenmedi**. ADR 0004 bunu anlık görüntü testleri için
şart koşuyor ve haklı; ama bugün karşılaştırılacak referans görüntü yok, dolayısıyla
sabitlenecek bir şey de yok. Çalışma zamanı sabiti #36 ile, referanslarla birlikte
geliyor. O güne kadar her koşu `xcodebuild -version` ve çalışma zamanı listesini log'a
yazıyor.

### 4. iOS 17 doğrulama boşluğu — minimum 17.0 kalıyor

Geliştirme makinesinde Xcode 27.1 var ve kurulabilen en eski iOS simülatör çalışma zamanı
**18.2**. Yani iOS 17'de hiçbir şey çalıştırılamıyor.

Minimum sürüm yine de 17.0 kalıyor (ADR 0002 değişmiyor). Asıl koruma derleyicinin
availability kontrolü: dağıtım hedefi 17.0 olduğu sürece 18+ API'si kullanmak **derleme
hatası**, yani sessizce kaçamıyor. Kalan risk davranış farkları — aynı API'nin iOS 17'de
başka davranması — ve bu yalnız gerçek cihazda görülür. Faz 4'teki TestFlight dış testi bu
boşluğun kapandığı yer; iPhone 12 ölçümü zaten oraya bırakılmıştı (ADR 0003).

Alternatif minimumu 18.0'a çekmekti. Reddedildi: iOS 17 cihazlar hâlâ kullanımda ve bu
kitle (35 yaş üstü) telefonunu geç yeniliyor. Test edilemiyor olmak, desteklenmemesi için
yeterli sebep değil — ölçülmemiş bir risk, kapatılmış bir pazardan iyi.

### 5. Uygulama kimliği ve hedef

| Alan | Değer | Gerekçe |
|---|---|---|
| Paket kimliği | `com.pencilmarkgames.puzzles` | Brief b.4'teki geliştirici adı "Pencilmark Games" |
| Görünen ad | `Kakuro & Calcudoku Puzzles` | Brief b.4 birebir kullanılmasını şart koşuyor |
| Cihaz ailesi | Yalnız iPhone | iPad, 12×12 ızgara için ayrı yerleşim ve anlık görüntü matrisinin iki katı demek |
| Yön | Yalnız dikey | Izgaralar kare; telefonda yatay yön dikey alanı ve rakam çubuğunu sıkıştırıyor |

Paket kimliği ilk App Store yüklemesine kadar değiştirilebilir; sonrasında kilitleniyor.
iPad ve yatay yön Faz 5 konusu.

## Sonuçları

- Yeni Swift dosyası eklemek proje dosyasına dokunmadığı için iki dal paralel çalışabiliyor.
  Buna karşılık hedef veya yapılandırma eklemek elle `pbxproj` düzenlemek demek; bu
  dosyanın biçimi affedici değil ve bozulursa Xcode projeyi hiç açmıyor.
- `Persistence` ve `Store` katmanları geldiğinde aynı pakete hedef olarak girecekler.
  Store StoreKit'e bağlı olduğu için Linux'ta derlenmeyecek; o hedef eklenirken Linux
  işinin hedef süzmesi gerekecek. Bugünden görülen, bugünden çözülmeyen bir iş.
- macOS işi atlandığında PR'da "başarılı" değil "atlandı" görünüyor. Dal koruma kuralı
  yazılırken bu işin **zorunlu** işaretlenmemesi gerekiyor, yoksa motor PR'ları
  birleştirilemez.
- iOS 17 doğrulaması Faz 4'e kadar yapılmamış bir varsayım olarak duruyor ve bu ADR onu
  görünür kılmak için var.

## Değerlendirilen alternatifler

- **XcodeGen / Tuist:** proje dosyasını YAML'dan üretir, çakışmayı bitirir. Üçüncü parti
  araç, CI'da kurulum adımı ve ADR 0004'ün açıkça kapattığı yüzey.
- **Her katman ayrı SPM paketi:** sınırları en net ayıran seçenek. Bağımlılık kapısını
  bulanıklaştırması ve beş manifestin bakımı yüzünden seçilmedi.
- **Uygulamayı tek bir SPM paketi olarak kurmak:** iOS uygulama paketi (Info.plist,
  entitlement, StoreKit yapılandırması) SPM ile üretilemiyor; seçenek değil.
- **macOS işini her PR'da koşturmak:** en basit yapılandırma. 10x dakika maliyeti motor
  PR'larında karşılıksız.
