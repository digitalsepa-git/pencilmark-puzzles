# ADR 0001 — Repo dili ve çalışma akışı

- Tarih: 2026-10-17
- Durum: kabul edildi

## Bağlam

Brief bölüm 10 bağlayıcı: hiçbir iş doğrudan `main`'e yazılmaz, her iş kendi issue'su, dalı,
PR'ı ve günlük satırıyla ilerler. Brief Türkçe yazıldı ama uygulamanın arayüz dili İngilizce
ve `PuzzleKit` ileride taşınabilir kalmak zorunda (b.9). Repo dilinin ne olacağı bu iki
gereksinim arasında bir seçim gerektiriyor.

## Karar

**Dokümanlar, issue'lar, PR'lar, commit açıklamaları, ADR'ler ve iş günlüğü Türkçe.**
Ekip tek kişi ve karar verici Türkçe okuyor; geriye dönük okunabilirlik asıl amaç (b.10).

**Kod İngilizce:** tip adları, fonksiyon adları, parametreler, dosya adları, test adları.
`PuzzleKit` dışa açık bir API yüzeyi ve ileride taşınabilir olması isteniyor; Türkçe tanımlayıcı
adları Swift ekosisteminde okunabilirliği düşürür ve diyakritikler sorun çıkarır.

**Kod içi yorumlar Türkçe.** Yorumun işi "neden böyle" sorusunu cevaplamak; bu da karar
kaydının bir parçası.

**Commit mesajları Conventional Commits.** Tür önekleri İngilizce ve standart
(`feat`, `fix`, `chore`, `docs`, `test`, `perf`, `refactor`), açıklama Türkçe:

```
feat(hashi): köprü kesişme kontrolü eklendi

Kesişme kontrolünü kural doğrulayıcıya değil çözücüye koyduk; doğrulayıcı
hamle başına çağrılıyor ve O(n) tarama orada kare karmaşıklık yaratıyordu.
```

Dal adları İngilizce ve tek konulu: `feat/hashi-generator`, `chore/ci-setup`.

## Sonuçları

- Projeyi devralacak kişinin Türkçe okuması gerekir. Kabul edildi: sahiplik tek kişide.
- Kod ve doküman arasında terim eşlemesi gerekiyor (ör. "kesit" ↔ `run`, "kafes" ↔ `cage`,
  "karala" ↔ `shade`). Sözlük `docs/terimler.md` dosyasında tutulacak.
- CI çıktıları ve araç mesajları İngilizce kalır; değiştirilmeye çalışılmayacak.

## Değerlendirilen alternatifler

- **Her şey İngilizce:** devralma kolaylığı artar ama karar gerekçeleri kayıt sahibinin
  kendi dilinde olmazsa daha az ve daha yüzeysel yazılır. Asıl risk ADR'lerin boş kalması.
- **Her şey Türkçe (kod dahil):** Swift'te `struct Izgara` okunabilirliği düşürür, dış API
  olarak kullanılamaz, motorun taşınabilirlik hedefini bozar.
