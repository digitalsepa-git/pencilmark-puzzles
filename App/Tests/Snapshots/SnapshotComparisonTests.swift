import Testing
import SwiftUI
import UIKit
import PuzzleKit
@testable import Pencilmark

/// Harness'ın kendi testleri. Bunlar referans görüntüye bağlı değil, bu yüzden **her**
/// çalışma zamanında koşuyorlar: karşılaştırıcı bozulursa anlık görüntü testleri sessizce
/// yeşile döner ve kimse fark etmez.
@Suite("Anlık görüntü karşılaştırıcısı")
@MainActor
struct SnapshotComparisonTests {
    private func solid(_ color: UIColor, size: CGSize = CGSize(width: 20, height: 20)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func halves(_ left: UIColor, _ right: UIColor) -> UIImage {
        let size = CGSize(width: 20, height: 20)
        return UIGraphicsImageRenderer(size: size).image { context in
            left.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 20))
            right.setFill()
            context.fill(CGRect(x: 10, y: 0, width: 10, height: 20))
        }
    }

    @Test("Aynı görüntüde fark yok")
    func identicalImagesHaveNoDifference() {
        let image = solid(.black)
        #expect(SnapshotHarness.compare(image, image).ratio == 0)
    }

    @Test("Tamamen farklı görüntüde oran 1")
    func oppositeImagesDifferCompletely() {
        let ratio = SnapshotHarness.compare(solid(.black), solid(.white)).ratio
        #expect(ratio == 1)
    }

    @Test("Yarısı farklı görüntüde oran yarım")
    func halfDifferentImagesReportHalf() {
        let ratio = SnapshotHarness.compare(
            halves(.black, .white),
            solid(.black)
        ).ratio
        #expect(abs(ratio - 0.5) < 0.01)
    }

    // Pay, kenar yumuşatmasındaki tek birimlik oynamalar için; bu testin işi payın gerçek
    // bir farkı yutacak kadar büyümesini engellemek.
    @Test("Tolerans altındaki sapma fark sayılmıyor")
    func differencesBelowToleranceAreIgnored() {
        let base = UIColor(white: 0.5, alpha: 1)
        let nudged = UIColor(white: 0.5 + 2.0 / 255.0, alpha: 1)
        #expect(SnapshotHarness.compare(solid(base), solid(nudged)).ratio == 0)
    }

    @Test("Tolerans üstündeki sapma fark sayılıyor")
    func differencesAboveToleranceAreCounted() {
        let base = UIColor(white: 0.5, alpha: 1)
        let shifted = UIColor(white: 0.5 + 40.0 / 255.0, alpha: 1)
        #expect(SnapshotHarness.compare(solid(base), solid(shifted)).ratio == 1)
    }

    @Test("Boyut değişimi fark olarak görünüyor")
    func sizeChangesShowUpAsDifference() {
        let small = solid(.black, size: CGSize(width: 10, height: 20))
        let large = solid(.black, size: CGSize(width: 20, height: 20))
        #expect(SnapshotHarness.compare(small, large).ratio > 0)
    }

    @Test("Eksik referans sessizce geçmiyor")
    func missingReferenceIsReported() {
        let image = solid(.black)
        let outcome = SnapshotHarness.verify(image, named: "boyle-bir-referans-yok")
        #expect(outcome == .missingReference(name: "boyle-bir-referans-yok"))
    }

    // Renkler `UIColor`'ın dinamik sağlayıcısıyla tanımlı (bkz. `Theme.swift`). Bu testin
    // işi, `colorScheme` ortam değerinin o sağlayıcıya gerçekten ulaştığını doğrulamak —
    // ulaşmasaydı karanlık mod referansları açık modunkiyle aynı olur ve testler hiçbir
    // şey korumazdı.
    @Test("Karanlık mod çizimi açık moddan farklı")
    func darkModeRendersDifferently() {
        let size = CGSize(width: 200, height: 90)
        let view = VariantCard(variant: .kakuro)
        let light = SnapshotHarness.render(view, size: size, colorScheme: .light)
        let dark = SnapshotHarness.render(view, size: size, colorScheme: .dark)

        let lightImage = try? #require(light)
        let darkImage = try? #require(dark)
        guard let lightImage, let darkImage else { return }
        #expect(SnapshotHarness.compare(lightImage, darkImage).ratio > 0.5)
    }

    @Test("Dynamic Type çizimi değiştiriyor")
    func dynamicTypeChangesTheRendering() {
        let size = CGSize(width: 240, height: 200)
        let view = VariantCard(variant: .kakuro)
        let standard = SnapshotHarness.render(
            view, size: size, colorScheme: .light, dynamicTypeSize: .large
        )
        let enlarged = SnapshotHarness.render(
            view, size: size, colorScheme: .light, dynamicTypeSize: .accessibility1
        )

        guard let standard, let enlarged else {
            Issue.record("Çizim başarısız")
            return
        }
        #expect(SnapshotHarness.compare(standard, enlarged).ratio > SnapshotHarness.allowedPixelRatio)
    }
}

/// Zeminin de temaya uyduğunu ayrıca koruyan test.
///
/// İlk kayıt koşusunda `.background` ortam değiştiricilerinin dışında kalmıştı: kart koyu,
/// zemin açık çıkıyordu. "Karanlık mod farklı" testi bunu yakalayamadı, çünkü kart yine de
/// değişiyordu.
@Suite("Anlık görüntü zemini")
@MainActor
struct SnapshotBackgroundTests {
    @Test("Zemin de karanlık modu görüyor")
    func backgroundFollowsTheColorScheme() throws {
        let size = CGSize(width: 40, height: 40)
        // İçeriği olmayan bir görünüm: geriye yalnız harness'ın koyduğu zemin kalıyor.
        let light = SnapshotHarness.render(Color.clear, size: size, colorScheme: .light)
        let dark = SnapshotHarness.render(Color.clear, size: size, colorScheme: .dark)

        let lightImage = try #require(light)
        let darkImage = try #require(dark)
        #expect(SnapshotHarness.compare(lightImage, darkImage).ratio == 1)
    }
}
