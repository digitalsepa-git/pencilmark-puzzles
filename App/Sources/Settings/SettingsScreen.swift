import SwiftUI

/// Ayarlar (brief b.7, ekran 5).
///
/// "Satın alma geri yükleme" burada yok: ortada satın alma yok ve Apple'ın zorunlu
/// tuttuğu şey satın alması olan uygulamalar için. StoreKit işiyle birlikte gelecek.
struct SettingsScreen: View {
    @Environment(Preferences.self) private var preferences

    var body: some View {
        @Bindable var preferences = preferences

        Form {
            Section {
                Picker("Theme", selection: $preferences.theme) {
                    ForEach(Preferences.Theme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            } footer: {
                Text("System follows your device setting.")
            }

            Section {
                Toggle("Haptic feedback", isOn: $preferences.isHapticsEnabled)
            } footer: {
                Text("A short tap when a puzzle is solved, or when a wrong entry is caught.")
            }

            Section {
                Toggle("Check as you go", isOn: $preferences.usesImmediateErrorChecking)
            } footer: {
                // Brief b.7: iki kip var ve varsayılan manuel. Açıklama hangi kipte
                // olduğunu anlatıyor; "kapalı" kelimesi tek başına ne olduğunu söylemiyor.
                Text(
                    preferences.usesImmediateErrorChecking
                        ? "Wrong entries turn red as soon as you make them."
                        : "Wrong entries stay hidden until you tap Check."
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
