// swift-tools-version: 6.0
import PackageDescription

// PuzzleKit arayüzden tamamen bağımsız (brief b.9): UIKit/SwiftUI/Foundation bağımlılığı yok.
// Foundation'dan da kaçınıyoruz — tarih/saat dilimi politikası uygulama katmanına ait,
// motor yalnızca sayılarla çalışır. Bu sayede testler Linux'ta da koşar (ucuz CI).
let package = Package(
    name: "PuzzleKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PuzzleKit", targets: ["PuzzleKit"]),
        .library(name: "GameCore", targets: ["GameCore"])
    ],
    targets: [
        .target(
            name: "PuzzleKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // GameCore ayrı bir paket değil, aynı paketin ikinci hedefi (ADR 0015). Sebebi
        // ölçülebilir: ayrı paket olsa aralarında bir yol bağımlılığı doğar, CI'daki
        // bağımlılık kapısı tek grep olmaktan çıkar ve oyun oturumu mantığı Linux'ta
        // 1x maliyetle koşamaz hale gelme riski taşır. GameCore de arayüze bağlı değil.
        .target(
            name: "GameCore",
            dependencies: ["PuzzleKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "PuzzleKitTests",
            dependencies: ["PuzzleKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
