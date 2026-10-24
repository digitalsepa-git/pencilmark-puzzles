import SwiftUI

/// Yakınlaştırma ve kaydırma hareketlerini bir ızgara görünümüne bağlıyor.
///
/// Beş varyantın beşinde de aynı: sıkıştırma ölçeği, sürükleme ızgarayı taşıyor. Hareket
/// mantığı burada tek yerde duruyor; `GridZoom` hesabı yapıyor, bu değiştirici yalnız
/// hareketi hesaba çeviriyor.
///
/// Tek parmak sürüklemesi yalnız **yakınlaştırılmışken** kaydırmaya dönüşüyor. 1 katta
/// hareket hiç kurulmuyor: varsayılan durumda dokunma davranışı bugünküyle birebir aynı
/// kalıyor ve gezinme çubuğunun geri kaydırması da bozulmuyor.
struct GridZoomGestures: ViewModifier {
    @Binding var zoom: GridZoom
    /// Izgaranın 1 kattaki ekran boyu; kaydırma sınırı buradan çıkıyor.
    let board: CGSize
    let viewport: CGSize
    /// Sürükleme kaydırma sayılıyor mu? Hashi'de köprü de sürüklemeyle kuruluyor ve o
    /// varyant kararı kendi hareketinin içinde, sürüklemenin başladığı yere bakarak
    /// veriyor.
    var pansWithDrag = true

    @State private var start: GridZoom?

    func body(content: Content) -> some View {
        content
            // `simultaneousGesture`: sıkıştırma iki parmak, ızgaranın kendi dokunma ve
            // sürükleme hareketleriyle yarışmıyor.
            .simultaneousGesture(magnify)
            .gesture(drag, including: isPanEnabled ? .all : .subviews)
    }

    private var isPanEnabled: Bool { pansWithDrag && zoom.scale > GridZoom.minimumScale }

    private var magnify: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                let base = start ?? zoom
                if start == nil { start = base }
                zoom = base.magnified(
                    to: base.scale * value.magnification,
                    about: GridZoomGestures.anchor(value.startAnchor, in: viewport),
                    board: board,
                    viewport: viewport
                )
            }
            .onEnded { _ in start = nil }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let base = start ?? zoom
                if start == nil { start = base }
                zoom = base.panned(
                    by: value.translation,
                    board: board,
                    viewport: viewport
                )
            }
            .onEnded { _ in start = nil }
    }

    /// `UnitPoint` biçimindeki çapayı görüş alanının merkezine göre noktaya çeviriyor;
    /// `GridZoom` çapayı böyle bekliyor.
    static func anchor(_ unit: UnitPoint, in viewport: CGSize) -> CGPoint {
        CGPoint(
            x: (unit.x - 0.5) * viewport.width,
            y: (unit.y - 0.5) * viewport.height
        )
    }
}

extension View {
    func gridZoomGestures(
        _ zoom: Binding<GridZoom>,
        board: CGSize,
        viewport: CGSize,
        pansWithDrag: Bool = true
    ) -> some View {
        modifier(
            GridZoomGestures(
                zoom: zoom,
                board: board,
                viewport: viewport,
                pansWithDrag: pansWithDrag
            )
        )
    }
}
