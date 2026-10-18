# ADR 0012 — Calcudoku üretici algoritması ve teknik seviyeleri

- Tarih: 2026-10-18
- Durum: kabul edildi
- Dayanak: ADR 0005 (boyutlar, zorluk çerçevesi), ADR 0010 (`guessing` kararı), ADR 0011 (ölçüm disiplini)

## Bağlam

Faz 2'nin ikinci varyantı. Hashi ve Hitori'de çalışan yaklaşım aynen kullanıldı: çözümü önce
kur, bulmacayı ondan türet, benzersizliğe hat karar versin.

Calcudoku'da iki şey farklı çıktı ve ikisi de ölçümle görüldü:

1. **Maliyetin ağırlığı yer değiştirdi.** Hashi ve Hitori'de pahalı olan benzersizlik
   kontrolüydü; Calcudoku'da **derecelendirme** pahalı. 8×8'de tek bir bulmacanın `trace`
   çağrısı ilk sürümde 1.100 ms alıyordu — 2.000 ms bütçenin yarısı, tek bir bulmaca için.
2. **Hard ile Expert'i teknik seviyesiyle ayırmak mümkün olmadı.** İki yerleşim de bol bol
   `advanced` üretiyor ve denediğim iki ölçüt de ikisini güvenilir biçimde ayırmıyor.

## Karar

### 1. Üretici: Latin karesi → kafes bölüntüsü → hedefler

Latin karesi `LatinSquare.random` ile kuruluyor (Hitori'den ortak katmana taşındı). Izgara
rastgele bir hücreden başlayıp komşularına doğru büyüyen bağlı kafeslere bölünüyor. Her
kafesin hedefi ve işlemi çözümdeki değerlerden türetiliyor.

Kurulum gereği çıkan garanti: çözüm hem Latin kısıtını hem bütün kafes hedeflerini tutuyor.

### 2. Teknik seviyeleri (Calcudoku'ya özel liste)

| Seviye | Teknik | Ne yapıyor |
|---|---|---|
| `basic` | Latin elemesi | Kesinleşmiş rakam, satır ve sütunundaki adaylardan siliniyor |
| `basic` | küçük kafes | Bir ve iki hücreli kafeslerin aritmetiği |
| `intermediate` | gizli tek | Bir rakamın girebileceği tek hücre kaldıysa oraya yazılıyor |
| `intermediate` | büyük kafes | Üç ve daha fazla hücrelide hedefi tutturan bileşimler aranıyor |
| `advanced` | tek adım varsayım | Bir hücreye rakam varsayılıp çelişki aranıyor |
| `guessing` | — | Yukarıdakiler tükendiği halde bulmaca kapanmıyor |

Kafes yayılımı kafes düzeyinde tam tutarlılık (GAC): hedefi tutturan bileşimler aranıyor,
hiçbir bileşimde görünmeyen aday eleniyor. **Latin kısıtı aramanın içine de taşındı** —
olmasa arama satırda tekrar eden bileşimleri de mümkün sayar ve eleme gücünü kaybeder.

### 3. Varsayım tekniği tek geçişte, ama elemeleri tek tek sayıyor

İlk sürüm ilk elemede durup yayılımı baştan başlatıyordu. 8×8'de bir bulmaca 68 eleme
gerektirebiliyor ve 68 tam tarama derecelendirmeyi **1.100 ms**'ye çıkarıyordu.

Şimdi bir geçişte bulunan bütün elemeler uygulanıyor; **en kötü derecelendirme 117 ms.**
Sayaç yine eleme sayısını tutuyor — `SolveTrace.record` bir geçişte bulunan eleme sayısını
bir kerede alıyor (`times:`). Yani derecelendirme bulmacanın kaç çıkarım gerektirdiğini
ölçmeye devam ediyor, maliyet geçiş sayısı kadar kalıyor.

### 4. Hard ile Expert ayrımı: boyut + mantıksal ilerleme

Teknik seviyesi **birincil**: `basic` → Easy, `intermediate` → Medium, `guessing` → eleniyor
(ADR 0010). `advanced` içindeki ayrım ise iki koşula bakıyor:

```
Expert  ⟺  advanced  ve  kenar ≥ 8  ve  mantıksal ilerleme < 0,35
Hard    ⟺  advanced  ve bunların dışında
```

**Mantıksal ilerleme**, temel ve orta tekniklerin tek başına kesinleştirdiği hücre oranı.

Boyutun karara girmesi ADR 0005'in "boyut, zorluğun çerçevesi" kuralıyla uyumlu ve brief
b.6'yı ihlal etmiyor: **teknik seviyesi yine birincil.** 8×8 bir bulmaca yalnız temel
tekniklerle çözülüyorsa Easy sayılıyor ve Expert hedefinde eleniyor — brief b.6'nın
engellemek istediği şey buydu ("Expert diye açtığı bulmaca kolay çıkarsa yorumda yazar").
İlerleme eşiği de boyutun tek başına yetmesini engelliyor: büyük ızgarada olup da mantığın
neredeyse bitirdiği bir bulmaca Expert değil Hard. İkisi de testle korunuyor.

### 5. Yerleşimler ve sabitler

| Zorluk | Kenar | Kafes boyutu ağırlıkları | Çıkarma/bölme | Çarpma % |
|---|---|---|---|---|
| Easy | 4 | 1:25, 2:75 | kapalı | 50 |
| Medium | 5 | 1:10, 2:60, 3:30 | açık | 40 |
| Hard | 7 | 2:50, 3:35, 4:15 | açık | 30 |
| Expert | 8 | 2:35, 3:40, 4:25 | açık | 20 |

`CalcudokuSolver.cageSearchLimit` = 4096 bileşim, `hypothesisBudget` = 48 hücre,
`GenerationPipeline.maxAttempts` = 2500.

### 6. 500 bulmaca ve performans testleri yalnız release derlemede

Üç varyantın 500'lükleri debug derlemede birlikte **93 saniye**, release'te **5 saniye**
alıyor. CI'ın her PR'da 93 saniye beklemesinin karşılığı yok.

Aynı karar varyant performans testlerini de kapsıyor ve bunu CI söyledi: debug derlemede
Calcudoku Expert üretimi runner'da en kötü **6 saniye** sürüyor ve ilk denememde testi
kırdı. Release'te aynı ölçüm 136 ms. **Debug süresi ürün ölçümü değil** — eşiği o sayıya
göre gevşetmek testi anlamsız kılar, sıkı tutmak runner gürültüsüne bağlı kırmızı PR'lar
üretir.

Bu, **ADR 0003'ün "CI eşiği gevşek, gerçek bütçe cihazda" maddesini günceller**: varyant
performans testlerinin eşiği artık doğrudan brief b.11'in bütçesi (2.000 ms) ve ölçüm
release'te yapılıyor. Pay yeterince geniş olduğu için uydurma bir kat gerekmiyor. Cihaz
ölçümü yine PR şablonundaki satırla raporlanıyor.

Testler `#if !DEBUG` ile debug'da derlenmiyor; CI'ın release adımı onları kapsıyor. Debug
koşusu **93 saniyeden 2 saniyeye** indi.

## Ölçüm

Apple Silicon, release. Yerleşim başına 200 aday, hat başına 40 üretim.

| Zorluk | Benzersiz | basic | intermediate | advanced | guessing |
|---|---|---|---|---|---|
| Easy | 146/200 | 132 | 13 | 1 | 0 |
| Medium | 170/200 | 63 | 106 | 1 | 0 |
| Hard | 173/200 | 4 | 97 | 72 | 0 |
| Expert | 61/200 | 0 | 16 | 44 | **1** |

| Zorluk | Deneme ort. | En kötü | Süre ortanca | Süre en kötü |
|---|---|---|---|---|
| Easy | 1 | 4 | 0,05 ms | 0,24 ms |
| Medium | 1 | 4 | 0,16 ms | 1,22 ms |
| Hard | 2 | 11 | 4,69 ms | 45,34 ms |
| Expert | 4 | 19 | 25,50 ms | **183,14 ms** |

Bütçe 2.000 ms, en kötü 183 ms → **11 kat pay.** (Hashi 65, Hitori 20.)

**Kafes boyutu dağılımı yerleşimden sapıyor.** Hard ve Expert yerleşimleri tek hücreli kafes
istemiyor ama üretilen kafeslerin %19-21'i tek hücreli çıkıyor: büyüme sırasında etrafı
dolmuş bir hücre hedef boyuta ulaşamıyor ve tek başına kalıyor. Zorluğu kolaylaştırıcı yönde
etkiliyor (tek hücreli kafes verilmiş değer demek) ve ağırlıklar bu sapma ölçüldükten sonra
seçildi.

## Sonuçları

- **Calcudoku üç varyantın en darı** (11 kat pay) ve maliyetin ağırlığı derecelendirmede.
  Faz 3'teki cihaz ölçümünde Hitori ile birlikte en dikkat edilecek varyant.
- **`guessing` ilk kez görüldü**: 800 adayda 1. ADR 0010'un eleme kararının bedeli Hashi ve
  Hitori'de sıfırdı, burada ihmal edilebilir ama sıfır değil. Slitherlink'te belirgin
  olmasını bekliyorum.
- **Hard/Expert ayrımı kısmen boyuta dayanıyor.** Aynı boyutta iki `advanced` bulmacayı
  ayıramıyoruz — ama ikisi aynı hedefte üretilmediği için pratikte sorun çıkmıyor. Risk:
  7×7 bir Hard ile 8×8 bir Expert oyuncuya benzer gelebilir. Faz 4'teki TestFlight dış
  testinde sorulacak sorulardan biri bu.
- **Kabul oranları üç varyantın en iyisi** (%66, %53, %36, %22). Hashi ve Hitori'de Hard ve
  Expert %1-5 bandındaydı.
- `SolveTrace.record` artık `times:` alıyor; pahalı tekniklerin her çıkarımdan sonra yayılımı
  baştan başlatmasını gereksiz kılan şey bu. Hashi ve Hitori'de davranış değişmedi.
- **Debug koşusu 93 saniyeden 2 saniyeye indi.** Ağır testlerin release'e taşınmasının yan
  faydası: her PR'daki geri bildirim döngüsü belirgin şekilde kısaldı.

## Değerlendirilen alternatifler

- **Hard/Expert'i varsayım sayısıyla ayırmak.** İlk ölçüm umut verdi (Hard 1-6, Expert 10-40)
  ama o rakamlar her elemeden sonra baştan başlayan pahalı sürümden geliyordu. Tek geçişli
  sürümde sayılar 42-230 bandına çıktı ve iki yerleşimin histogramları örtüştü.
- **Yalnız mantıksal ilerlemeyle ayırmak.** Ölçümde Hard %0-49, Expert %0-29 — büyük örtüşme.
  Tek başına kullanılırsa Hard kabul oranı %7,5'e düşüyor.
- **Toplam çıkarım adımıyla ayırmak.** Adım sayısı ızgara boyutuyla birlikte artıyor, yani
  ölçüt aslında boyutu gizli biçimde kodluyor — açıkça boyuta bakmak daha dürüst.
- **İpucu-önce üretim** (hedefleri atıp çözüm aramak): adayların çoğu çözümsüz çıkıyor.
- **`cageSearchLimit`'i büyütmek:** daha güçlü yayılım ama 5 hücreli bir kafes tek başına
  59.049 bileşim deniyor; ölçümde kazanç maliyeti karşılamıyor.
- **Expert'i 9×9 yapmak** (ADR 0005 aralığı 8×8-9×9'a izin veriyor): 8×8'de en kötü süre
  183 ms; 9×9 payı daha da daraltır. V2'de yeniden ölçülebilir.
