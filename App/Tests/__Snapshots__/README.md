# Anlık görüntü referansları

Bu klasördeki PNG'ler **CI'da üretildi**, geliştirme makinesinde değil. Sebebi ADR 0016'da:
geliştirme makinesiyle CI runner'ının ortak bir iOS simülatör çalışma zamanı yok ve piksel
karşılaştırması sürüme duyarlı.

Üretildikleri yapılandırma:

| | |
|---|---|
| Çalışma zamanı | iOS 18.6 |
| Cihaz | iPhone 16 |
| Çizim ölçeği | 2× |

## Yeniden üretmek

Çizim bilerek değiştiyse referanslar yeniden üretilmeli:

1. GitHub'da **Actions → Anlık görüntü referansları → Run workflow**
2. Koşu bitince `anlik-goruntu-referanslari` artifact'ini indir
3. İçeriğini bu klasöre kopyala, değişikliği PR'da gözden geçir

`__Failures__/` CI'ın kırmızı koşularda ürettiği fark görüntüleri için; repoda durmuyor.
