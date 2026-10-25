# ADR 0022 — StoreKit kurulumu ve paywall kapısı

- Tarih: 2026-10-25
- Durum: kabul edildi
- Dayanak: brief b.8 (monetizasyon ve uygulama kuralları), b.5 (V1 çevrimdışı),
  ADR 0021 (yetki dikişi), ADR 0007 (ücretsiz katman)

## Bağlam

ADR 0021 yetkiyi bir dikiş olarak bırakmıştı: katman `PlayLimits`'te duruyor, onu
yazacak olan StoreKit henüz yoktu. Bu ADR o boşluğu dolduruyor ve yol boyunca verilmesi
gereken altı kararı kaydediyor: ürün kimlikleri, yetkinin kaynağı, doğrulamanın nerede
yapıldığı, paywall eşiğinin harfiyen mi yorumlanacağı, gizlilik politikasının nerede
duracağı ve mağazanın nasıl sınanacağı.

## Karar

### 1. Üç ürün, paket kimliğinin altında

`com.pencilmarkgames.puzzles.plus.monthly` / `.yearly` / `.lifetime`. Aylık ve yıllık tek
bir abonelik grubunda (yükseltme/düşürme Apple tarafından yönetilsin diye), ömür boyu
`NonConsumable`.

Kimlikler App Store Connect'te **bire bir** aynı olmak zorunda; yazım hatası mağazadan
boş liste dönmesi demek ve bu hata derlemede görünmüyor. `PlusProductTests` biçimi
sınıyor, `StoreServiceTests` de kimliklerin yapılandırmayla eşleştiğini.

Fiyat kodda yok (brief b.8). Ekrandaki değer `Product.displayPrice`, yani mağazanın
verdiği yerelleştirilmiş fiyat. Mağazaya ulaşılamazsa fiyat **uydurulmuyor**: paywall
"şu an ulaşılamıyor" diyor ve yeniden deneme sunuyor.

### 2. Yetkinin tek kaynağı `StoreService`

Kilitli her şey `PlayLimits`'e bakıyor, `PlayLimits`'in katmanını da yalnız `StoreService`
yazıyor (`onTierChange`). İkinci bir yetki kaynağı, iki yerin farklı cevap verdiği bir
hata sınıfı açardı — ve o hata ödeyen oyuncuyu kilitli ekranda bırakma biçiminde ortaya
çıkardı.

`Transaction.updates` uygulama boyunca dinleniyor ve bilinçli olarak iptal edilmiyor:
satın alma uygulama kapalıyken tamamlanmış olabilir (aile onayı, kesintili ağ).

### 3. Makbuz doğrulaması cihazda, sunucu yok

StoreKit 2 imzayı kendisi doğruluyor; `VerificationResult.verified` olmayan hiçbir işlem
kabul edilmiyor, iade edilmiş (`revocationDate`) ve süresi dolmuş işlemler eleniyor.

Sunucu tarafı doğrulama V1'de yok. Gerekçe b.5 ile aynı: sunucu açmak çevrimdışı olma
kararını ve "veri toplanmıyor" gizlilik etiketini bozuyor. Bedeli, jailbreak'li bir
cihazda yetkinin taklit edilebilmesi; bu kitlede ve bu fiyatta kabul edilebilir.

### 4. Paywall eşiği harfiyen uygulanıyor

Brief b.8: "Paywall, kullanıcı en az 3 bulmaca bitirmeden gösterilmez." Kural
`PaywallPolicy`'de, saf ve sınanabilir. Eşiğin altında satın almaya giden **hiçbir yol
yok**: sınıra çarpınca bilgi ekranı çıkıyor (ADR 0021) ve ayarlardaki yükseltme satırı
bile görünmüyor.

Daha gevşek bir yorum mümkündü — "kendiliğinden gösterilmez ama oyuncu ayarlardan
isterse açabilir". Reddedildi: brief'in cümlesi koşulsuz ve gerekçesi ("erken paywall bu
kategoride silinme sebebi") ürünün en kırılgan noktasına, yoruma dokunuyor. Maliyeti ilk
gün ödemek isteyen oyuncunun üç bulmaca beklemesi.

"Restore purchases" bu kuralın dışında ve her zaman görünüyor: Apple satın alması olan
uygulamalarda zorunlu tutuyor ve geri yükleme bir teklif değil, zaten ödemiş birinin
hakkı.

### 5. Gizlilik politikası uygulamanın içinde

Apple paywall'dan gizlilik politikasına erişilebilmesini istiyor. Normalde bu bir web
adresi olur; bu uygulamanın sunucusu yok ve bir alan adı da henüz yok.

Metin uygulamaya kondu (`PrivacyScreen`). Hem bugün çalışıyor hem de çevrimdışı bir
uygulamaya daha uygun: "hiçbir veri toplanmıyor" diyen bir politikayı okumak için ağ
gerekmemeli. Metin `PrivacyInfo.xcprivacy` ile tutarlı olmak zorunda.

Kullanım koşulları Apple'ın standart EULA'sı. Kendi koşullarımızı yazmadığımız sürece
App Store'un varsayılanı bu ve Apple bu bağlantıyı kabul ediyor.

**Bağlayıcı olan:** App Store Connect ayrıca bir gizlilik politikası **URL**'si istiyor.
O, alan adıyla birlikte Faz 4'ün işi; bu ADR onu uygulama içi metnin yerine geçmiş
saymıyor.

### 6. Paywall yalnız bugün var olan şeyleri sayıyor

Teklif üç madde: sınırsız bulmaca, Hard ve Expert, sınırsız ipucu. ADR 0008'in Plus'a
verdiği istatistik geçmişi **henüz yapılmadı**, bu yüzden yazmıyor. Olmayan bir şeyi
satmak bu kitlede yorumla geri döner; madde, özellik geldiğinde eklenecek.

### 7. Mağaza `.storekit` yapılandırmasıyla sınanıyor

`App/Pencilmark.storekit` üç ürünü tanımlıyor ve şemanın hem test hem çalıştırma
eylemine bağlı. Testler dosyayı `SKTestSession(contentsOf:)` ile doğrudan yoldan açıyor
(anlık görüntü harness'ının `#filePath` kullanmasıyla aynı yaklaşım), yani şemanın
yapılandırmasına bağlı kalmıyorlar ve CI'da da koşuyorlar.

Kapsanmayan tek yol iade: `StoreKitTest`'in `refundTransaction`'ı aynı süreçteki
`Transaction.currentEntitlements` çıktısına yansımıyor. Kod `revocationDate`'i eliyor
(StoreKit'in belgelediği sözleşme) ama bunu doğrulayan bir test yok.

## Sonuçlar

- App Store Connect'te üç ürün bu kimliklerle açılmak zorunda; kimlik değişirse kod da
  değişmeli.
- Paywall'ın görsel doğrulaması simülatörde elle yapılamadı: eşik üç **çözülmüş** bulmaca
  istiyor ve bunu elle oynamak tarif edilebilir bir doğrulama değil. Ekranın mantığı
  testlerle, mağaza yolu `SKTestSession` ile doğrulandı; cihazda görülmesi #66'ya kalıyor.
- Abonelik grubu tek: aylık ve yıllık arasında geçiş Apple tarafından yönetiliyor, kodda
  yükseltme mantığı yok.
- Plus iptal edilince `currentEntitlements` aboneliği düşürüyor ve katman kendiliğinden
  `free`'ye dönüyor; yarım kalan Hard/Expert oyunları kilitli satırın arkasında kalıyor.
  Veri silinmiyor (ADR 0008'in "veri kullanıcının" kararıyla tutarlı).
