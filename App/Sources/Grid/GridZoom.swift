import CoreGraphics

/// Izgaranın yakınlaştırma ve kaydırma durumu.
///
/// Çizime bir dönüşüm olarak **uygulanmıyor**; `GridGeometry`'ye girdi oluyor ve ızgara
/// büyük hücre kenarıyla yeniden çiziliyor. Sebebi netlik: `scaleEffect` `Canvas`'ın
/// hazır bitmap'ini büyütür ve 3 kat yakınlaştırmada çizgiler de rakamlar da bulanır —
/// oysa yakınlaştırmanın bütün amacı küçük rakamı okumak.
///
/// Saf ve `SwiftUI` bilmiyor: kırpma ve çapa hesabının doğruluğu sayıyla sınanabilmeli
/// (bkz. `GridGeometry`'nin aynı gerekçesi).
struct GridZoom: Equatable {
    /// 1 = ızgara ekrana sığdırılmış hâli; büyüdükçe yakınlaşıyor.
    var scale: CGFloat
    /// Izgara merkezinin ekran merkezinden kaydırılmış mesafesi.
    var pan: CGSize

    static let identity = GridZoom(scale: 1, pan: .zero)

    /// Alt sınır 1: ızgarayı ekrandan küçük göstermenin oyuncuya faydası yok.
    static let minimumScale: CGFloat = 1
    /// Üst sınır 3. Ölçü en sıkışık iki durumdan geliyor: Expert Kakuro 11×11'de hücre
    /// iPhone'da ~30 pt, Slitherlink 12×12'de kenar dokunma payı ~9 pt. 3 kat ikisini de
    /// rahat dokunulur aralığa çıkarıyor (90 pt ve ~27 pt); daha fazlası ızgaranın
    /// tamamını gözden kaçırmaya başlıyor.
    static let maximumScale: CGFloat = 3

    var isIdentity: Bool { self == .identity }

    /// Ölçek sınırlara kırpılmış hâli.
    static func clampScale(_ scale: CGFloat) -> CGFloat {
        guard scale.isFinite else { return minimumScale }
        return min(max(scale, minimumScale), maximumScale)
    }

    /// Kaydırmanın izin verilen en büyük mesafesi: ızgaranın kenarı görüş alanının
    /// içine giremez. Ekrana sığan bir ızgarada sıfır, yani yakınlaştırma yokken
    /// kaydırma da yok.
    static func panLimit(board: CGSize, viewport: CGSize, scale: CGFloat) -> CGSize {
        CGSize(
            width: max((board.width * scale - viewport.width) / 2, 0),
            height: max((board.height * scale - viewport.height) / 2, 0)
        )
    }

    /// Sınırların dışına düşmüş durumu içeri çekiyor.
    ///
    /// Yalnız hareketin sonunda değil çizim sırasında da çağrılıyor: cihaz döndüğünde ya
    /// da ızgara boyu değiştiğinde eldeki kaydırma geçersizleşiyor ve ızgara ekranın
    /// dışında kalabilir.
    func clamped(board: CGSize, viewport: CGSize) -> GridZoom {
        let scale = Self.clampScale(self.scale)
        let limit = Self.panLimit(board: board, viewport: viewport, scale: scale)
        return GridZoom(
            scale: scale,
            pan: CGSize(
                width: min(max(pan.width, -limit.width), limit.width),
                height: min(max(pan.height, -limit.height), limit.height)
            )
        )
    }

    /// Verilen ekran noktası sabit kalacak şekilde ölçeği değiştiriyor.
    ///
    /// Çapa olmadan sıkıştırma ızgarayı merkezden büyütür ve parmağın altındaki hücre
    /// kayar; oyuncu okumak istediği yeri kaybeder.
    ///
    /// `anchor` görüş alanının **merkezine göre** verilen bir nokta. Izgara noktasının
    /// ekrandaki yeri `merkez + pan + (nokta - merkez) * ölçek` olduğundan, çapanın
    /// altındaki noktayı yerinde tutmak için `pan` yeni ölçekle oranlı küçülüyor.
    func magnified(
        to scale: CGFloat,
        about anchor: CGPoint,
        board: CGSize,
        viewport: CGSize
    ) -> GridZoom {
        let target = Self.clampScale(scale)
        guard self.scale > 0 else { return .identity }
        let ratio = target / self.scale
        let offsetX = anchor.x - pan.width
        let offsetY = anchor.y - pan.height
        return GridZoom(
            scale: target,
            pan: CGSize(
                width: anchor.x - offsetX * ratio,
                height: anchor.y - offsetY * ratio
            )
        ).clamped(board: board, viewport: viewport)
    }

    func panned(by translation: CGSize, board: CGSize, viewport: CGSize) -> GridZoom {
        GridZoom(
            scale: scale,
            pan: CGSize(
                width: pan.width + translation.width,
                height: pan.height + translation.height
            )
        ).clamped(board: board, viewport: viewport)
    }
}
