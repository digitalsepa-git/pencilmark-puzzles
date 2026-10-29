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

    @State private var preferences = Preferences()
    @State private var limits = PlayLimits()
    @State private var store = StoreService()
    @State private var prefetcher = PuzzlePrefetcher()

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .environment(preferences)
                .environment(limits)
                .environment(store)
                .environment(prefetcher)
                .task {
                    // Yetkinin tek kaynağı StoreKit; kota katmanı onu burada alıyor
                    // (ADR 0021'in bıraktığı dikiş).
                    store.onTierChange = { limits.update(tier: $0) }
                    store.start()
                }
                // Tema uygulamanın tamamına burada uygulanıyor; `nil` sistemin
                // kararına bırakıyor.
                .preferredColorScheme(preferences.theme.colorScheme)
        }
        .modelContainer(container)
    }
}
