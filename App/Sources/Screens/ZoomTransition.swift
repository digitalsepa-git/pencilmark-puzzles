import SwiftUI

/// Satırdan tahtaya büyüyen geçiş (ADR 0027).
///
/// iOS 18'in `zoom` geçişi: dokunulan satır büyüyüp açılan ekrana dönüşüyor, oyuncu
/// nereden nereye gittiğini görüyor. Asgari sürümümüz iOS 17 (ADR 0002), orada normal
/// push kalıyor — geçiş bir süs değil ama olmayınca da hiçbir şey bozulmuyor.
///
/// İki sarmalayıcının sebebi `if #available`'ın görünüm değiştiricilerinde doğrudan
/// yazılamaması.
extension View {
    /// Büyüyecek olan şey: liste satırı.
    @ViewBuilder
    func zoomSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Büyüyüp varacağı yer: açılan ekran.
    @ViewBuilder
    func zoomDestination(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
