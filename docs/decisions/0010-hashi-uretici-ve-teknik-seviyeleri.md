# ADR 0010 — Hashi üretici algoritması ve teknik seviyeleri

- Tarih: 2026-10-17
- Durum: kabul edildi
- Etkiler: ADR 0005'teki seviye → zorluk eşlemesini değiştiriyor

## Bağlam

Brief b.14 varsayılanı: *"önce kaba kuvvet + benzersizlik elemesi, performans yetmezse ADR
ile değiştir"*, ve b.13 Faz 1: *"performans bütçesi burada ölçülür; tutmuyorsa algoritma
kararı ADR olarak burada alınır"*. Bu ADR o ölçümün sonucu.

Ayrıca ADR 0005 teknik seviyesi → zorluk eşlemesini dört seviyeye birebir kurmuştu
(`guessing` → Expert). Ölçüm bunun iki yerde yanlış olduğunu gösterdi.

## Karar

### 1. Üretici çözümü kuruyor, bulmacayı değil

Bir adadan başlayıp köprü çekerek ağı büyütüyor, sonra her adanın derecesini ipucu olarak
yazıyor. Kurulum gereği çıkan üç garanti: **ağ bağlı, köprüler kesişmiyor, dereceler çözümle
tutarlı.** Kalan tek soru benzersizlik ve ona hat karar veriyor.

Tersi — önce ipuçlarını atıp sonra çözüm aramak — adayların çoğunu çözümsüz yapıyor ve
elenme oranını kullanılamaz hale getiriyor.

### 2. Teknik seviyeleri (Hashi'ye özel liste)

| Seviye | Teknik | Ne yapıyor |
|---|---|---|
| `basic` | ada derecesi toplamı | Adanın gereken derecesi komşu kenarların alabileceği en küçük/en büyük toplamla sınırlı; dışarıda kalan değerler eleniyor |
| `basic` | kesişim | Bir kenarda köprü kesinleşmişse kesiştiği kenarlar sıfırlanıyor |
| `intermediate` | olası ağ bağlı mı | Mümkün kenarlarla bile adalar tek ağda olamıyorsa çelişki |
| `intermediate` | tek çıkış | Bir bileşenin dışarıya tek çıkışı kaldıysa o kenarda köprü zorunlu |
| `intermediate` | erken kapanma | Bir kenara köprü koymak birleşen grubu doyurup kapatıyorsa o değer imkânsız |
| `advanced` | tek adım varsayım | Bir kenara değer varsayılıp temel+orta tekniklerle çelişki aranıyor |
| `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor |

Klasik Hashi başlangıç kuralları ayrı ayrı yazılmadı: derecesi komşu sayısının iki katı olan
ada, bir eksiği olan ada, derecesi dolmuş ada, tek komşulu ada — hepsi derece toplamı
kısıtının özel hali. Aynı şekilde "derecesi 1 olan iki ada birbirine bağlanamaz" ve
"derecesi 2 olan iki ada çifte köprüyle bağlanamaz" kuralları erken kapanmanın özel hali.

### 3. `guessing` hiçbir zorlukta kullanıcıya verilmiyor

ADR 0005 `guessing`'i Expert'e eşliyordu. **Değişti: `guessing` eleme sebebi.**

Gerekçe rakip analizinden (`docs/arastirma/rakip-sikayetleri.md`): Slitherlink liderine gelen
şikâyet "iki çözümü var" değil, *zor seviyelerde mantıkla ilerlemenin bitip tahmin
gerekmesi*. Tek çözümü olan bulmaca da mantıkla çözülemeyebilir ve böyle bir bulmaca hiçbir
zorluğa ait değil.

Bu kararın maliyeti ölçüldü: **1.600 adayda `guessing` hiç görülmedi.** Yani Hashi'de
reddetmenin bedeli sıfır. `PuzzleGenerator.rate` buna izin vermek için eklendi (`nil` →
aday eleniyor).

### 4. Hard ile Expert ayrımı varsayım sayısına bağlı

İkisi de ileri teknik gerektiriyor; fark o tekniğin kaç kez gerektiği. **Eşik: 2.** Toplam
çıkarım adımı kullanılmıyor — o büyük ölçüde ızgara boyutunu yansıtıyor, zorluğu değil.

### 5. Yerleşimler ve sabitler

Izgara boyutları ADR 0005'ten; diğerleri ölçümle seçildi.

| Zorluk | Izgara | Ada hedefi | En uzun köprü | Çifte köprü | Ek bağlantı |
|---|---|---|---|---|---|
| Easy | 7×7 | 10 | 4 | %30 | 4 |
| Medium | 9×9 | 13 | 6 | %45 | 6 |
| Hard | 11×11 | 24 | 9 | %45 | 6 |
| Expert | 13×13 | 30 | 6 | %45 | 6 |

- `GenerationPipeline.maxAttempts` = **2500** (hattın varsayılanı 500).
- `HashiSolver.hypothesisBudget` = **48** kenar.

## Ölçüm

Apple Silicon, release derleme. Yerleşim başına 400 aday, hat başına 80 üretim.

| Zorluk | Benzersiz | basic | intermediate | adv×1 | adv≥2 | guessing |
|---|---|---|---|---|---|---|
| Easy | 160/400 | 105 | 35 | 18 | 2 | **0** |
| Medium | 204/400 | 171 | 17 | 13 | 3 | **0** |
| Hard | 161/400 | 125 | 19 | 17 | 0 | **0** |
| Expert | 105/400 | 67 | 21 | 12 | 5 | **0** |

| Zorluk | Deneme ort. | Deneme en kötü | Süre ortanca | Süre en kötü |
|---|---|---|---|---|
| Easy | 3 | 12 | 0,05 ms | 0,33 ms |
| Medium | 27 | 110 | 0,60 ms | 3,05 ms |
| Hard | 34 | 196 | 1,33 ms | 9,92 ms |
| Expert | 74 | 453 | 4,11 ms | **30,65 ms** |

Brief b.11'in bütçesi Expert'te 2.000 ms. Ölçülen en kötü 30,65 ms — **65 kat pay.** Debug
derlemede en kötü 569 ms, hâlâ bütçenin altında.

## Sonuçları

- **Kaba kuvvet + eleme kalıyor.** Brief'in öngördüğü yedek çözümler (algoritmayı değiştirmek
  ya da arka planda önceden üretip kuyrukta tutmak) gerekmedi. Kuyruk, 30 ms'lik bir iş için
  taşıdığı karmaşıklığı hak etmiyor; yine de üretim arayüzü kilitlememeli (b.11) çünkü asıl
  risk tek bulmacanın süresi değil, ekranın hiç yanıt vermemesi.
- **Deneme sınırı payla alındı.** Expert'te en kötü 453 deneme ölçüldü; hattın varsayılanı
  500 olsaydı varyansın kenarında çalışıyor olurduk. 2500 denemenin maliyeti yarım saniyenin
  altında, yani payı almanın bedeli yok.
- **Hard ve Expert ince aralıkta üretiliyor** (%4 ve %1,25 kabul oranı). Yerleşim
  parametreleri değişirse bu ADR'deki ölçüm tekrarlanmalı; `HashiPropertyTests` en kötü
  deneme sayısını 1500'ün altında tutmayı test ediyor ve bozulma orada görünür.
- **Ada sayısı hedefin altına düşebiliyor** (Hard'da 18-24 arası). Yerleşim sıkıştığında
  büyüme duruyor; bulmaca yine geçerli, yalnız daha küçük.
- **`extraLinkAttempts` ölçümde neredeyse etkisiz.** Büyüme sonrası tahtada boş yol kalmadığı
  için ek bağlantı denemelerinin çoğu başarısız; 6'dan 30'a çıkarmak dağılımı değiştirmiyor.
  Parametre küçük bir değerde tutuldu, büyütmenin anlamı yok.
- **Zorluk ölçeği artık iki eksenli:** teknik seviyesi + varsayım sayısı. Brief b.6'nın
  "zorluk teknik seviyesiyle belirlenir" kuralı korunuyor; ikinci eksen seviye *içinde*
  ayrım yapıyor, seviyenin yerine geçmiyor.

## Değerlendirilen alternatifler

- **İpucu-önce üretim** (ada derecelerini atıp çözüm aramak): adayların çoğu çözümsüz çıkıyor,
  elenme oranı kullanılamaz.
- **Arka planda önceden üretip kuyrukta tutmak** (brief b.11'in önerdiği yedek): 30 ms'lik
  iş için gereksiz karmaşıklık; kuyruk tükenirse yeni bir hata sınıfı doğuyor.
- **Hard/Expert ayrımını toplam adım sayısına bağlamak:** ölçümde adım sayısı ızgara
  boyutuyla birlikte artıyor, zorlukla değil. 13×13 bir Easy bulmaca 11×11 bir Hard'dan çok
  adım alabiliyor.
- **`guessing`'i Expert olarak sunmak** (ADR 0005'in ilk hali): rakip analizindeki en can
  alıcı şikâyet buydu; üstelik Hashi'de hiç üretilmediği için bedelsiz vazgeçildi.
- **Benzersizliği üreticiye bırakmak** (kurulum gereği benzersiz olduğunu varsaymak): ölçüm
  tam tersini gösteriyor — adayların %49 ile %74'ü çok çözümlü. Kurulum benzersizlik
  garantisi vermiyor, eleme şart.
