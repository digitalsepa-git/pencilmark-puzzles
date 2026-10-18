# Karar kayıtları (ADR)

Geri dönmesi pahalı olan her teknik karar burada: başlık, bağlam, karar, sonuçları,
değerlendirilen alternatifler. Yarım sayfayı geçmiyor. Amaç üç ay sonra "bunu neden böyle
yaptık" sorusuna cevap verebilmek (brief b.10).

| No | Karar | Durum |
|---|---|---|
| [0001](0001-repo-dili-ve-calisma-akisi.md) | Repo dili ve çalışma akışı | kabul |
| [0002](0002-minimum-ios-surumu.md) | Minimum iOS sürümü 17.0 | kabul |
| [0003](0003-ci-topolojisi-ve-performans-olcumu.md) | CI topolojisi ve performans ölçümü | kabul |
| [0004](0004-sifir-bagimlilik-ve-anlik-goruntu-testi.md) | Sıfır bağımlılık ve anlık görüntü testi | kabul |
| [0005](0005-izgara-boyutlari-ve-zorluk-cercevesi.md) | Izgara boyutları ve zorluk çerçevesi | kabul, 0010 ile güncellendi |
| [0006](0006-gunluk-bulmaca-tohum-ve-saat-dilimi.md) | Günlük bulmaca: tohum, saat dilimi, varyant eşlemesi | kabul |
| [0007](0007-ucretsiz-katman-mekanigi.md) | Ücretsiz katman mekaniği ve ipucu sınırı | kabul |
| [0008](0008-istatistik-katmanlari.md) | İstatistik: ücretsiz ve Plus katmanları | kabul |
| [0009](0009-etkilesimli-ogretici.md) | Etkileşimli öğretici | kabul |
| [0010](0010-hashi-uretici-ve-teknik-seviyeleri.md) | Hashi üretici algoritması ve teknik seviyeleri | kabul |
| [0011](0011-hitori-uretici-ve-teknik-seviyeleri.md) | Hitori üretici algoritması ve teknik seviyeleri | kabul |
| [0012](0012-calcudoku-uretici-ve-teknik-seviyeleri.md) | Calcudoku üretici algoritması ve teknik seviyeleri | kabul |
| [0013](0013-kakuro-uretici-benzersizlik-sorunu.md) | Kakuro: benzersizlik sorunu ve arama bütçesi | **kısmen çözüldü** |

Beklenen, henüz yazılmamış kararlar:

- Varyant başına üretici algoritması ve teknik seviyesi listesi — Hashi 0010, Hitori 0011, Calcudoku 0012, Kakuro 0013 (üretici kısmı açık); Slitherlink kendi PR'ında (Faz 2)
- Kakuro desen tasarımı — 0013'ün açık bıraktığı iş, [#26](https://github.com/digitalsepa-git/pencilmark-puzzles/issues/26)
- Saklama şeması ve SwiftData model sürümleme — Faz 3
- Grid çizim yaklaşımı (Canvas katmanlama, yakınlaştırma) — Faz 3
- StoreKit 2 yetki kontrolü ve ürün kimlikleri — Faz 3
