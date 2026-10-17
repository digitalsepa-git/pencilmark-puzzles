# ADR 0004 — Sıfır bağımlılık kuralı ve anlık görüntü testi

- Tarih: 2026-10-17
- Durum: kabul edildi

## Bağlam

Briefte çözülmesi gereken bir çelişki var. B.9 bağımlılık satırında "Yok (SPM dahil)"
diyor; b.11 ise her PR'da anlık görüntü testi istiyor ("grid çizimi, karanlık mod,
Dynamic Type"). Anlık görüntü testi pratikte `swift-snapshot-testing` ile yapılıyor ve o
bir SPM bağımlılığı.

Dürüst olmak gerekirse b.9'un gerekçesi test bağımlılıklarını birebir kapsamıyor: test
hedefi mağazaya gitmiyor, gizlilik etiketini ve ATT iznini etkilemiyor. Kuralın test
tarafında geçerli kalan kısmı başka: `Package.resolved`'a giren her paket bakım ve denetim
yüzeyi, ve toolchain yükseltmelerinde kırılan ilk şey genelde test bağımlılıkları oluyor.

## Karar

**Sıfır bağımlılık kuralı test hedeflerini de kapsar.** Anlık görüntü testi için kendi
harness'ımızı yazıyoruz — Faz 3'te, arayüz geldiğinde:

- SwiftUI görünümü `ImageRenderer` ile PNG'ye alınır (iOS 16+, ek bağımlılık yok).
- Referans görüntüler repoda, `App/Tests/__Snapshots__/` altında.
- Karşılaştırma piksel bazlı, küçük bir tolerans payıyla; fark varsa fark görüntüsü CI
  artifact'i olarak yüklenir.
- Referans üretme açık bir bayrakla yapılır, test koşusu sessizce referans güncellemez.

Tahmini büyüklük 150 satır. CI'daki bağımlılık kapısı (ADR 0003) kuralı zorunlu tutuyor.

## Sonuçları

- Harness'ın bakımı bizde. Karşılaştırma algıya değil piksele dayalı, yani gölge/font
  yuvarlamasındaki ufak farklar yanlış alarm verebilir. Bunu sınırlamak için macOS CI işi
  **sabit bir simülatör runtime'ıyla** koşacak; runtime değişimi bilinçli bir PR olacak.
- Faz 3'ün ilk işlerinden biri bu harness; arayüz testleri ona kadar yok.
- Kural CI'da kapı olduğu için ileride "sadece bu bir paket" diye gevşetilemiyor; gevşetmek
  isteyen önce bu ADR'yi değiştirmek zorunda. İstenen davranış bu.

## Değerlendirilen alternatifler

- **`swift-snapshot-testing`'i test-only bağımlılık olarak eklemek:** olgun, bakımlı,
  algısal karşılaştırma dahil. Brief'in kuralını açık bir istisnayla esnetmek gerekirdi;
  istisna istenirse bu ADR değiştirilerek alınır — kapı o zaman da yerinde kalır.
- **Anlık görüntü testinden vazgeçmek:** b.11 açıkça istiyor ve karanlık mod + Dynamic Type
  kombinasyonları elle gözle kontrol edilemeyecek kadar çok.
- **Yalnızca elle görsel kontrol:** 5 varyant × 4 zorluk × 2 tema × 3 Dynamic Type adımı
  elle sürdürülemez.
