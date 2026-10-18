# ADR 0013 — Kakuro üreticisi: benzersizlik sorunu ve arama bütçesi

- Tarih: 2026-10-19
- Durum: **kısmen çözüldü** — çözücü ve arama bütçesi kabul edildi, üretici henüz kabul
  kriterini karşılamıyor
- Açık iş: [#26](https://github.com/digitalsepa-git/pencilmark-puzzles/issues/26)

## Bağlam

Faz 2'nin üçüncü varyantı. Brief b.6 Kakuro'nun üretim zorluğunu "yüksek" olarak işaretliyor
ve haklı çıktı — ama tahmin edilen sebepten değil.

Beklenen zorluk desen kurulumuydu: her kesit 2-9 uzunluğunda olmak zorunda, yani uzun
kesitleri siyah hücreyle kırmak gerekiyor ama her kırma dik yöndeki kesidi de ikiye ayırıyor
ve orada tek hücreli kesit yaratabiliyor. **Bu kısım çözüldü**: ihlal miktarını ölçüp azaltan
hamleleri kabul eden bir arama, dört boyutun hepsinde geçerli desen buluyor ve maliyeti
6 ms'nin altında.

Asıl zorluk başka yerde çıktı.

## Ölçüm: benzersizlik geçerli bir doldurmanın yan ürünü değil

Diğer üç varyantta çalışan yaklaşım — çözümü kur, bulmacayı ondan türet, benzersizliğe hat
karar versin — Kakuro'da **hiç işlemiyor**.

| Ölçüm | Aday | Benzersiz |
|---|---|---|
| Dört zorluk, standart yerleşim | 400 | **0** |
| Uç rakam yanlılığı eklendikten sonra (8×8) | 200 | **0** |
| Dört boyut × üç yoğunluk taraması | 480 | **0** |
| Yerel onarım döngüsü (60 tura kadar) | 80 | **0** |

Toplam 1.160 aday, sıfır benzersiz. Yoğunluk, boyut, rakam yanlılığı ve onarım — dördü de
sonucu değiştirmiyor.

### Teşhis: 2 hücreli kesitlerden oluşan 2×2 blok serbestlik derecesi bırakıyor

Dört giriş hücresi bir 2×2 blok oluşturuyor ve dört kesidin hepsi 2 hücreliyse:

```
A B   →  A+B = S₁ (yatay),  C+D = S₂ (yatay)
C D      A+C = S₃ (dikey),  B+D = S₄ (dikey)
```

Dört denklem var ama **bağımsız değil**: `S₁ + S₂ = S₃ + S₄`, yani dördüncü denklem ilk
üçünden türüyor. Dört bilinmeyene üç bağımsız denklem kalıyor ve bir serbestlik derecesi
açıkta. Onu kapatan tek şey 1-9 aralığı ve kesit içi tekrarsızlık.

Örnek: `A+B=9, A+C=7, B+D=11` için `A=4,B=5,C=3,D=6` çalışıyor — ama `A=2,B=7,C=5,D=4` da
çalışıyor ve `C+D` ikisinde de 9.

Test sabiti `unique2x2` benzersiz çünkü toplamları (7, 16, 8, 15) aralıkta tek bir seçenek
bırakıyor. Yani 2×2 bloklar *bazen* benzersiz, **genellikle değil** — ve üreticinin kurduğu
desenler bu bloklarla dolu (Easy'de kesitlerin ~%73'ü 2 hücreli).

Yerel onarım döngüsünün yakınsamamasının sebebi de bu: her tur bir alternatifi öldürüyor ama
ızgarada birbirinden bağımsız onlarca serbestlik derecesi var; tek tek kapatmak bitmiyor.

## Karar

### 1. Benzersizlik aramayla değil yayılımın tamamlanmasıyla elde edilecek

Yayılım **sağlam**: yalnız hiçbir çözümde yer alamayacak adayları eliyor. Dolayısıyla bütün
hücreleri kesinleştirdiyse o tek çözüm demektir ve aramaya hiç gerek yoktur.

`findSolutions` artık önce mantığı deniyor; kapanırsa tek çözümü döndürüyor. Kapanmazsa
aramaya düşüyor ama bütçeyle.

Bu kestirme Kakuro'da belirleyici: benzersizliği *aramayla* kanıtlamak, ikinci bir çözümün
olmadığını göstermek için ağacın tamamını tüketmek demek ve 14×14'te saniyeler sürüyor.
Bütçesiz bir ölçüm on dakikada bitmedi.

### 2. Arama bütçesi ve `.indeterminate`

`KakuroSolver.searchNodeBudget` (varsayılan 20.000 düğüm) tükenirse arama
`SolverError.searchBudgetExhausted` atıyor, `uniquenessCheck` bunu `.indeterminate`'e
çeviriyor ve hat adayı eliyor.

**Benzersizliği kanıtlanamamış bulmaca kullanıcıya verilmiyor.** Brief b.11'in garantisi
"benzersiz olduğunu *doğruladık*" demek, "muhtemelen benzersiz" demek değil. `SolveOutcome`'a
dördüncü durum eklendi ve hat onu ayrı sayıyor.

### 3. Varsayım tekniği kabul ölçütü olarak kullanılmıyor

Kakuro'nun boyutlarında tek bir varsayım geçişi yüzlerce yayılım çalıştırıyor ve saniyelere
çıkıyor. Yani **kabul edilen Kakuro bulmacaları temel ve orta tekniklerle çözülebilen
bulmacalar** olacak — zaten yayınlanmış Kakuro'nun da tanımı bu. Teknik çözücüde duruyor
(derecelendirme için), kabul kapısında değil.

### 4. Üretici henüz kabul kriterini karşılamıyor ve hattı yok

`KakuroGenerator` geçerli bulmaca üretiyor — desen kuralları tutuyor, doldurma kesit içi
tekrarsız, çözüm bütün toplamları tutuyor — ama benzersiz değil. Bu yüzden
`KakuroGenerator.pipeline()` **yazılmadı**: kabul kriterini karşılamayan bir API, onu kullanan
kodda sessiz bir tuzak olur. 500 bulmaca özellik testi de yok, çünkü geçemez.

Var olan testler ürettiğinin *geçerli* olduğunu doğruluyor; desen tasarımı düzeltildiğinde
o düzeltmenin bir şeyi bozmadığının güvencesi olacaklar.

## Sonraki adım (#26)

Teşhis sonraki adımı da söylüyor: **sorun desen tasarımında.** Gerekli olan şey, 2×2
bloklardan kaçınan ve kesit uzunluklarını çeşitlendiren desenler — 4 hücreli bir yatay
kesidin 2, 3, 2, 4 uzunluğundaki dikey kesitleri kesmesi gibi. Böyle bir yerleşimde denklem
sistemi tam ranklı oluyor ve serbestlik derecesi kalmıyor.

Üç yol var, sırayla denenecek:

1. **Desen ölçütüne 2×2 blok cezası eklemek.** En küçük değişiklik: `violationPenalty`'ye
   "dört kesidi de 2 hücreli olan 2×2 blok" terimi eklenir ve desen araması onlardan kaçınır.
2. **Kesit uzunluğu dağılımını hedeflemek.** Desen araması yalnız geçerliliğe değil, uzunluk
   çeşitliliğine de bakar (ör. 2 hücreli kesit oranına üst sınır).
3. **Kanonik desen kütüphanesi.** Yayınlanmış Kakuro'nun kullandığı yol: elle tasarlanmış,
   simetrik, benzersizliği yapısal olarak destekleyen desenler; üretici yalnız doldurur.
   En güvenli ama en az çeşitlilik veren yol.

Birinci yol ölçümle en ucuz test edilebilir olan ve teşhisle doğrudan uyumlu; oradan
başlanacak.

## Sonuçları

- **Faz 2 Kakuro'da tamamlanmadı.** Dört varyantın üçü bitti (Hashi, Hitori, Calcudoku);
  Kakuro'nun motoru ve çözücüsü bitti, üreticisi bitmedi. Slitherlink'e geçmeden önce #26
  kapanmalı — brief b.13 "bu faz bitmeden arayüze geçilmez" diyor ve aynı mantık varyantlar
  arası sıra için de geçerli.
- **`.indeterminate` bütün varyantlar için kullanılabilir.** Slitherlink'in döngü kısıtı
  Kakuro'dan da pahalı olacak; bu mekanizma orada da gerekecek.
- **Ölçümün değeri yanlış cevabı erken bulmakta.** Dört farklı müdahale (yoğunluk, boyut,
  rakam yanlılığı, onarım) denendi ve hiçbiri sonucu değiştirmedi; teşhis ancak bundan sonra
  netleşti. Tahminle devam edilseydi desen tasarımı hiç sorgulanmazdı.

## Değerlendirilen alternatifler

- **Yoğunluğu artırmak** (daha fazla siyah hücre, daha kısa kesitler): 2×2 blokları
  *çoğaltıyor*, yani sorunu büyütüyor. Ölçümde fark yok.
- **Yoğunluğu azaltmak** (uzun kesitler): teorik olarak daha kısıtlayıcı ama ölçümde
  benzersizlik yine sıfır ve arama maliyeti patlıyor.
- **Uç rakam yanlılığı** (uç toplamların tek bileşimi olması): zorlanmış kesit oranını
  %12'de bırakıyor, yetmiyor.
- **Yerel onarım döngüsü**: bilinen yöntem ve denendi; serbestlik dereceleri bağımsız olduğu
  için 60 turda yakınsamıyor.
- **Arama bütçesini büyütmek ve belirsizleri kabul etmek**: benzersizliği kanıtlanmamış
  bulmaca vermek demek. Brief b.11 buna kapalı ve kategorinin en yaygın şikâyeti bu.
