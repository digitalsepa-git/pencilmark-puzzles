# TestFlight'a build gönderme

Bu belge imzalı bir .ipa üretip App Store Connect'e yüklemenin adımlarını tutuyor.
Komutlar bu Mac'te, bu depoda çalışıyor.

## Bir kerelik kurulum

**Takım.** Projede `DEVELOPMENT_TEAM = 2SH6N4AK3P` sabit. Dağıtım sertifikası takıma ait,
uygulamaya değil — aynı takımdaki başka bir uygulamanın sertifikası bu uygulama için de
geçerli.

**App ID.** Xcode otomatik imzalamayla kendisi kaydetti (`-allowProvisioningUpdates`).
Elle bir şey yapmak gerekmedi; "iOS Team Store Provisioning Profile:
com.pencilmarkgames.puzzles" profili de o sırada üretildi.

**App Store Connect kaydı.** Bu adım tarayıcıdan yapılmak zorunda: App Store Connect API
uygulama kaydı **oluşturmayı desteklemiyor** ve komut satırından yolu yok. Yükleme bu
kayıt olmadan şu hatayla duruyor:

```
App record with bundle identifier "com.pencilmarkgames.puzzles" not found on
App Store Connect. Create an app record on App Store Connect, or distribute the
app from Xcode, and then try again.
```

Kayıt oluşturulurken verilecek bilgiler:

| Alan | Değer | Kaynak |
|---|---|---|
| Platform | iOS | — |
| Ad | Kakuro & Calcudoku Puzzles | brief b.4 |
| Birincil dil | English (U.S.) | brief b.5 |
| Paket kimliği | com.pencilmarkgames.puzzles | proje |
| SKU | pencilmark-puzzles-001 | serbest, mağazada görünmüyor |

## Build üretme

```bash
S=/tmp/pencilmark-dagitim
xcodebuild archive \
  -project App/Pencilmark.xcodeproj \
  -scheme Pencilmark \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$S/Pencilmark.xcarchive" \
  -allowProvisioningUpdates

xcodebuild -exportArchive \
  -archivePath "$S/Pencilmark.xcarchive" \
  -exportPath "$S/export" \
  -exportOptionsPlist docs/magaza/ExportOptions.plist \
  -allowProvisioningUpdates
```

`ExportOptions.plist` içindeki `destination` anahtarı `export` ise .ipa dosyaya yazılıyor,
`upload` ise doğrudan App Store Connect'e gidiyor.

## Sürüm numaraları

`MARKETING_VERSION` kullanıcıya görünen sürüm (1.0.0), `CURRENT_PROJECT_VERSION` build
numarası. App Store Connect aynı sürüm için aynı build numarasını ikinci kez kabul
etmiyor; her yüklemede build numarası artmalı.

## İhracat uyumluluğu

`ITSAppUsesNonExemptEncryption = NO` projede sabit. Uygulamanın hiç ağ kodu yok ve
şifreleme kullanmıyor; bu anahtar olmadan App Store Connect her yüklemede soruyor ve
build işlenmeden bekliyor.

## Dahili test

Dahili testçiler (takımdaki kişiler) için Beta App Review gerekmiyor; build işlendikten
sonra birkaç dakika içinde dağıtılabiliyor. Dış testçiler için inceleme gerekiyor.

## Bu build'de çalışmayan şey

Satın alma. Üç ürün (`com.pencilmarkgames.puzzles.plus.monthly` / `.yearly` /
`.lifetime`) App Store Connect'te açılmadığı sürece paywall "No plans are available
right now." diyor. Oyunun geri kalanı — beş varyant, kota, kilitler, istatistikler —
çalışıyor.
