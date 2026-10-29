# Cihazda ölçüm — 29 Ekim 2026

ADR 0003'ün eki (#66). ADR 0003 cihaz ölçümünü "PR şablonundaki 'cihazda denendi'
satırıyla raporlanıyor" diye bırakmıştı ve bugüne kadar hiçbir şey cihazda denenmemişti.
Bu belge ilk ölçümün sayılarını tutuyor.

## Ortam

| | |
|---|---|
| Cihaz | iPhone 14 Pro Max (iPhone15,3) |
| iOS | 26.7.1 (23H30) |
| Derleme | Debug, cihaza kurulu |
| Sürüm | 1.0.0 (1) |
| Yöntem | `DeviceMeasurementTests`, zorluk başına 3 üretim, farklı tohumlarla |

Ölçüm **Debug** derlemesinde yapıldı; test hedefi başka türlü cihaza kurulamıyor. Release
derlemesi daha hızlı olacak, yani aşağıdaki sayılar bir **üst sınır**. Ne kadar hızlanacağı
ölçülmedi.

> **Güncelleme (aynı gün):** Slitherlink sayıları `uretim-darbogazi-2026-10-29.md`
> bölüm 5'teki iyileştirmeden **önceki** hâli. Güncel ölçüm orada.

## Üretim süresi

Ortanca · en kötü, milisaniye:

| Varyant | Easy | Medium | Hard | Expert |
|---|---|---|---|---|
| Kakuro | 110 · 255 | 540 · **1584** | **2222 · 2284** | **1208 · 4322** |
| Calcudoku | 1 · 1 | 2 · 5 | 135 · 325 | **999 · 3681** |
| Slitherlink | 44 · 66 | 741 · **1488** | **1199 · 1911** | **3644 · 4021** |
| Hashi | 1 · 1 | 15 · 20 | 24 · 144 | 458 · 513 |
| Hitori | 19 · 24 | 5 · 9 | 109 · 153 | 172 · 220 |

Koyu yazılanlar ADR 0003'ün 1 saniyelik hedefini aşıyor.

### Brief'in kabul ölçütü karşılanmıyor

Brief b.5: "Üretim süresi en zor seviyede bile cihazda 2 saniyenin altında." Dört hücre
bunu aşıyor:

- Kakuro Hard — 2222 ms ortanca
- Kakuro Expert — 4322 ms en kötü
- Calcudoku Expert — 3681 ms en kötü
- Slitherlink Expert — 3644 ms ortanca, 4021 ms en kötü

ADR 0003'ün daha sıkı olan 1 saniyelik hedefini yedi hücre aşıyor.

### Düzeltme: "Kakuro Hard, Expert'ten yavaş" yanlıştı

İlk okumada Kakuro Hard'ın ortancası (2222 ms) Expert'inkinin (1208 ms) iki katı
görünüyordu ve bu, zorluk bandının yan etkisi diye not edilmişti. **Yanlıştı.**

Zorluk başına üç örnek, Expert'in dağılımını tarif etmeye yetmiyor. On örnekle
tekrarlanınca sıralama tersine döndü (Mac, Debug):

| Kakuro | ortalama tur | ortalama süre | tur başına |
|---|---|---|---|
| Medium | 5,0 | 1406 ms | 281 ms |
| Hard | 5,9 | 2091 ms | 354 ms |
| Expert | 2,6 | 3967 ms | **1526 ms** |

Expert en pahalısı; cihazdaki ölçümde şansı yaver gitmiş. İki zorluğun yavaşlığı da
**farklı sebepten**: Hard çok tur dönüyor (5,9) ama turu ucuz, Expert az tur dönüyor
(2,6) ama turu 1,5 saniye.

Bu bölüm, az örnekle ölçüp sebep uydurmanın nasıl göründüğünün kaydı olarak duruyor.

## Soğuk açılış

Instruments "App Launch" şablonu, `xctrace` ile cihazda kaydedildi:

| Aşama | Süre |
|---|---|
| System Interface Initialization | 57,68 ms |
| Static Runtime Initialization | 4,53 ms |
| UIKit Initialization | 10,21 ms |
| UIKit Scene Creation | 3,45 ms |
| `didFinishLaunchingWithOptions()` | 0,08 ms |
| `sceneWillConnectTo()` | 8,13 ms |
| `sceneWillEnterForeground()` | 0,04 ms |
| Initial Frame Rendering | 79,29 ms |
| **Toplam (ilk kareye kadar)** | **187 ms** |

Brief'in hedefi 1,5 saniye; ölçülen onun sekizde biri. Açılışta bulmaca üretilmiyor —
üretim yalnız oyuncu bir zorluk seçtiğinde başlıyor — ve açılış süresinin bu kadar düşük
olmasının sebebi bu.

## Dokunma hedefleri

iPhone 14 Pro Max 430×932 pt. Izgaraya kalan genişlik 390 pt (iki yanda 20 pt kenar
boşluğu). Hesaplanan hücre ölçüleri:

| Izgara | Hücre (1 kat) | 3 katta |
|---|---|---|
| Kakuro Expert 11×11 | 35,5 pt | 106 pt |
| Slitherlink Expert 12×12 | 32,5 pt (kenar payı 10,7 pt) | 97 pt (32 pt) |
| Hashi Expert 13×13 | 30 pt (kenar payı 12 pt) | 90 pt (36 pt) |

Apple'ın en küçük dokunma hedefi 44×44 pt. **Üç Expert ızgarası da 1 katta bunun
altında** — zaten #65'in yakınlaştırmayı getirme sebebi buydu ve ölçüm o kararı
doğruluyor. 3 katta hepsi eşiğin üstüne çıkıyor.

Okunaklılığın öznel değerlendirmesi burada yok: ekrana bakan bir insanın işi ve bu
belgeye sayı yazılabilecek bir tarafı yok.

## Sonuç

- Soğuk açılış ve dokunma hedefleri (yakınlaştırmayla) karşılanıyor.
- **Üretim süresi karşılanmıyor.** Dört zorluk hücresi brief'in 2 saniyelik ölçütünün
  üstünde. Bu, yayından önce kapatılması gereken bir açık.
- ADR README'nin "beklenen kararlar" listesindeki "Kakuro ve Slitherlink Expert'in arka
  planda önceden üretilmesi — cihaz ölçümüyle birlikte" satırı artık ölçüye dayanıyor:
  önceden üretim yalnız Expert'i değil Kakuro Hard'ı ve Calcudoku Expert'i de kapsamalı.
