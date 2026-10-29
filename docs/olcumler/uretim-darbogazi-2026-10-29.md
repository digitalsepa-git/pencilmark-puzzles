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

## Sonuç

Darboğaz tek bir yerde: seyrek ızgarada koşturulan yayılım çözümleri, silme başına bir
tane. Çözüm yönleri şunlar ve hiçbiri henüz denenmedi:

1. **Toplu silme.** K ipucunu birlikte silip bir kez doğrula; başarısızsa geri koyup
   teker teker dene. Çözücü çağrısını K kat azaltıyor, ürün davranışını değiştirmiyor.
2. **Pahalı kuyruğu kısaltmak.** Son çeyrekte denemelerin çoğu reddediliyor; sıra
   bilgisine dayalı bir durma ölçütü o çeyreği kısaltabilir.
3. **Arka planda önceden üretim.** Maliyeti düşürmüyor, oyuncudan gizliyor. İlk
   bulmacanın beklemesini kaldırmıyor.

(1) ürün davranışını hiç değiştirmediği için ilk denenecek olan.
