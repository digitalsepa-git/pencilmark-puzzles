# App Store Connect gizlilik cevapları

Bu dosya, gönderim sırasında App Store Connect'in soracağı gizlilik sorularına verilecek
cevapları önceden yazıyor. Amaç, gönderim anında doğaçlama cevap verilmemesi: yanlış bir
"evet" gizlilik etiketini kalıcı olarak bozuyor ve düzeltmek yeni bir sürüm gerektiriyor.

Dayanak: brief b.9 (analitik yok, üçüncü parti bağımlılık yok) ve b.12 (gizlilik etiketi
"veri toplanmıyor" olmalı). Teknik karşılığı `App/Sources/PrivacyInfo.xcprivacy`.

## Veri toplama

| Soru | Cevap | Neden |
|---|---|---|
| Uygulamanız veri topluyor mu? | **Hayır** | Sunucu yok, analitik yok, üçüncü parti SDK yok. Üretilen her şey cihazda kalıyor. |
| Üçüncü parti ortaklar veri topluyor mu? | **Hayır** | Üçüncü parti kod yok (ADR 0004: test hedefleri dâhil sıfır bağımlılık). |
| İzleme yapıyor musunuz? | **Hayır** | Reklam yok (brief b.8), kimlik yok, ATT izni sorulmuyor. |

Saklanan veriler ve nerede durdukları:

| Veri | Nerede | Cihazdan çıkıyor mu |
|---|---|---|
| Bitmiş bulmaca kayıtları (tarih, süre, ipucu) | SwiftData, cihazda | Hayır |
| Yarım kalan oyunlar | SwiftData, cihazda | Hayır |
| Tercihler (tema, dokunsal, hata kontrolü, görülen öğreticiler) | `UserDefaults`, cihazda | Hayır |

**iCloud senkronizasyonu yok.** Olsaydı veri Apple sunucularına giderdi ve cevap değişirdi;
V1 tamamen çevrimdışı (brief b.5).

## Required reason API'ler

| API | Kategori | Sebep kodu | Kullanım |
|---|---|---|---|
| `UserDefaults` | `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | Yalnız bu uygulamanın kendi tercihleri |

Dosya zaman damgası, disk alanı, sistem çalışma süresi ve aktif klavye API'leri
kullanılmıyor; beyan edilmiyorlar.

## Yaş sınırı

**4+.** Kullanıcı üretimi içerik yok, dış bağlantı yok (gizlilik politikası ve şartlar
bağlantıları paywall geldiğinde eklenecek ve yaş sınırını değiştirmiyor), reklam yok.

## Satın alma geldiğinde değişecekler

StoreKit eklendiğinde bu dosya yeniden gözden geçirilmeli:

- Satın alma geçmişi Apple tarafından işleniyor; uygulama toplamıyor ama **"Purchases"**
  kategorisinin işaretlenmesi gerekip gerekmediği kontrol edilmeli.
- Gizlilik politikası ve kullanım koşulları için bir web adresi zorunlu (brief b.12) ve
  alan adı henüz yok.
