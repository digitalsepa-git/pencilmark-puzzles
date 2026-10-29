import SwiftUI
import UIKit

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
///
/// Simgeler çizgi varyantında. Sekme çubuğu varsayılan olarak dolu varyantı uyguluyor ve
/// iOS 26'nın cam çubuğunda dolu simgeler ağır duruyor: cam zaten bir katman, üstüne
/// dolu bir blok koymak ikisini birden kalınlaştırıyor. Çizgi varyantı aynı simgeyi
/// kâğıt-kalem tonuna yaklaştırıyor (brief b.7: sakin ve okunaklı).
struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Label {
                    Text("Puzzles")
                } icon: {
                    Self.icon("square.grid.2x2")
                }
            }

            NavigationStack {
                StatsScreen()
            }
            .tabItem {
                Label {
                    Text("Statistics")
                } icon: {
                    Self.icon("chart.bar")
                }
            }

            NavigationStack {
                SettingsScreen()
            }
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Self.icon("slider.horizontal.3")
                }
            }
        }
    }

    /// Sekme simgesi, ince çizgiyle.
    ///
    /// Kalınlık `.fontWeight` ile verilemiyor: sekme çubuğu simgeyi kendi
    /// yapılandırmasıyla yeniden çiziyor ve SwiftUI'nin yazı tipi ağırlığı oraya
    /// geçmiyor. Simge bu yüzden istenen ağırlıkta üretilip veriliyor. Şablon kipi
    /// korunuyor: seçili sekmenin vurgu rengini çubuk yine kendisi veriyor.
    private static func icon(_ name: String) -> Image {
        let configuration = UIImage.SymbolConfiguration(weight: .light)
        guard let image = UIImage(systemName: name, withConfiguration: configuration) else {
            // Simge adı yanlışsa sistem zaten bir yer tutucu çiziyor; sessiz kalmak
            // sekmeyi boş bırakmaktan iyi.
            return Image(systemName: name)
        }
        return Image(uiImage: image)
    }
}

#Preview {
    RootTabs()
}
