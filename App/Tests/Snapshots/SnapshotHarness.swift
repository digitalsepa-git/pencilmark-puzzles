import Foundation
import SwiftUI
import UIKit
@testable import Pencilmark

/// Kendi anlık görüntü harness'ımız (ADR 0004).
///
/// `swift-snapshot-testing` olgun ve bakımlı ama bir SPM bağımlılığı; ADR 0004 sıfır
/// bağımlılık kuralını test hedeflerine de genişletirken gerekçesini "bakım ve denetim
/// yüzeyi" diye koymuştu. Karşılığı bu dosya: yaklaşık 150 satır ve bakımı bizde.
enum SnapshotHarness {
    /// Referansların üretildiği ve karşılaştırmanın yapıldığı tek yapılandırma (ADR 0016).
    ///
    /// Piksel karşılaştırması çalışma zamanına bağlı: aynı görünüm iOS 18.2 ile 18.6'da
    /// farklı piksellere dönüşüyor. Bu yüzden referanslar tek bir sürümde üretiliyor ve
    /// başka sürümde testler **atlanıyor**, sessizce geçmiyor.
    static let pinnedRuntime = (major: 18, minor: 6)

    /// Çizim ölçeği cihazdan bağımsız sabit: simülatörün ekran ölçeği değişse de referans
    /// aynı kalıyor.
    static let scale: CGFloat = 2

    /// Farklı sayılması için bir kanalın en az bu kadar sapması gerekiyor. Aynı çalışma
    /// zamanında render iki koşuda birebir aynı çıkıyor; pay, kenar yumuşatmasındaki
    /// tek birimlik oynamalar için.
    static let channelTolerance = 8
    /// İzin verilen farklı piksel oranı. Bir hücrenin kayması bunun çok üstünde fark
    /// üretiyor, yani gerçek bir regresyon bu payın altında saklanamıyor.
    static let allowedPixelRatio = 0.002

    static var isPinnedRuntime: Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return version.majorVersion == pinnedRuntime.major
            && version.minorVersion == pinnedRuntime.minor
    }

    /// Referans üretme yalnız açık bayrakla (ADR 0004).
    ///
    /// Bayrak ortam değişkeni değil **derleme koşulu**. İlk sürüm ortam değişkeniydi ve
    /// işlemedi: `xcodebuild`'e verilen değişken test sürecine ulaşmıyor (`TEST_RUNNER_`
    /// öneki de barındırılan birim testlerinde geçmiyor). Derleme koşulu hem işliyor hem
    /// daha güçlü: normal bir koşu kayıt kipine **derlenemiyor** bile, yani referansı
    /// kazara güncelleyen bir çalıştırma mümkün değil.
    static var isRecording: Bool {
        #if SNAPSHOT_RECORD
        true
        #else
        false
        #endif
    }

    static var referenceDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
    }

    /// Farklı çıkan karşılaştırmaların yazıldığı yer; CI bunu artifact olarak yüklüyor.
    static var failureDirectory: URL {
        referenceDirectory.appendingPathComponent("__Failures__")
    }

    @MainActor
    static func render(
        _ view: some View,
        size: CGSize,
        colorScheme: ColorScheme,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: view
                .environment(\.colorScheme, colorScheme)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .frame(width: size.width, height: size.height)
                .background(Color.paper)
        )
        renderer.scale = scale
        return renderer.uiImage
    }

    enum Outcome: Equatable {
        case matched
        case recorded
        case missingReference(name: String)
        case differed(name: String, ratio: Double, diffPath: String)
        case renderFailed
    }

    /// Görüntüyü referansla karşılaştırıyor; kayıt kipinde referansı yazıyor.
    static func verify(_ image: UIImage?, named name: String) -> Outcome {
        guard let image, let data = image.pngData() else { return .renderFailed }

        let reference = referenceDirectory.appendingPathComponent("\(name).png")
        if isRecording {
            try? FileManager.default.createDirectory(
                at: referenceDirectory, withIntermediateDirectories: true
            )
            try? data.write(to: reference)
            return .recorded
        }

        guard let referenceData = try? Data(contentsOf: reference),
              let referenceImage = UIImage(data: referenceData) else {
            return .missingReference(name: name)
        }

        let (ratio, diff) = compare(image, referenceImage)
        guard ratio > allowedPixelRatio else { return .matched }

        let diffURL = failureDirectory.appendingPathComponent("\(name).diff.png")
        try? FileManager.default.createDirectory(
            at: failureDirectory, withIntermediateDirectories: true
        )
        try? diff?.pngData()?.write(to: diffURL)
        try? data.write(to: failureDirectory.appendingPathComponent("\(name).actual.png"))
        return .differed(name: name, ratio: ratio, diffPath: diffURL.path)
    }

    /// Farklı piksel oranı ve farkı kırmızıyla işaretleyen görüntü.
    ///
    /// Karşılaştırma iki görüntüyü de aynı RGBA tamponuna çizerek yapılıyor: `CGImage`'ın
    /// kendi bayt düzeni görüntüden görüntüye değişebiliyor ve ham baytları doğrudan
    /// karşılaştırmak o yüzden güvenilir değil.
    static func compare(_ lhs: UIImage, _ rhs: UIImage) -> (ratio: Double, diff: UIImage?) {
        guard let left = lhs.cgImage, let right = rhs.cgImage else { return (1, nil) }
        let width = max(left.width, right.width)
        let height = max(left.height, right.height)
        guard width > 0, height > 0 else { return (1, nil) }

        guard var leftPixels = pixels(of: left, width: width, height: height),
              let rightPixels = pixels(of: right, width: width, height: height) else {
            return (1, nil)
        }

        var differing = 0
        for index in stride(from: 0, to: leftPixels.count, by: 4) {
            let delta = (0..<4).contains { channel in
                abs(Int(leftPixels[index + channel]) - Int(rightPixels[index + channel]))
                    > channelTolerance
            }
            if delta {
                differing += 1
                leftPixels[index] = 255
                leftPixels[index + 1] = 0
                leftPixels[index + 2] = 0
                leftPixels[index + 3] = 255
            }
        }

        let ratio = Double(differing) / Double(width * height)
        return (ratio, image(from: leftPixels, width: width, height: height))
    }

    /// Boyutları farklıysa görüntü sol üste hizalanıp kalan alan şeffaf kalıyor; böylece
    /// boyut değişimi de fark olarak görünüyor.
    private static func pixels(of image: CGImage, width: Int, height: Int) -> [UInt8]? {
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        let drawn = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: space,
                bitmapInfo: info
            ) else { return false }
            context.draw(
                image,
                in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
            )
            return true
        }
        return drawn ? buffer : nil
    }

    private static func image(from pixels: [UInt8], width: Int, height: Int) -> UIImage? {
        var buffer = pixels
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        return buffer.withUnsafeMutableBytes { raw -> UIImage? in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: space,
                bitmapInfo: info
            ), let cgImage = context.makeImage() else { return nil }
            return UIImage(cgImage: cgImage)
        }
    }
}
