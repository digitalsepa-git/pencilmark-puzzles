# ADR 0003 — CI topolojisi ve performans ölçüm stratejisi

- Tarih: 2026-10-17
- Durum: kabul edildi, performans eşiği [ADR 0012](0012-calcudoku-uretici-ve-teknik-seviyeleri.md) ile güncellendi

## Bağlam

Brief b.11 iki şey istiyor ve ikisi aynı yerde buluşamıyor:

1. Her PR'da derleme, testler, SwiftLint ve performans testleri koşsun; kırmızı CI ile
   merge yok, istisnası yok.
2. Performans bütçesi "Expert seviyede **iPhone 12'de** 2 saniyenin altında".

GitHub Actions runner'ı iPhone 12 değil. Üstelik paylaşımlı sanal makine: aynı iş iki
koşuda iki kat fark verebiliyor. İkinci maddeyi CI'da kapı yapmak, PR'ların runner
gürültüsüne göre kırmızı olması demek — bu da birkaç haftada "CI'ı tekrar çalıştır"
alışkanlığına, oradan CI'a güvenmemeye gidiyor.

İkinci kısıt maliyet: repo private ve GitHub Free planında macOS runner dakikası
**10 kat** sayılıyor. Her PR'da macOS'ta koşan bir iş, aylık kotayı birkaç haftada bitirir.

## Karar

**İki iş, ikisi de Linux.**

- `engine` — `swift:6.4-noble` konteynerinde PuzzleKit derleme + testler + release modda
  performans testleri. PuzzleKit saf Swift ve Foundation'a bile bağımlı olmadığı için
  Linux'ta sorunsuz koşuyor; dakika maliyeti 1x.
- `lint` — resmî `ghcr.io/realm/swiftlint` imajıyla `swiftlint lint --strict`.

**macOS işi Faz 3'te eklenecek**, App hedefi ve anlık görüntü testleri geldiğinde — o
zaman gerçekten gerekli olacak ve yalnızca arayüze dokunan PR'larda koşacak.

**Performans iki ayrı yerde, iki ayrı eşikle ölçülüyor:**

| Nerede | Eşik | Amaç |
|---|---|---|
| CI (her PR) | Gevşek, gerçek bütçenin katları | Katastrofik regresyonu yakalamak |
| Cihaz (iPhone 14 Pro Max) | Brief b.11'deki gerçek bütçe | Bütçeyi doğrulamak |

> **ADR 0012 ile güncellendi.** Varyant performans testlerinin eşiği artık doğrudan brief
> b.11'in bütçesi (2.000 ms) ve ölçüm **yalnız release derlemede** yapılıyor. Release'te pay
> yeterince geniş olduğu için gevşek bir kat gerekmiyor; debug derlemede ise süre ürün
> ölçümü değil (aynı iş CI runner'ında 25 kat yavaş) ve testler orada hiç koşmuyor.

Cihaz ölçümü PR şablonundaki "cihazda denendi" satırıyla raporlanıyor. Ölçülen süreler
her CI koşusunda log'a yazılıyor (`[perf]` satırları), böylece regresyon sayıyla görünür.

**Test cihazı iPhone 14 Pro Max, brief'in referansı iPhone 12.** 14 Pro Max belirgin
şekilde daha hızlı; ölçülen sürenin bütçeye yakın çıkması bile iPhone 12'de aşıldığı
anlamına gelir. Bu yüzden cihaz ölçümünde hedef **1 saniye**: iPhone 12'ye payı bırakıyor.
Gerçek iPhone 12 ölçümü Faz 4'te TestFlight dış testinde yapılacak.

**CI'da ayrıca bağımlılık kapısı var:** `Package.swift`'e `dependencies:` eklenirse veya
`Package.resolved` ortaya çıkarsa iş kırmızı olur. Brief b.9'daki sıfır bağımlılık kuralı
yoruma bırakılmıyor.

## Sonuçları

- Linux'ta koşmak PuzzleKit'i Foundation'dan uzak tutma kararını kalıcı kılıyor; biri
  Foundation'a özgü bir API kullanırsa CI anında söyler. Bu istenen bir yan etki.
- Arayüz kodu Faz 3'e kadar CI kapsamında değil. Faz 3'ün ilk işi macOS işini eklemek.
- CI'daki gevşek eşik, bütçeyi iki katına çıkaran bir regresyonu **yakalamaz**. Bunu cihaz
  ölçümü yakalayacak ve o ölçüm elle yapılıyor — yani disipline bağlı bir boşluk. Kabul
  edildi; alternatifi her PR'da macOS runner'ı ve tükenen kota.
- Swift konteyner sürümü sabit (`6.4-noble`). Toolchain yükseltmesi bilinçli bir PR olacak.

## Ek: ilk cihaz ölçümü (29 Ekim 2026)

Bu ADR cihaz ölçümünü elle yapılan, disipline bağlı bir boşluk olarak bırakmıştı. İlk
ölçüm #66'da yapıldı ve sayıları `docs/olcumler/cihaz-olcumu-2026-10-29.md`'de duruyor.

Özeti: soğuk açılış 187 ms (hedef 1,5 s) ama **üretim süresi brief'in 2 saniyelik
ölçütünü dört zorluk hücresinde aşıyor** — Kakuro Hard, Kakuro Expert, Calcudoku Expert,
Slitherlink Expert. Bu ADR'nin öngördüğü şey gerçekleşti: CI'daki gevşek eşik bu
aşımların hiçbirini yakalamadı.

Ölçüm artık tekrar edilebilir: `DeviceMeasurementTests` yalnız gerçek cihazda koşuyor.

## Değerlendirilen alternatifler

- **Her şey macOS runner'da:** cihaza en yakın ortam ve tek iş tanımı. 10x dakika
  maliyeti ve yine iPhone olmaması yüzünden seçilmedi — pahalıya alınan sahte güven.
- **Gerçek bütçeyi CI'da kapı yapmak:** runner gürültüsü yüzünden rastgele kırmızı PR'lar;
  "CI'ı tekrar çalıştır" alışkanlığı CI'ın anlamını yok eder.
- **Performans testlerini CI'dan tamamen çıkarmak:** brief b.11 açıkça her PR'da istiyor
  ve ölçmeyen bir regresyonun fark edilmesi aylar sürer.
- **Self-hosted runner (bağlı bir Mac):** gerçek cihaz ölçümüne en yakını. Tek kişilik
  projede makinenin açık ve bakımlı tutulması gereksiz yük; ileride yeniden düşünülebilir.
