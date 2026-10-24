import Testing
import Foundation
import SwiftUI
import GameCore
@testable import Pencilmark

@Suite("Tercihler")
@MainActor
struct PreferencesTests {
    private func defaults(_ name: String = UUID().uuidString) throws -> UserDefaults {
        try #require(UserDefaults(suiteName: name))
    }

    @Test("Varsayılanlar")
    func defaultValues() throws {
        let preferences = Preferences(defaults: try defaults())
        #expect(preferences.theme == .system)
        // Dokunsal geri bildirim varsayılan açık; `bool(forKey:)` kayıt yokken false
        // döndüğü için okuma `object(forKey:)` ile yapılıyor.
        #expect(preferences.isHapticsEnabled)
        // Brief b.7: hata kontrolü varsayılan manuel.
        #expect(!preferences.usesImmediateErrorChecking)
        #expect(preferences.errorChecking == .manual)
    }

    @Test("Tercihler saklanıyor ve geri okunuyor")
    func preferencesPersist() throws {
        let suite = UUID().uuidString
        let store = try defaults(suite)

        let first = Preferences(defaults: store)
        first.theme = .dark
        first.isHapticsEnabled = false
        first.usesImmediateErrorChecking = true

        let second = Preferences(defaults: store)
        #expect(second.theme == .dark)
        #expect(!second.isHapticsEnabled)
        #expect(second.usesImmediateErrorChecking)
        #expect(second.errorChecking == .immediate)
    }

    @Test("Tanınmayan tema değeri sisteme düşüyor")
    func unknownThemeFallsBackToSystem() throws {
        let suite = UUID().uuidString
        let store = try defaults(suite)
        store.set("boyle-bir-tema-yok", forKey: "tercih.tema")

        #expect(Preferences(defaults: store).theme == .system)
    }

    @Test("Tema renk şemasına çevriliyor")
    func themeMapsToColorScheme() {
        #expect(Preferences.Theme.system.colorScheme == nil)
        #expect(Preferences.Theme.light.colorScheme == .light)
        #expect(Preferences.Theme.dark.colorScheme == .dark)
    }

    @Test("Üç tema da seçilebilir")
    func allThemesAreSelectable() {
        #expect(Preferences.Theme.allCases.count == 3)
        #expect(Preferences.Theme.allCases.allSatisfy { !$0.displayName.isEmpty })
    }
}
