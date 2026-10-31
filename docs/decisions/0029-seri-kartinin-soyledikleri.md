# ADR 0029 — Seri kartının söyledikleri ve katalogdan kaçan metin

- Tarih: 2026-10-31
- Durum: kabul edildi
- Dayanak: #102, brief b.6, brief b.7 (ekranlar, "rozet ve ses efekti değil"),
  ADR 0008 (istatistik katmanları), ADR 0019 ve ADR 0025 (yerelleştirme),
  ADR 0027, ADR 0028 (satırlar ne verdiğini söylüyor)

## Bağlam

ADR 0027 ve 0028 ana ekranla zorluk ekranında aynı boşluğu kapattı: ekrandaki şey ne
verdiğini söylemiyordu. İstatistik ekranında aynı boşluk sayılarda duruyordu — ve
yanında sessiz bir hata çıktı.

**Seri.** `StatsSummary` seriyi "herhangi bir bulmaca çözülen üst üste günler" diye
tanımlıyor ve bugün oynanmamışsa dün biten diziyi hâlâ güncel sayıyor. İkisi de ekranda
yazmıyordu. Serisini Günün Bulmacası'na bağlı sanan oyuncu sayıyı bozuk görür; bugünün
henüz sayılmadığını ise hiçbir yerden öğrenemezdi.

**Çeviri.** "Current streak" ve "Longest streak" katalogda hiç yoktu. Sebebi tip:
`figure(_:_:)` başlığı `String` alıyordu ve `Text(_ s: StringProtocol)` çeviri yapmıyor.
Xcode da bu dizgileri çıkarmıyor, yani metin hem katalogda yok hem ekranda İngilizce.
Aynı hata ana ekranda "Continue where you left off" cümlesinde de vardı; yarım kalan
oyunu olmayan biri hiç görmediği için fark edilmemişti.

## Karar

### 1. Kart neyin sayıldığını söylüyor

Üç sayının altında tek cümle: bir günü sayan şey **herhangi** bir bulmacayı bitirmek.
Tanım zaten koddaydı, ekranda yoktu.

Seri yaşıyor ve bugün henüz sayılmamışsa ikinci bir satır bunu söylüyor. Bu satır
mürekkep renginde, açıklama ikincil gri: durum ile tanıtımın ayrımı ADR 0027'den beri
aynı.

Satır yalnız bu hâlde çıkıyor. Bugün sayıldığında "bugün sayıldı" yazmak hiçbir şey
eklemezdi; gösterilen tek şey oyuncunun hakkında yapabileceği bir şey olan durum.

**Oyunlaştırma değil.** Brief b.7 "animasyon, rozet ve ses efekti değil" diyor ve kitle
35+. Burada eklenen şey bir dürtü değil bir tanım: sayının ne olduğu ve bugün nerede
durduğu. Seriyi kaybetmekle tehdit eden bir sayaç, geri sayım ya da kutlama yok.

### 2. "Bugün sayıldı mı" kararı `StatsSummary`'de

`isTodayCounted` özetin kendi alanı. Görünümün `lastPlayed`'i bugünle karşılaştırması
aynı kuralı iki yere yazmak olurdu ve kural zaten incelikli: dün biten dizi güncel
sayılıyor, yani "seri yaşıyor" ile "bugün kazanıldı" aynı şey değil. GameCore testi
tam olarak bu ayrımı tutuyor.

### 3. Katalogdan kaçan metin için kapı

Dil bütünlüğü kapısı (ADR 0025) yalnız katalogdaki dizgilere bakıyor; katalogdan hiç
geçmeyen bir metni göremiyor. Yeni test kaynağı tarıyor: yorumlar, çok satırlı
değişmezler, interpolasyonlu metinler ve `comment:` argümanları dışarıda; geriye kalan
her düzyazı dizgisi katalogda olmak zorunda.

Ölçüt kaba — "boşluk içeren, harfle başlayan, yalnız ASCII bir dizgi ekrana çıkar" — ama
bugünkü ağaçta tam olarak üç kaçağı buluyor ve başka hiçbir şeyi işaretlemiyor. Kesin
çözüm kaynak kodu ayrıştırmak olurdu; bağımlılık yok (ADR 0004) ve kazanç bu hatayı
yakalamaktan ibaret.

### 4. İki metin kusuru

- İpucusuz çözüm yokken özet "0 ipucusuz · 1 ipuçlu" diyordu. Sıfırı yazmanın anlamı
  yok; "hepsi ipucuyla çözüldü" cümlesi "hepsi ipucusuz"un simetriği.
- Boş ekranın Türkçesi kipleri karıştırıyordu ("bitir" + "süreleriniz"). İkinci çoğula
  çekildi; uygulamanın geri kalanı da öyle.

## Sonuçları

- `StatsSummary` bir alan büyüdü; `summarise` dışında kuran yok.
- Seri kartı iki satır metin daha taşıyor, kart yükseldi.
- `stats-filled` referansları yenilendi; riskli hâl için ayrı bir referans var.
- Kapı yeni bir `Text(_ s: String)` kaçağını derleme zamanında değil test zamanında
  yakalıyor. Yanlış pozitif verirse ölçütü gevşetmek değil, metni katalogdan geçirmek
  doğru cevap.

## Değerlendirilen alternatifler

- **Seriyi yalnız Günün Bulmacası'na bağlamak.** Daha paylaşılabilir bir sayı ama ADR
  0008'in gerekçesi duruyor: ödüllendirmek istediğimiz alışkanlık uygulamayı açmak.
- **"Bugün sayıldı" satırını her zaman göstermek.** Simetrik ama yarısı gürültü.
- **Seriyi geri sayımla korumak** (kalan saat, uyarı rozeti). Tam olarak brief'in
  istemediği şey.
- **Çeviri kaçağını yalnız düzeltip kapı yazmamak.** Aynı hata iki ekranda bağımsız
  olarak çıktı; üçüncüsü de çıkar.
