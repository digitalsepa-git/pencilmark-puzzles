import SwiftData
import SwiftUI

@main
struct PencilmarkApp: App {
    /// Kap uygulama başlarken bir kez kuruluyor. Kurulamazsa — disk dolu, şema bozuk —
    /// uygulama bellekte çalışmaya devam ediyor: istatistik kaybolur ama oyun oynanır.
    /// Bulmaca çözmek isteyen birine açılmayan bir uygulama göstermek daha kötü.
    private let container: ModelContainer = {
        do {
            return try AppStorage.container()
        } catch {
            // Bellek içi kap da kurulamıyorsa yapacak bir şey kalmıyor.
            // swiftlint:disable:next force_try
            return try! AppStorage.container(inMemory: true)
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeScreen()
        }
        .modelContainer(container)
    }
}
