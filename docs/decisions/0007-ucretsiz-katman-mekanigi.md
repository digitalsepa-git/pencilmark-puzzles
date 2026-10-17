# ADR 0007 — Ücretsiz katman mekaniği ve ipucu sınırı

- Tarih: 2026-10-17
- Durum: kabul edildi

## Bağlam

Brief b.8 ücretsiz katmanı "günde 3 bulmaca + günlük bulmaca, tüm varyantlar, Easy ve
Medium" olarak tanımlıyor. Ama V1'de hesap, sunucu ve bulut yok (b.5) — yani sayaç tamamen
cihazda. Dört soru açıkta kalıyordu: sayaç ne zaman sıfırlanır, yarım kalan bulmaca kotayı
tekrar harcar mı, günlük bulmaca kotaya dahil mi, ve cihaz saatini değiştiren kullanıcıya ne
olur.

## Karar

**Kota, "yeni bulmaca başlatma" üzerinden sayılıyor; günde 3.**

- Sıfırlanma cihazın yerel gece yarısında (ADR 0006'daki gün tanımıyla aynı).
- **Günlük bulmaca kotadan sayılmıyor.** Yani ücretsiz kullanıcı günde 4 bulmaca oynuyor.
- Yarım kalan bulmacaya dönmek kota harcamıyor. Kota bulmaca kimliği başına günde bir kez
  düşüyor; aynı bulmacayı sıfırlayıp baştan başlamak da yeni başlatma sayılmıyor.
- Easy ve Medium ücretsiz, Hard ve Expert Plus (b.8 aynen).

**İpucu: ücretsiz katmanda günde 3, varyanttan bağımsız ortak havuz. Plus'ta sınırsız.**
Bulmaca başına değil günlük havuz olmasının sebebi: bulmaca başına sınır, kullanıcıyı ipucu
toplamak için bulmacayı sıfırlamaya iter. Günlük havuz hem açıklaması kolay hem bulmaca
kotasıyla aynı zihinsel modeli kullanıyor.

**Cihaz saati.** En son görülen yerel tarih saklanıyor ve **geriye gidiş yok sayılıyor**:
saat geri alınırsa kota yenilenmiyor. İleri alınırsa yenileniyor — bu bilinçli bir boşluk,
kapatmak sunucu gerektirir ve V1'de sunucu yok (b.5).

**Paywall en az 3 bulmaca bitirilmeden gösterilmiyor** (b.8). Kullanıcı 3 bulmacayı
bitirmeden kotayı tüketirse paywall değil sade bir "yarın yeniden" mesajı görüyor.

## Sonuçları

- Saati ileri alan kullanıcı sınırsız oynar. Kabul edildi: bu kitlede yaygın bir davranış
  değil ve engellemenin maliyeti (hesap + sunucu) ürünün tamamını değiştiriyor.
- Kota "başlatma" üzerinden sayıldığı için kullanıcı bir bulmacaya bakıp beğenmezse hakkı
  gider. Bunu yumuşatmak için zorluk seçiminden sonra bulmaca doğrudan açılıyor, ön izleme
  yok — hak harcandığında kullanıcı zaten oynuyor olacak.
- Saklama şeması günlük sayaç için üç alan tutuyor: son görülen yerel tarih, o gün
  başlatılan bulmaca kimlikleri, o gün kullanılan ipucu sayısı.
- Günlük bulmacanın kotadan muaf olması, günlük bulmacayı alışkanlık motoru yapıyor; bu
  paylaşım kartının (tek organik kanal) çalışması için gerekli.

## Değerlendirilen alternatifler

- **Kotayı "bitirme" üzerinden saymak:** kullanıcı dostu ama istismara açık — bulmacayı
  bitirmeyip sürekli yenisini açmak sınırsız oyun demek.
- **Bulmaca başına ipucu sınırı:** daha cömert görünür, bulmacayı sıfırlayıp ipucu toplama
  davranışını teşvik eder.
- **İpucunun tamamen ücretsiz olması:** ipucu bu kategoride gerçek bir değer; sınırsız
  verilmesi Plus'ın gerekçesini zayıflatır.
- **Sunucu tarafı kota:** saat manipülasyonunu tamamen kapatır. B.5 "V1 tamamen çevrimdışı"
  diyor ve hesap/sunucu açmak gizlilik etiketini de ("veri toplanmıyor") bozar.
