# Pencilmark Puzzles

Tek bir iOS uygulamasında beş klasik mantık bulmacası: **Kakuro, Calcudoku, Slitherlink,
Hashi, Hitori**. Hedef pazar ABD, uygulama arayüz dili İngilizce.

| | |
|---|---|
| App Store adı | Kakuro & Calcudoku Puzzles |
| Alt başlık | Slitherlink, Hashi & Hitori |
| Geliştirici | Pencilmark Games |
| Platform | iOS 17+ |
| Dil / araçlar | Swift 6 (strict concurrency), SwiftUI, SwiftData, StoreKit 2 |
| Üçüncü parti bağımlılık | yok (SPM dahil) |

## Dokümanlar

| Dosya | Ne işe yarar |
|---|---|
| [`docs/brief.md`](docs/brief.md) | İşin tek referans kaynağı. Orijinal PDF: `docs/brief.pdf` |
| [`docs/decisions/`](docs/decisions/) | ADR'ler — geri dönüşü pahalı kararlar ve gerekçeleri |
| [`docs/progress.md`](docs/progress.md) | Kronolojik iş günlüğü, her merge'den sonra bir satır |
| [`docs/terimler.md`](docs/terimler.md) | Türkçe doküman ↔ İngilizce kod terim eşlemesi |
| [`docs/arastirma/`](docs/arastirma/) | Rakip araştırması ve pazar notları |

## Repo yapısı

```
Packages/PuzzleKit/   SPM paketi — motor (saf Swift, arayüz bağımsız)
App/                  Xcode projesi (Faz 3'te geliyor)
docs/                 brief, ADR'ler, iş günlüğü, araştırma
.github/              PR şablonu, CI workflow
```

## Kurulum

Gereken: macOS, Xcode 17 veya üstü (Swift 6 toolchain).

```bash
git clone https://github.com/digitalsepa-git/pencilmark-puzzles.git
cd pencilmark-puzzles
```

Motor üzerinde çalışmak için Xcode'a ihtiyaç yok, yalnız Swift toolchain yeter.

## Çalıştırma ve test

Motor testleri (arayüz gerekmez, saniyeler içinde koşar):

```bash
swift test --package-path Packages/PuzzleKit
```

Tek bir test paketi:

```bash
swift test --package-path Packages/PuzzleKit --filter HashiSolverTests
```

Performans testleri yavaştır, ayrı koşar:

```bash
swift test --package-path Packages/PuzzleKit -c release --filter Performance
```

Lint:

```bash
swiftlint lint --strict
```

Uygulama hedefi Faz 3'te eklenecek; o zamana kadar `App/` boş.

## Çalışma akışı

Bağlayıcı — detayı [`docs/brief.md`](docs/brief.md) bölüm 10'da:

1. Issue aç (kabul kriteri olmadan issue hazır değil)
2. Tek konulu dal: `feat/…`, `fix/…`, `chore/…`, `docs/…`
3. Küçük commit'ler, Conventional Commits, mesaj *neden* yapıldığını da söyler
4. PR aç, şablonu doldur, `Closes #N` ile issue'ya bağla
5. CI yeşil olmadan merge yok
6. Merge sonrası `docs/progress.md`'ye bir satır

Geri dönüşü pahalı her karar `docs/decisions/` altına ADR olarak yazılır.
