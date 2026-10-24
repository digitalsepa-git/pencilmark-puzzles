import Foundation
import SwiftUI

/// Bulmaca ekranının süre sayacı.
///
/// Geçen süre saniye sayarak değil **iki an arasındaki fark** olarak tutuluyor: sayaç
/// tikleri kaçarsa (uygulama arka planda, cihaz meşgul) sayılan süre gerçek süreden sapar.
/// Tik yalnız ekrandaki yazıyı tazelemek için.
///
/// Arka plana alınınca duruyor, dönünce devam ediyor — oyuncu uygulamayı kapatıp bir saat
/// sonra açtığında "en iyi süre"nin bir saat olması anlamsız.
@MainActor
@Observable
final class PuzzleTimer {
    private var accumulated: TimeInterval = 0
    private var startedAt: Date?
    private var ticker: Task<Void, Never>?

    /// Ekranda gösterilen saniye. Tik bunu tazeliyor.
    private(set) var seconds = 0

    var isRunning: Bool { startedAt != nil }

    var elapsed: TimeInterval {
        guard let startedAt else { return accumulated }
        return accumulated + Date().timeIntervalSince(startedAt)
    }

    func start() {
        guard startedAt == nil else { return }
        startedAt = Date()
        seconds = Int(elapsed)
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.seconds = Int(self.elapsed)
            }
        }
    }

    func pause() {
        guard let startedAt else { return }
        accumulated += Date().timeIntervalSince(startedAt)
        self.startedAt = nil
        ticker?.cancel()
        ticker = nil
        seconds = Int(accumulated)
    }

    /// Saklanan süreyi geri yüklüyor; devam eden oyun sıfırdan saymıyor.
    func restore(seconds: Int) {
        accumulated = TimeInterval(seconds)
        self.seconds = seconds
    }

    func stop() {
        pause()
    }

    /// Dakika:saniye. Bir saati aşan bulmacalar için saat de gösteriliyor.
    static func format(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let rest = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, rest)
        }
        return String(format: "%d:%02d", minutes, rest)
    }
}
