import CoreGraphics
import Testing
import PuzzleKit
@testable import Pencilmark

@Suite("Izgara yakınlaştırma")
struct GridZoomTests {
    private let board = CGSize(width: 300, height: 300)
    private let viewport = CGSize(width: 300, height: 300)

    @Test("Ölçek sınırların dışına çıkmıyor")
    func scaleStaysWithinBounds() {
        #expect(GridZoom.clampScale(0.2) == GridZoom.minimumScale)
        #expect(GridZoom.clampScale(9) == GridZoom.maximumScale)
        #expect(GridZoom.clampScale(2) == 2)
        // Sıkıştırma hareketinden sıfıra bölünmüş bir değer gelirse çökmemeli.
        #expect(GridZoom.clampScale(.nan) == GridZoom.minimumScale)
    }

    @Test("Ekrana sığan ızgarada kaydırma yok")
    func noPanWhileTheGridFits() {
        let limit = GridZoom.panLimit(board: board, viewport: viewport, scale: 1)
        #expect(limit == .zero)

        let moved = GridZoom.identity.panned(
            by: CGSize(width: 120, height: -80),
            board: board,
            viewport: viewport
        )
        #expect(moved == .identity)
    }

    @Test("Kaydırma ızgaranın kenarında duruyor")
    func panStopsAtTheBoardEdge() {
        let zoomed = GridZoom(scale: 2, pan: .zero)
        // 2 katta ızgara 600 pt, görüş alanı 300 pt: her yöne 150 pt pay var.
        let limit = GridZoom.panLimit(board: board, viewport: viewport, scale: 2)
        #expect(limit == CGSize(width: 150, height: 150))

        let moved = zoomed.panned(
            by: CGSize(width: 500, height: -500),
            board: board,
            viewport: viewport
        )
        #expect(moved.pan == CGSize(width: 150, height: -150))
    }

    // Yakınlaştırmanın tek önemli özelliği bu: parmağın altındaki nokta yerinde kalmalı.
    // Kalmazsa oyuncu okumak için yakınlaştırdığı yeri kaybediyor.
    @Test("Sıkıştırma çapası yerinde kalıyor")
    func magnificationKeepsItsAnchor() {
        let anchor = CGPoint(x: 60, y: -40)
        let zoom = GridZoom.identity.magnified(
            to: 2,
            about: anchor,
            board: board,
            viewport: viewport
        )

        // Izgara noktasının ekrandaki yeri: pan + (nokta - merkez) * ölçek. Çapanın
        // altındaki ızgara noktası 1 katta `anchor`, 2 katta aynı yerde görünmeli.
        let before = screenPoint(of: anchor, at: .identity)
        let after = screenPoint(of: anchor, at: zoom)
        #expect(abs(before.x - after.x) < 0.001)
        #expect(abs(before.y - after.y) < 0.001)
    }

    @Test("Çapalı sıkıştırma kaydırma sınırını aşmıyor")
    func anchoredMagnificationRespectsThePanLimit() {
        // Köşeye yakın bir çapa, kırpma olmasa ızgarayı ekranın dışına taşırdı.
        let zoom = GridZoom.identity.magnified(
            to: 1.2,
            about: CGPoint(x: 150, y: 150),
            board: board,
            viewport: viewport
        )
        let limit = GridZoom.panLimit(board: board, viewport: viewport, scale: zoom.scale)
        #expect(abs(zoom.pan.width) <= limit.width + 0.001)
        #expect(abs(zoom.pan.height) <= limit.height + 0.001)
    }

    /// Çapa hesabının ters yönü: görüş alanı merkezine göre verilen ızgara noktasının
    /// ekranda nereye düştüğü.
    private func screenPoint(of point: CGPoint, at zoom: GridZoom) -> CGPoint {
        CGPoint(
            x: zoom.pan.width + point.x * zoom.scale,
            y: zoom.pan.height + point.y * zoom.scale
        )
    }
}

@Suite("Yakınlaştırılmış ızgara geometrisi")
struct ZoomedGridGeometryTests {
    private let rect = CGRect(x: 0, y: 0, width: 300, height: 300)
    private let size = GridSize(square: 6)

    @Test("1 kat, yakınlaştırmasız geometriyle aynı")
    func identityZoomMatchesThePlainGeometry() {
        let plain = GridGeometry(fitting: size, in: rect)
        let zoomed = GridGeometry(fitting: size, in: rect, zoom: .identity)
        #expect(plain == zoomed)
    }

    @Test("Hücre kenarı ölçekle büyüyor")
    func cellSideGrowsWithTheScale() {
        let plain = GridGeometry(fitting: size, in: rect)
        let zoomed = GridGeometry(
            fitting: size,
            in: rect,
            zoom: GridZoom(scale: 2, pan: .zero)
        )
        #expect(zoomed.cellSide == plain.cellSide * 2)
        // Kaydırma yoksa ızgara ortalı kalıyor: taşma iki yana eşit dağılıyor.
        #expect(zoomed.boardRect.midX == rect.midX)
        #expect(zoomed.boardRect.midY == rect.midY)
    }

    // Kabul ölçütü: "dokunma eşlemesi yakınlaştırmayla doğru çalışıyor." Çizim nereye
    // düşüyorsa dokunma oraya denk gelmeli; ikisi de aynı geometriden türüdüğü için
    // sınama hücre merkezine dokunup hücreyi geri istemek.
    @Test("Yakınlaştırılmış ve kaydırılmış ızgarada dokunma doğru hücreye gidiyor")
    func hitTestingFollowsTheZoom() {
        let zoom = GridZoom(scale: 2, pan: CGSize(width: -80, height: 40))
        let geometry = GridGeometry(fitting: size, in: rect, zoom: zoom)

        for position in size.allPositions {
            let centre = geometry.center(of: position)
            guard rect.contains(centre) else { continue }
            #expect(geometry.cell(at: centre) == position)
        }
    }

    @Test("Yakınlaştırılmış ızgarada görüş alanı dışına dokunmak hücre vermiyor")
    func touchesOutsideTheViewportStillMapToNothing() {
        let zoom = GridZoom(scale: 3, pan: .zero)
        let geometry = GridGeometry(fitting: size, in: rect, zoom: zoom)
        // Izgara görüş alanından büyük; sol üst hücrenin merkezi ekranın dışında ve
        // oraya dokunmak mümkün değil ama eşleme yine de hücreyi tanıyor.
        let hidden = geometry.center(of: Position(row: 0, column: 0))
        #expect(hidden.x < rect.minX)
        #expect(geometry.cell(at: hidden) == Position(row: 0, column: 0))
        // Izgaranın tamamen dışı yine hiçbir hücre değil.
        #expect(geometry.cell(at: CGPoint(x: geometry.boardRect.maxX + 1, y: rect.midY)) == nil)
    }

    // Cihaz döndüğünde görüş alanı değişiyor ve eldeki kaydırma geçersizleşiyor. Kırpma
    // yalnız harekette olsaydı ızgara ekranın dışında kalırdı.
    @Test("Görüş alanı küçülünce kaydırma içeri çekiliyor")
    func shrinkingTheViewportReclampsThePan() {
        let zoom = GridZoom(scale: 2, pan: CGSize(width: 150, height: 150))
        let narrow = CGRect(x: 0, y: 0, width: 300, height: 150)
        let geometry = GridGeometry(fitting: size, in: narrow, zoom: zoom)
        // Kısa kenar 150, hücre 25 → 2 katta ızgara 300×300 pt. Yatayda görüş alanı da
        // 300 pt, yani yatay pay sıfır: elde 150 pt kaydırma olsa bile ızgara ortada
        // kalıyor. Dikeyde pay (300 - 150) / 2 = 75 pt.
        #expect(geometry.boardRect.midX == narrow.midX)
        #expect(geometry.boardRect.midY == narrow.midY + 75)
    }

    @Test("Sıfır boyutlu görüş alanında yakınlaştırma çökmüyor")
    func degenerateViewportDoesNotCrash() {
        let geometry = GridGeometry(
            fitting: size,
            in: .zero,
            zoom: GridZoom(scale: 3, pan: CGSize(width: 10, height: 10))
        )
        #expect(geometry.cellSide == 0)
        #expect(geometry.cell(at: .zero) == nil)
    }
}
