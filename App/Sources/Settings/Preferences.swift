import Foundation
import GameCore
import SwiftUI

/// Kullanıcı tercihleri.
///
/// `UserDefaults`'ta, SwiftData'da değil. Üçü de tek değer ve aralarında ilişki yok;
/// SwiftData'ya koymak bir şema, bir göç yolu ve bir sorgu katmanı getirirdi — hiçbirinin
/// karşılığı olmadan. Oyun verisi (ADR 0017) ayrı yerde kalmaya devam ediyor.
@MainActor
@Observable
final class Preferences {
    enum Theme: String, CaseIterable, Identifiable, Sendable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }

        /// `nil` sistemin kararına bırakıyor.
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    private enum Key {
        static let theme = "tercih.tema"
        static let haptics = "tercih.dokunsal"
        static let immediateErrors = "tercih.anlikHataKontrolu"
    }

    private let defaults: UserDefaults

    var theme: Theme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    var isHapticsEnabled: Bool {
        didSet { defaults.set(isHapticsEnabled, forKey: Key.haptics) }
    }

    /// Brief b.7: hata kontrolü iki modda, **varsayılan manuel**.
    var usesImmediateErrorChecking: Bool {
        didSet { defaults.set(usesImmediateErrorChecking, forKey: Key.immediateErrors) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.theme = Theme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .system
        // `object(forKey:)` ile okunuyor: `bool(forKey:)` kayıt yokken false döner ve
        // dokunsal geri bildirimin varsayılanı açık olmalı.
        self.isHapticsEnabled = defaults.object(forKey: Key.haptics) as? Bool ?? true
        self.usesImmediateErrorChecking = defaults.bool(forKey: Key.immediateErrors)
    }

    var errorChecking: ErrorChecking {
        usesImmediateErrorChecking ? .immediate : .manual
    }
}
