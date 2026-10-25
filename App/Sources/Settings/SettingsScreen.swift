import GameCore
import SwiftData
import SwiftUI

/// Ayarlar (brief b.7, ekran 5).
struct SettingsScreen: View {
    @Environment(Preferences.self) private var preferences
    @Environment(PlayLimits.self) private var limits
    @Environment(StoreService.self) private var store
    @Environment(\.modelContext) private var modelContext

    @State private var solvedPuzzles = 0
    @State private var isShowingPaywall = false
    @State private var restoreMessage: String?

    var body: some View {
        @Bindable var preferences = preferences

        Form {
            plusSection

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

            Section {
                Button("Show tutorials again") {
                    preferences.resetTutorials()
                }
            } footer: {
                // ADR 0009: öğretici ayarlardan da yeniden oynanabiliyor. Buradaki
                // düğme hepsini birden geri açıyor; tek bir varyantı tekrar oynamak
                // zorluk ekranındaki "How to play" satırıyla.
                Text(
                    preferences.seenTutorials.isEmpty
                        ? "Tutorials will start the first time you open each puzzle."
                        : "Each puzzle will show its tutorial again the next time you open it."
                )
            }

            Section {
                NavigationLink("Privacy Policy") {
                    PrivacyScreen()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            solvedPuzzles = (try? RecordStore(context: modelContext).solvedCount()) ?? 0
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallScreen(store: store) { isShowingPaywall = false }
        }
        .alert(
            restoreMessage ?? "",
            isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )
        ) {
            Button("OK") { restoreMessage = nil }
        }
    }

    /// Satın alma bölümü.
    ///
    /// "Restore purchases" her zaman görünüyor: Apple satın alması olan uygulamalarda
    /// bunu zorunlu tutuyor ve geri yükleme bir teklif değil, zaten ödemiş olan birinin
    /// hakkı.
    ///
    /// Yükseltme satırı ise paywall eşiğine bağlı (brief b.8: "Paywall, kullanıcı en az
    /// 3 bulmaca bitirmeden gösterilmez"). Kuralı harfiyen uyguluyoruz: eşiğin altında
    /// satın almaya giden hiçbir yol yok. Maliyeti, ilk gün ödemek isteyen oyuncunun
    /// bekliyor olması; brief bu kararı bilerek vermiş.
    @ViewBuilder
    private var plusSection: some View {
        Section {
            if limits.allowance.isUnlimited {
                LabeledContent("Pencilmark Plus", value: String(localized: "Active"))
            } else if PaywallPolicy.canShow(solvedPuzzles: solvedPuzzles) {
                Button("Pencilmark Plus") { isShowingPaywall = true }
            }

            Button("Restore purchases") {
                Task {
                    let outcome = await store.restore()
                    switch outcome {
                    case .purchased:
                        restoreMessage = String(localized: "Pencilmark Plus is active.")
                    case .failed(let reason):
                        restoreMessage = reason
                    case .cancelled, .pending:
                        break
                    }
                }
            }
            .disabled(store.isWorking)
        } footer: {
            Text(
                limits.allowance.isUnlimited
                    ? "Thank you. Every difficulty and every puzzle is unlocked."
                    : "Already bought Plus on another device? Restore brings it back."
            )
        }
    }
}
