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

    @State private var preferences: Preferences

    /// Kayıtlı dil ilk gövdeden **önce** uygulanıyor: `localized()` ilk çizimde de
    /// doğru paketten okusun (ADR 0026).
    init() {
        let preferences = Preferences()
        AppLanguage.apply(preferences.language)
        _preferences = State(initialValue: preferences)
    }
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
                // SwiftUI metin değişmezleri ve biçimlendiriciler ortamdaki `locale`'i
                // izliyor; kodda kurulan metinler ise paketi (ADR 0026). İkisi burada
                // aynı seçime bağlanıyor.
                .environment(\.locale, preferences.language.locale)
                // Ortam `locale`'i değişince SwiftUI yalnız metin **değişmezlerini**
                // yeniden çözüyor; gövdeyi yeniden çalıştırmıyor. `localized()` ile
                // kurulan dizgiler gövdede hesaplandığı için eski dilde kalırdı. Kimlik
                // dile bağlanınca ağaç baştan kuruluyor: dil değişimi nadir, bedeli
                // gezinme yığınının köke dönmesi (yarım oyun zaten kayıtlı, ADR 0018).
                .id(preferences.language)
                // Seçimi uygulayan tek yer burası; `Preferences` yalnız saklıyor.
                .onChange(of: preferences.language) { _, language in
                    AppLanguage.apply(language)
                }
        }
        .modelContainer(container)
    }
}
