# ADR 0002 — Minimum iOS sürümü 17.0

- Tarih: 2026-10-17
- Durum: kabul edildi, [ADR 0015](0015-xcode-projesi-modul-sinirlari-ve-macos-ci.md) ile not düşüldü

## Bağlam

Brief b.14 varsayılanı 17.0 ve gerekçesi 16'ya inmenin SwiftData'yı dışlaması. Karar
onaylandı, ama sorulması gereken ters soru vardı: Ekim 2026'da iOS 26 güncel sürüm ve
18.0'a çıkmak daha yeni SwiftData/SwiftUI API'lerini açıyor.

Kitle yetişkin, çoğunlukla 35 yaş üstü (b.7). Bu kitlede eski cihaz oranı genç kitleye göre
yüksek; iOS 17 iPhone XR/XS ve sonrasında çalışıyor, yani 2018 cihazları hâlâ kapsamda.
Sıfır reklam bütçesiyle çalışan bir üründe erişilebilir cihaz havuzunu daraltmanın bedeli
doğrudan indirmeye yansır.

## Karar

**iOS 17.0.**

Pratik sonucu: iOS 18+ API'leri kullanılamaz. SwiftData'nın 18'de gelen özellikleri
(`#Index`, gelişmiş geçiş API'leri), `@Entry`, yeni Observation kolaylıkları kapsam dışı.
Kullanılması gerekirse `@available` ile koşullu, 17 yolu da yazılmış olarak.

## Sonuçları

- Bu makinede iOS 17 simülatör runtime'ı yüklü değil (18.2, 26.2, 26.5 var). Faz 3'ten önce
  indirilecek (~7 GB); minimum sürümde test edilmeyen bir minimum sürüm iddiası değersiz.
- Xcode 27 SDK'sı minimum 15.0'ı destekliyor, yani toolchain tarafında engel yok.
- SwiftData'nın 17'deki hali 18'dekinden daha dar; şema geçişleri elle yazılacak. Saklama
  katmanı küçük (bulmaca durumu + istatistik), bu yüzden maliyeti sınırlı.
- V2'de minimum sürüm yükseltmek her zaman kolay; indirmeye başladıktan sonra düşürmek
  mümkün değil. Sıra bu yönde olmalı.

## Değerlendirilen alternatifler

- **iOS 18.0:** daha yeni API'ler ve daha az `@available` dalı. 35 yaş üstü kitlede eski
  cihaz oranı yüksek olduğu için, kazanılan geliştirme kolaylığı kaybedilen erişimden
  küçük. Reklam bütçesi sıfırken erişim en pahalı kaynak.
- **iOS 16.0:** SwiftData'yı dışlıyor, saklama katmanı Core Data'ya veya elle yazılmış bir
  çözüme dönüyor. Kazanılan cihaz havuzu (2017 cihazları) bu maliyeti karşılamıyor.

> **ADR 0015 notu (2026-10-24).** Elimizdeki Xcode 27.1 ile kurulabilen en eski iOS
> simülatör çalışma zamanı 18.2; iOS 17'de hiçbir şey çalıştırılamıyor. Minimum 17.0
> olarak kalıyor — derleyicinin availability kontrolü 18+ API kullanımını derleme hatasına
> çeviriyor, yani sessiz kaçış yok. Kalan risk davranış farkları ve o yalnız gerçek cihazda
> görülüyor: Faz 4'teki TestFlight dış testi bu boşluğun kapandığı yer.
