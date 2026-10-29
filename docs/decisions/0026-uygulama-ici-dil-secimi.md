# ADR 0026 — Uygulama içinden dil seçimi

- Tarih: 2026-10-29
- Durum: kabul edildi
- Dayanak: #92, ADR 0019 (yerelleştirme kapsamı), ADR 0025 (çok dillilik altyapısı),
  ADR 0015 (modül sınırları)

## Bağlam

iOS'un kendi yolu var: Ayarlar → Apps → uygulama → Language. Ürün kararı bunun yetmediği
yönünde — kullanıcı dili **uygulamanın içinden** de değiştirebilmeli, uygulama yine
cihazın dilinde açılmaya devam ederken.

Önce ölçüldü. Kökte `.environment(\.locale, Locale(identifier: "tr"))`, cihaz dili
İngilizceyken:

| | Sonuç |
|---|---|
| SwiftUI metin değişmezleri (`Text("Settings")`) | Türkçe |
| `String(localized:)` ile kurulan metinler | İngilizce kaldı |
| Tarih (`ShareCard.longDate`) | İngilizce kaldı |

Sebep: kodda kurulan bir metin hangi `.lproj`'dan okunacağını **pakete** soruyor, ortam
`locale`'ine değil. Ortam yalnız biçimlendirmeyi ve değişmezlerin çözümünü etkiliyor.
120 çağrı yeri bu durumdaydı.

## Karar

### 1. Seçili dilin paketi tek bir yerden okunuyor

`AppLanguage` seçimi (`sistem` ya da bir dil kodu) çözüp paketini ve `locale`'ini
veriyor. Diller kodda sabit değil, `Bundle.main.localizations`'tan türüyor: üçüncü bir
dil eklemek yalnız çeviri işi.

Durum bir kilidin arkasında, MainActor'a bağlı değil: metinler görünüm katmanının
dışından da okunuyor (erişilebilirlik etiketleri, mağaza hataları).

### 2. Kodda kurulan metinler `localized(_:)` üzerinden

`String(localized:)` doğrudan çağrılırsa uygulamanın paketinden okur ve o satır seçilen
dili görmez. Sarmalayıcı seçili paketi ve `locale`'i geçiriyor.

Değişmez sarmalayıcıya düz geçtiği için `-exportLocalizations` dizgiyi görmeye devam
ediyor — ölçüldü: sarmalayıcıdan geçen yeni bir dizgi katalogda belirdi. ADR 0019'un
"her metin çıkarmaya görünür" garantisi korunuyor.

`String(localized:` doğrudan çağrısını yakalayan bir test var; sessiz kalacak tek hata
buydu.

### 3. Kök görünümün kimliği dile bağlı

Ortam `locale`'i değişince SwiftUI metin **değişmezlerini** yeniden çözüyor ama gövdeyi
yeniden çalıştırmıyor. `localized()` ile kurulan dizgiler gövdede hesaplandığı için eski
dilde kalıyordu — ekranın yarısı çeviriyor, yarısı çevirmiyordu.

`.id(preferences.language)` ağacı baştan kuruyor. Bedeli gezinme yığınının köke dönmesi;
dil değişimi nadir ve yarım kalan oyun zaten kayıtlı (ADR 0018).

### 4. Seçimi uygulayan yer uygulama katmanı

`Preferences` yalnız saklıyor. Uygulama `AppLanguage.apply`'ı başlangıçta (ilk gövdeden
önce) ve seçim değiştiğinde çağırıyor.

İlk tasarımda uygulamayı `Preferences` yapıyordu ve testler bunu kırdı: bir `Preferences`
kurmak süreç genelinde dili değiştiriyordu, paralel koşan testler birbirinin metnini
bozacaktı.

## Sonuçları

- Uygulama cihazın dilinde açılıyor; seçim yapılırsa o dilde ve seçim kalıcı.
- Dil değişimi **yeniden başlatma istemiyor**; arayüz anında değişiyor, tarih dahil.
- Kayıtlı dil pakette yoksa sisteme düşülüyor.
- Yeni bir `String(localized:)` çağrısı eklemek testi kırıyor; doğru yol `localized(_:)`.
- Dil değiştirince gezinme yığını köke dönüyor.

## Değerlendirilen alternatifler

- **Yalnız iOS Ayarlar'ına yönlendirmek.** Apple'ın yolu ve sıfır kod. Ürün kararı aksi
  yönde; ayrıca kullanıcıyı uygulamadan çıkarıyor.
- **`AppleLanguages`'i `UserDefaults`'a yazmak.** İki satır, ama ancak **yeniden
  başlatınca** etkili oluyor ve kullanıcıya "uygulamayı kapatıp açın" demek gerekiyordu.
- **`Bundle.main`'in sınıfını değiştirmek** (`object_setClass`). Çağrı yerlerine hiç
  dokunmadan her şeyi çözüyor, yaygın bir yöntem. Foundation sınıfına çalışma anında
  müdahale; bu repoda açıklığı sihre tercih ediyoruz ve sarmalayıcı bir testle
  korunabiliyor.
- **Her görünüme `@Environment(\.locale)` koymak** (kök kimliği yerine). Daha ucuz ama
  unutulabilir: eklenmeyen bir görünüm sessizce eski dilde kalırdı.
