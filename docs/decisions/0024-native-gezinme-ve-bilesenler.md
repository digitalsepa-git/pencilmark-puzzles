# ADR 0024 — Native gezinme ve bileşenler

- Tarih: 2026-10-29
- Durum: kabul edildi
- Dayanak: #86, brief b.7 (ekranlar ve tasarım yönü), ADR 0002 (asgari iOS 17),
  ADR 0015 (Dynamic Type), ADR 0019 (yerelleştirme)

## Bağlam

Uygulamanın gezinmesi tek bir `NavigationStack`'ti. Ayarlar ve İstatistik ana ekranın
üst araç çubuğunda ikon olarak duruyordu: ikisi de bir ekranın aracı değil, uygulamanın
ayrı bölümü. Ana ekran ve zorluk ekranı da `List` yerine elle çizilmiş kartlardan
oluşuyordu — zemin, kenar, köşe yarıçapı, ayırıcı ve disclosure göstergesi hep elle
kuruluyordu. Bunların karşılığı yalnız fazladan kod değil: basılı hâl, sürükleyerek
geri gitme ve VoiceOver satır davranışı da taklit edilmek zorunda kalıyordu ve hiçbiri
sistemin güncellemeleriyle birlikte ilerlemiyordu.

## Karar

**Gezinme ve bileşen desenleri Apple'ın kendi kütüphanesinden alınıyor.**

1. Kök görünüm `TabView`, üç sekme: Puzzles, Statistics, Settings. `NavigationStack`
   her sekmenin **içinde**, yani sekme değiştirmek yığını bozmuyor.
2. Ana ekran ve zorluk ekranı `List` (`.insetGrouped`) satırlarına geçti. Gösterge,
   ayırıcı, basılı hâl ve satır erişilebilirliği sistemden geliyor.
3. Bulmaca ekranında sekme çubuğu `.toolbar(.hidden, for: .tabBar)` ile gizleniyor:
   oyun alanı tam ekran kalıyor ve oyun sırasında gidilecek bir yer yok.
4. Boş istatistik durumu `ContentUnavailableView`.
5. Araç çubuğu düğmelerinin üzerindeki elle verilmiş renkler kalktı; vurgu rengi
   sistemin.
6. Sekme simgeleri çizgi varyantında ve `light` ağırlıkta. Sekme çubuğu varsayılan
   olarak dolu varyantı uyguluyor; iOS 26'nın cam çubuğunda dolu simgeler ağır duruyor,
   çünkü cam zaten bir katman. Ağırlık `.fontWeight` ile verilemiyor — çubuk simgeyi
   kendi yapılandırmasıyla yeniden çiziyor — o yüzden simge istenen ağırlıkta üretilip
   veriliyor; şablon kipi korunduğu için seçili sekmenin vurgu rengi yine sistemin.
   `ultraLight` denendi ve bırakıldı: küçük ekranda ve koyu temada zayıflıyor, brief b.7
   yüksek kontrast istiyor. Simgeler: ızgara, çubuk grafik, sürgü (ayarlar için dişliden
   daha ince bir silüet).

**Renk paleti değişmiyor.** Kâğıt hissi brief b.7'nin tasarım yönü ve `Theme.swift`
olduğu gibi duruyor; liste ve form zeminleri `.scrollContentBackground(.hidden)` ile
hâlâ kâğıda boyanıyor. Karar desenlerle ilgili, temayla değil.

## Sonuçları

- Ayarlar ve İstatistik ana ekranın araç çubuğundan çıktı; iki ekran da artık sekme
  kökü ve native büyük başlık kullanıyor.
- `VariantCard` ve `DailyCard` yerlerini `VariantRow` ve `DailyRow`'a bıraktı. Anlık
  görüntü referansları yeniden üretildi (ADR 0016'nın yolu).
- Sekme çubuğu bir ekran daha dikey alan yiyor; bu yüzden bulmaca ekranında gizleniyor.
  Gizlemeyi unutan bir ekran ızgarayı küçültür — `PuzzleScaffold` tek yerde yapıyor.
- Liquid Glass ayrı bir iş değil: iOS 26 SDK'sıyla derlenen standart `TabView` cam
  çubuğu kendiliğinden alıyor, iOS 17–18'de ise klasik çubuk çiziliyor. İkisi de aynı
  koddan geliyor; uygulamanın yapması gereken tek şey kendi çubuğunu çizmemek.
- Dokunma hedefi asgarisi (60 pt, brief b.7) satır içeriğinde `minHeight` olarak
  duruyor: `List` satırı yüksekliğini içeriğinden alıyor.

## Değerlendirilen alternatifler

- **Araç çubuğu ikonlarını korumak.** Üç bölümü tek ekranın köşelerine sıkıştırıyor ve
  iOS'ta bölüm gezinmesinin yeri orası değil. Yeni bir bölüm eklendiğinde de yer yok.
- **Dört sekme (Daily ayrı sekme).** Günün bulmacası tek bir satır; ona bir sekme
  ayırmak kökünde yalnız bir düğme olan bir bölüm demek. Brief b.7 zaten onu ana
  ekranın ilk satırına koyuyor.
- **Kartları `List` içinde korumak.** Görünüm aynı kalırdı ama taklit edilen davranışlar
  da kalırdı; kararın amacı tam olarak onları sisteme bırakmak.
