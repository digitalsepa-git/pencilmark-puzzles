# ADR 0025 — Çok dillilik altyapısı

- Tarih: 2026-10-29
- Durum: kabul edildi
- Dayanak: #88, ADR 0019 (yerelleştirme kapsamı ve bıraktığı borç), ADR 0015 (modül
  sınırları), ADR 0009 (etkileşimli öğretici)

## Bağlam

ADR 0019 "altyapı hazır" dedi ve hazır olmayan iki yeri de yazdı:

1. **Öğretici prozası `GameCore`'da.** `TutorialStep.text` ve `.correction` düz `String`;
   22 cümle çıkarmaya görünmüyor ve çevrilemiyor. ADR 0019 §3 bunu bilinçli borç olarak
   kaydetti ve ödeme zamanını "ikinci dil eklendiğinde" diye koydu.
2. **Eksik çeviriyi yakalayan kapı yok.** Katalogda bir dizginin çevirisi eksikse
   uygulama sessizce kaynak dile düşüyor. Tek dilliyken görünmez; ikinci dille birlikte
   yarım çeviri gönderilebilir hâle geliyor.

Buna bir üçüncüsü eklendi: `knownRegions` yalnız `en` ve `Base` tanıyordu, yani katalogda
duran bir çeviri pakete hiç girmezdi.

## Karar

### 1. `GameCore` durum bildiriyor, cümleyi uygulama seçiyor

`TutorialStep` artık yalnız `isComplete` taşıyor. `TutorialRun.correction: String?`
yerine `isCorrecting: Bool` var: yanlış hamlenin **olduğu** bulmaca bilgisi, o hamleye
ne denileceği dil bilgisi.

Cümleler `App/Sources/Tutorial/TutorialCopy.swift` içinde `String(localized:)`
değişmezleri olarak duruyor. Senaryonun yapısı — ızgara, adım sırası, adımın ne zaman
bittiği — `GameCore`'da kaldı, yani ADR 0015'in Linux'ta 1x test maliyeti korunuyor ve
senaryoların benzersizliğini çözücüyle doğrulayan testler yerinde duruyor.

Anahtar (`"tutorial.kakuro.1"` gibi) üretilmedi: üretilmiş anahtar çıkarmaya görünmüyor
ve katalogu elle doldurmayı gerektirirdi, ADR 0019 bunu yasaklıyor. Cümlenin kendisi
anahtar olunca `-exportLocalizations` hepsini görüyor — 181 dizgi 209'a çıktı.

### 2. Dil bütünlüğü bir test kapısı

`LanguageCompletenessTests` katalogu **kaynak ağacından** okuyor ve katalogda geçen her
dil için her dizginin durumunun `translated` olmasını şart koşuyor. Beklenen dil listesi
elle yazılmıyor, katalogda geçen dillerden türüyor: yeni dil kendiliğinden kapsama
giriyor, unutulacak bir liste yok.

İkinci test katalogdaki dillerin `knownRegions` içinde de olmasını kontrol ediyor; ikisi
ayrışırsa çeviri katalogda durur ama pakete girmez.

Üçüncüsü öğreticinin her adımının bir cümlesi olduğunu kontrol ediyor: anlatım artık
senaryodan ayrı bir dosyada ve derleyici ikisinin ayrıştığını yakalamıyor.

### 3. `knownRegions` ikinci dili tanıyor

Projeye `tr` eklendi. Çevirinin kendisi ayrı iş (#89).

## Sonuçları

- `GameCore` kaynaklarında kullanıcıya görünen İngilizce cümle kalmadı.
- Öğretici davranışı değişmedi; `TutorialScenarioTests` cümle yerine durumu sınıyor.
- Yeni bir dil eklemek: katalogda değer yazmak, `knownRegions`'a eklemek, testi koşmak.
- `TutorialCopy.swift` içinde `line_length` kapalı. Çeviri değişmezi tek parça olmak
  zorunda — `String(localized:)` birleştirilmiş ifadeyi kabul etmiyor ve çıkarma yalnız
  değişmezi görüyor — yani satır bölünemiyor.

## Değerlendirilen alternatifler

- **`GameCore`'u yerelleştirmek.** `Bundle.module` ve Foundation'ın yerelleştirme
  kaynakları demek; ADR 0015'in Linux'ta ucuz test kararını riske atıyordu. ADR 0019 bunu
  zaten bir kez reddetmişti, gerekçe değişmedi.
- **Anahtar tabanlı öğretici metinleri.** `GameCore` anahtar taşır, uygulama çözerdi.
  Çıkarma anahtarları görmediği için katalog elle doldurulurdu ve bir anahtarın
  karşılığının unutulması ancak ekranda fark edilirdi.
- **Beklenen dilleri teste elle yazmak.** Daha açık ama bakımı insanın hafızasına bağlı;
  katalogdan türetmek aynı korumayı bedava veriyor.
