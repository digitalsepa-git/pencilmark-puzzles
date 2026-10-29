# Üretim darboğazı — nerede olduğu ölçüldü

#78'in ilk adımı. Cihaz ölçümü (`cihaz-olcumu-2026-10-29.md`) üretimin brief'in 2
saniyelik ölçütünü aştığını göstermişti; bu belge **nerede** aştığını arıyor.

Bütün ölçümler Mac'te, Debug derlemesinde. Mutlak sayılar cihazdakinden farklı; aranan
şey oran.

## 1. Tur sayısı mı, tur maliyeti mi

| | ortalama tur | ortalama süre | tur başına |
|---|---|---|---|
| Kakuro Medium | 5,0 | 1406 ms | 281 ms |
| Kakuro Hard | 5,9 | 2091 ms | 354 ms |
| Kakuro Expert | 2,6 | 3967 ms | 1526 ms |
| Slitherlink Medium | 2,8 | 2581 ms | 921 ms |
| Slitherlink Hard | 1,4 | 2873 ms | 2052 ms |
| Slitherlink Expert | 1,2 | 5799 ms | **4833 ms** |
| Calcudoku Hard | 1,9 | 96 ms | 50 ms |
| Calcudoku Expert | 3,1 | 1258 ms | 405 ms |

İki ayrı sorun var:

- **Kakuro Hard** çok tur dönüyor (5,9), turu ucuz. Kabul oranı düşük.
- **Slitherlink ve Kakuro Expert** az tur dönüyor ama tek tur saniyeler sürüyor.

## 2. Turun içinde nerede

Hat her turda üç şey yapıyor: aday kur, benzersizliği kontrol et, izini çıkar.

| | aday kurma | benzersizlik | iz |
|---|---|---|---|
| Slitherlink Expert | **5559 ms** | 63 ms | 62 ms |
| Kakuro Expert | **586 ms** | 6 ms | 25 ms |

Çözücü darboğaz değil. Hattın kabul edilen her aday için çözücüyü iki kez çağırması
(`uniquenessCheck` + `trace`) toplamın %2'si; o yüzden birleştirmenin anlamı yok.

## 3. Aday kurmanın içinde nerede

Yanlış çıkan iki tahmin, kayıt için:

- **`SlitherlinkPuzzle(clues:)` kurucusu.** Izgaranın topolojisini (312 kenar, 169 nokta,
  hücre-kenar tabloları) her çağrıda baştan kuruyor ve bu yalnız boyuta bağlı. 12×12'de
  144 kurma = **28 ms**. Önemsiz.
- **Döngü kurucusu** (`SlitherlinkLoopBuilder.inside`). Expert'te **12 ms**. Önemsiz.

Asıl yer **ipucu inceltme döngüsü**. Döngü her ipucu silme denemesinden sonra yayılımın
bulmacayı hâlâ kapattığını doğruluyor; yani silme başına bir yayılım çözümü. Izgara
seyreldikçe o çözüm pahalılaşıyor:

| İnceltme adımı | Son 36 çağrı | Çağrı başına | O aralıkta başarılı silme |
|---|---|---|---|
| 1–36 | 315 ms | 8,8 ms | 36 / 36 |
| 37–72 | 745 ms | 20,7 ms | 28 / 36 |
| 73–108 | 2204 ms | 61 ms | 16 / 36 |
| 109–144 | 3171 ms | 88 ms | 9 / 36 |

Tek adayın inceltilmesi 6435 ms. **Son çeyrek toplamın yarısı** ve orada 36 denemeden 27'si
reddediliyor — yani en pahalı çözümlerin çoğu boşa gidiyor.

## 4. Denenen ve işe yaramayan: toplu silme

İlk çözüm fikri toplu silmeydi: K ipucunu birlikte silip bir kez doğrulamak, başarısızsa
geri koyup teker teker denemek. Çözücü çağrısını azaltıyor, ürün davranışını
değiştirmiyor. Prototip ölçüldü (K=4, Expert, üç tohum):

| Tohum | Tek tek | Toplu |
|---|---|---|
| 24301 | 5881 ms / 144 çağrı | 6724 ms / 128 çağrı |
| 48879 | 5550 ms / 144 çağrı | 6286 ms / 116 çağrı |
| 49374 | 5525 ms / 144 çağrı | 6536 ms / 128 çağrı |

**Çağrı sayısı düştü, süre arttı.** Toplu silmede çözücü daha seyrek bir ızgarayla
karşılaşıyor ve bölüm 3'teki tablo zaten seyrekliğin maliyeti patlattığını gösteriyordu;
dört ipucu birden silmek o patlamayı öne çekiyor. Üstelik başarısız bir toplu deneme hem
kendi pahalı çözümünü hem de ardından gelen tek tek çözümleri ödetiyor.

**Çıkarılan ders:** kaldıraç çağrı sayısı değil, çözüm anındaki seyreklik.

## Sonuç

Darboğaz seyrek ızgarada koşturulan yayılım çözümleri. Çağrı sayısını azaltan her yaklaşım
çağrıları daha seyrek ızgaralara kaydırdığı için ters tepiyor. Geriye üç yol kalıyor:

1. **Yayılımı seyrek ızgarada hızlandırmak.** Asıl çözüm ama kapsamı belirsiz; çözücünün
   içine girmeyi gerektiriyor.
2. **Arka planda önceden üretim.** Maliyeti düşürmüyor, oyuncudan gizliyor. İlk
   bulmacanın beklemesini kaldırmıyor ama ikinciden sonrasını sıfırlıyor.
3. **Daha az seyreltmek.** Ürün değişikliği: daha çok ipucu, daha kolay bulmaca. Brief'in
   zorluk tanımına dokunuyor.

V1 için (2) öngörülebilir ve sınırlı; (1) sonraya kalabilir. (3) ürün kararı olduğu için
ölçümle değil briefle çözülür.

## 5. Yapılan: temel seviyenin işini iki kez yapmamak

`SlitherlinkSolver.propagationTier` iki kez sıfırdan yayılım yapıyordu: önce yalnız temel
kurallarla, kapatmazsa **yeni bir alan kümesiyle** temel + orta kurallarla. İkinci geçiş
birincinin işini baştan tekrarlıyordu.

Yayılım monoton (kurallar yalnız daraltıyor) ve birikimli, yani ulaşılan sabit nokta
kuralların uygulanma sırasından bağımsız. Orta seviye artık temel seviyenin bıraktığı
yerden devam ediyor. Temel seviyede çelişki çıkarsa orta seviye de çıkaracağı için o
durumda ikinci geçiş hiç yapılmıyor.

Değişiklik üreticinin çıktısını **değiştirmiyor**: aynı tohumla üretilen dokuz bulmacanın
parmak izi eski ve yeni kodda birebir aynı çıktı. Günlük bulmaca ve `Seed.algorithmVersion`
etkilenmiyor.

### Cihazda ölçülen etki

iPhone 14 Pro Max, ortanca · en kötü (ms):

| Slitherlink | Önce | Sonra |
|---|---|---|
| Easy | 44 · 66 | 45 · 68 |
| Medium | 741 · 1488 | 572 · 1168 |
| Hard | 1199 · 1911 | 884 · 1575 |
| Expert | **3644 · 4021** | **2575 · 2828** |

Expert'te ortanca %29 düştü. Kakuro ve Calcudoku değişmedi; onların çözücüleri ayrı ve
bu kalıp yalnız Slitherlink'te vardı.

### Brief'in ölçütü hâlâ karşılanmıyor

2 saniyeyi aşan dört hücre üçe inmedi, dörtte kaldı ama biri iyileşti:

| Hücre | Önce | Sonra |
|---|---|---|
| Kakuro Hard | 2222 | 2235 (değişmedi) |
| Kakuro Expert (en kötü) | 4322 | 4387 (değişmedi) |
| Calcudoku Expert (en kötü) | 3681 | 3760 (değişmedi) |
| Slitherlink Expert | 3644 | 2575 |

Sıradaki yer belli: Kakuro'nun aday kurması (tur başına 586 ms) ve Hard'ın düşük kabul
oranı (5,9 tur). İkisine de bakılmadı.

## 6. Kakuro: aynı aramanın iki kez yapılması

Kakuro'nun yönlendirme döngüsü her turda `findSolutions(upTo: 2)` çağırıyordu. Sonuç tek
çözüm değilse atılıyor, sonra çok-çözümlü dalda **aynı çağrı ikinci kez** yapılıyordu —
bu sefer iki çözümün ayrıştığı hücreyi bulmak için. Çözücü belirlenimci, yani ikinci
çağrı yeni bilgi vermiyordu.

Reddedilen her tur benzersizlik kontrolünü iki kez ödüyordu ve reddedilen turlar
çoğunluk: Hard'da tur başına 5,9 deneme.

Tek arama, iki dal. Çıktı değişmiyor: aynı tohumlarla üretilen dokuz bulmacanın parmak
izi eski ve yeni kodda birebir aynı. Rastgelelik tüketimi de değişmiyor, çünkü ikinci
çağrı rastgelelik kullanmıyordu.

### Cihazda ölçülen etki

iPhone 14 Pro Max, ortanca · en kötü (ms):

| Kakuro | Önce | Sonra |
|---|---|---|
| Easy | 110 · 255 | 78 · 176 |
| Medium | 540 · 1584 | 349 · 969 |
| Hard | **2222 · 2284** | **1195 · 1312** |
| Expert | **1208 · 4322** | **675 · 2357** |

Calcudoku'da aynı kalıp yok; üreticisi çözücüyü doğrudan çağırmıyor.

## 7. Nerede duruyoruz

Brief b.5'in 2 saniyelik ölçütü, en kötü durum (iPhone 14 Pro Max):

| Hücre | İlk ölçüm (#66) | Şimdi | Durum |
|---|---|---|---|
| Kakuro Hard | 2284 | 1312 | geçti |
| Kakuro Expert | 4322 | 2357 | hâlâ üstünde |
| Calcudoku Expert | 3681 | 3654 | hâlâ üstünde (dokunulmadı) |
| Slitherlink Expert | 4021 | 2704 | hâlâ üstünde |

Ortancalarda yalnız Slitherlink Expert (2448 ms) ölçütün üstünde.

İki iyileştirme de aynı türdendi: **aynı hesabın iki kez yapılması**. Üçüncüsü
Calcudoku'da aranabilir ama oradaki maliyet hat seviyesindeki tur sayısından geliyor,
tur içindeki tekrardan değil.
