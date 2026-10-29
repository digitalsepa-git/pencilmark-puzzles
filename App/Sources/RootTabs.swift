import SwiftUI

/// Uygulamanın kök gezinmesi: alt sekme çubuğu.
///
/// Üç sekme, çünkü brief b.7'nin beş ekranı üç dala ayrılıyor: oynanacak bulmacalar,
/// ilerleme, ayarlar. Zorluk seçimi ve bulmaca ekranı ilk sekmenin yığınında; geçmiş ve
/// eğilim ikincinin yığınında.
///
/// Ayarlar ve istatistik daha önce ana ekranın üst araç çubuğunda ikon olarak duruyordu.
/// İkisi de bir ekranın aracı değil, uygulamanın ayrı bölümü; iOS'un bu iş için verdiği
/// desen sekme çubuğu (ADR 0024).
///
/// `NavigationStack` her sekmenin **içinde**: sekme değiştirince yığın bozulmuyor,
/// oyuncu bulmacanın yarısından istatistiğe bakıp geri dönebiliyor. Tersi — tek yığının
/// içinde sekme çubuğu — sekmelerin geçmişini paylaştırır.
struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Label("Puzzles", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                StatsScreen()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar")
            }

            NavigationStack {
                SettingsScreen()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    RootTabs()
}
