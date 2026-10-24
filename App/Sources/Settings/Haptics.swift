import UIKit

/// Dokunsal geri bildirim.
///
/// Tercihi burada sormuyoruz; çağıran yeri karar veriyor ve kapalıyken hiç çağrılmıyor.
/// Alternatifi her çağrıda tercihi okumaktı ve o, kapalı tercihte bile üreteci kurup
/// hazırlamak demekti.
@MainActor
enum Haptics {
    /// Yanlış giriş. Brief b.7'nin "anlık hata kontrolü" kipinde anlamlı; manuel kipte
    /// oyuncu hatayı kendi isteyince görüyor ve titreşim şaşırtıcı olurdu.
    static func mistake() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func solved() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
