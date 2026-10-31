# ADR 0027 — Ana ekran önizlemeleri

- Tarih: 2026-10-31
- Durum: kabul edildi
- Dayanak: #94, brief b.7 (ekranlar ve tasarım yönü), ADR 0006 (günlük bulmaca),
  ADR 0007 (ücretsiz katman), ADR 0009 (öğretici senaryoları), ADR 0024 (native desenler),
  #78 (üretim süresi)

## Bağlam

Ana ekran iki farklı şeyi aynı biçimde gösteriyordu ve ikisini de açıklamıyordu:

- **Günün Bulmacası** tarihten türeyen sabit tohumla üretiliyor; her gün değişiyor,
  herkeste aynı, ücretsiz ve günlük kotadan sayılmıyor.
- **Beş varyant satırı** bulmaca değil kapı: oyun başlatıldığında rastgele tohumla her
  seferinde yeni bir bulmaca üretiliyor.

Oyuncunun ekrandan bunların hiçbirini öğrenmesi mümkün değildi. "Bu bulmacalar her gün
mü yenileniyor, sabit mi?" sorusu ürün sahibinden geldi — ekran o soruyu yanıtlamıyorsa
tasarım eksik.

Bir de şu var: beş ad (Kakuro, Hitori, Slitherlink…) bu kitlenin çoğuna bir şey
söylemiyor. En kısa anlatım ızgaranın kendisi.

## Karar

### 1. Satırlar ne verdiklerini söylüyor

Günün satırında tek cümle: her gün yeni, herkeste aynı, her zaman ücretsiz. Varyant
bölümünün altbilgisinde tek cümle: her oyun, başlatıldığı anda üretilen yeni bir bulmaca.

Cümle satır başına değil **bölüm başına**: aynı şeyi beş kez okutmak gürültü.

**Düzeltme (#96).** Varyant cümlesi önce bölümün altbilgisindeydi; ürün sahibi ekranı
kullanırken onu hiç görmedi. Yeri yanlıştı: beş satırın arkasında, ikincil gri renkte,
ekranda en son bakılan noktada. Cümle **bölüm başlığına** taşındı — listeye girmeden
okunuyor, mürekkep renginde ve yanında bir simge var. Ses yükseltilmedi; hâlâ tek,
sessiz bir cümle. Günün satırındaki açıklama yerinde kaldı: o zaten kartın içinde.

### 2. Mini ızgara, öğretici senaryolarından

Her satırın sağında 56 pt'lik gerçek ızgara, oyunun kendi çizim koduyla. Kaynak ADR
0009'un elle hazırlanmış öğretici senaryoları.

Üretilmiş bulmaca gösterilmiyor: beş üretim demekti ve #78'in ölçtüğü saniyeleri açılışa
taşırdı. Senaryolar sabit veri, maliyeti yok.

### 3. Önizleme kendini çiziyor

`GameSession.revealHint()` belirlenimci sırayla bir hücreyi ya da kenarı açıyor — ipucu
düğmesiyle **aynı** kod. Sakin bir tempoyla (0,55 s) çağrılınca bulmaca kendini
dolduruyor: Slitherlink'te kenar kenar, Kakuro'da hücre hücre. "Nasıl oynanır" sorusunun
cevabı zaten o sırada.

İki tur oynuyor, sonra çözülmüş hâlde duruyor. Ekran sonsuza kadar oynamıyor.

**Brief b.7 ile ilişkisi.** Brief "animasyon, rozet ve ses efekti değil" diyor ve kitle
35+. Buradaki hareket süs değil anlatım: sessiz, yavaş, biten, kazanılan bir şey yok.
Ürün sahibi bu ayrımı onayladı. "Hareketi Azalt" açıkken hiç oynamıyor, çözülmüş hâl
duruyor.

### 4. Satırdan tahtaya büyüyen geçiş

iOS 18+ `zoom` geçişi: dokunulan satır açılan ekrana dönüşüyor. iOS 17'de (ADR 0002'nin
asgarisi) normal push kalıyor.

## Sonuçları

- Önizleme dokunmayı yutmuyor (`allowsHitTesting(false)`) ve VoiceOver'a görünmüyor:
  satırın kendi etiketi zaten anlatıyor, ızgarayı hücre hücre okutmak gürültü olurdu.
- Görünüm ekrandan çıkınca `.task` iptal ediliyor, yani görünmeyen satır çizim yapmıyor.
- Başlangıç durumu senkron kuruluyor: `ImageRenderer` görevleri çalıştırmadığı için
  anlık görüntü testlerinde boş kutu kalırdı.
- Önizlemenin dayandığı varsayım — her senaryonun sonlu adımda çözülmesi — testle
  korunuyor; tutmazsa ızgara yarım kalırdı.
- Satırlar iki satır metin + ızgara ile uzadı; dokunma hedefi asgarisi zaten daha küçük
  olduğu için bir şey kaybedilmedi.

## Değerlendirilen alternatifler

- **Çizilmiş simge/illüstrasyon.** Ucuz ve sakin ama bulmacanın gerçek görüntüsü değil;
  ayrıca beş varlık üretmek ve karanlık mod için ikişer hâl demek.
- **Gerçek bir bulmacanın önizlemesi.** En dürüst olanı ama açılışta beş üretim: #78'in
  bütün gün uğraştığı maliyeti ana ekrana taşırdı.
- **Sonsuz döngü.** "Canlı" ama 35+ kitle için yorucu; iki turdan sonra durmak aynı şeyi
  anlatıyor.
- **Satır başına açıklama cümlesi.** Daha görünür ama beş kez tekrar; bölüm altbilgisi
  native ve bir kez.
