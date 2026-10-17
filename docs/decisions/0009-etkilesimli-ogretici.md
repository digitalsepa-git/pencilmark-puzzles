# ADR 0009 — Etkileşimli öğretici

- Tarih: 2026-10-17
- Durum: kabul edildi
- Not: **V1 kapsamına ektir.** Brief b.5'teki V1 listesinde öğretici yok; b.3 Calcudoku
  farkı olarak "düzgün öğretici" diyor. Karar öğreticinin V1'e girmesi yönünde alındı.

## Bağlam

Beş bulmacanın hiçbiri Sudoku kadar bilinmiyor. B.2'deki talep verisinin bilinen yanlılığı
tam olarak bunu söylüyor: insanlar **bilmedikleri** bulmacanın kurallarına bakıyor. Yani
mağazadan gelen kullanıcının önemli bir kısmı kuralları bilmiyor ve ilk 60 saniyede
öğrenemezse siliyor.

Statik bir kurallar sayfası bu işi görmüyor. "Karalı hücreler komşu olamaz" cümlesi
Hitori'yi hiç görmemiş birine bir şey anlatmıyor; aynı kural tek bir hamlede gösterilince
anlaşılıyor.

## Karar

**Her varyant için etkileşimli öğretici.** Varyant başına 4-6 adım, her adımda kullanıcı
gerçekten hamle yapıyor:

- **Elle hazırlanmış küçük ızgaralar**, üretilmiş değil. Öğretici belirli bir tekniği
  belirli bir sırada göstermek zorunda; üretilmiş bulmaca bunu garanti etmez.
- Adım anlatımı tek cümle, ızgaranın üstünde; doğru hamle yapılınca sonraki adım.
- Yanlış hamle engellenmiyor, nazikçe düzeltiliyor — kuralı ihlal eden hamle kullanıcıya
  kuralı öğretiyor.
- İlk kez bir varyant açıldığında kendiliğinden başlıyor, atlanabiliyor.
- Varyant kartından ve ayarlardan her zaman yeniden oynanabiliyor.

## Sonuçları

- **Bu, brief'in V1 kapsamına en büyük tek ekleme ve gönderim yolunun üzerinde.** Beş
  öğretici = beş elle hazırlanmış senaryo + adım motoru. Faz 3'ün içinde ayrı bir iş kalemi
  olarak izlenecek; takvim kayarsa kapsam değil takvim esneyecek (b.13).
- Öğretici içeriği bulmaca motorunu kullanıyor ama hattı kullanmıyor: elle hazırlanmış
  ızgara `GeneratedPuzzle` değil. Kural doğrulayıcı ve tahta modeli ortak, üretici devrede
  değil. Bu ayrımın kodda net durması gerekiyor.
- Guideline 4.3(b) tarafında işe yarıyor: "beş bulmaca tek uygulamada" iddiasının ilk ekran
  görüntüsünde okunması isteniyor (b.12) ve beş öğretici bunun somut kanıtı.
- Elle hazırlanmış ızgaraların da benzersiz çözümü olmalı; öğretici ızgaraları için ayrı bir
  test, çözücüyle doğrulama yapacak.

## Değerlendirilen alternatifler

- **Statik kurallar sayfası:** ucuz, hızlı, bu kitle için yetersiz. Kuralı okuyup anlamak
  bulmacayı görmeyi gerektiriyor.
- **Öğreticiyi V2'ye bırakmak:** gönderimi hızlandırırdı. Reddedildi çünkü ilk üç ayın
  yorumları sıralamadaki tek varlığımız (b.5) ve "kuralları anlamadım" yorumu doğrudan
  sıralamaya zarar veriyor.
- **Yalnızca Calcudoku'ya öğretici:** b.3 öğreticiyi Calcudoku farkı olarak sayıyor. Ama
  Hashi ve Slitherlink daha az biliniyor; yalnız Calcudoku'ya yapmak yanlış yere yatırım.
