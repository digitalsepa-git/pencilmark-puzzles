import Testing
import Foundation
import SwiftUI
@testable import Pencilmark

/// İkon PNG'lerini üretiyor.
///
/// Yalnız `ICON_RECORD` derleme koşuluyla yazıyor — anlık görüntü harness'ıyla aynı
/// gerekçe (ADR 0004): normal bir test koşusu varlıkları sessizce değiştiremez.
@Suite("Uygulama ikonu")
@MainActor
struct AppIconRecordingTests {
    private static var isRecording: Bool {
        #if ICON_RECORD
        true
        #else
        false
        #endif
    }

    private var destination: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/Assets.xcassets/AppIcon.appiconset")
    }

    @Test("İkon üç görünümde de çiziliyor")
    func iconRendersInEveryAppearance() throws {
        for (appearance, name) in [
            (AppIconArtwork.Appearance.light, "icon-light"),
            (.dark, "icon-dark"),
            (.tinted, "icon-tinted")
        ] {
            let renderer = ImageRenderer(
                content: AppIconArtwork(appearance: appearance, side: 1_024)
            )
            renderer.scale = 1
            let image = try #require(renderer.uiImage)
            #expect(image.size.width == 1_024)

            let data = try #require(image.pngData())
            if Self.isRecording {
                try FileManager.default.createDirectory(
                    at: destination, withIntermediateDirectories: true
                )
                try data.write(to: destination.appendingPathComponent("\(name).png"))
            }
        }
    }

    // Üç görünüm birbirinden farklı olmak zorunda: tonlu ikon tek renkli ve sistem
    // renklendiriyor, karanlık ikon kendi zeminini taşıyor.
    @Test("Üç görünüm birbirinden farklı")
    func appearancesDiffer() throws {
        func render(_ appearance: AppIconArtwork.Appearance) throws -> UIImage {
            let renderer = ImageRenderer(content: AppIconArtwork(appearance: appearance, side: 256))
            renderer.scale = 1
            return try #require(renderer.uiImage)
        }

        let light = try render(.light)
        let dark = try render(.dark)
        let tinted = try render(.tinted)

        #expect(SnapshotHarness.compare(light, dark).ratio > 0.5)
        #expect(SnapshotHarness.compare(dark, tinted).ratio > 0.1)
    }
}
