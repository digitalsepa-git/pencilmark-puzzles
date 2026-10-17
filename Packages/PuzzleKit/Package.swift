// swift-tools-version: 6.0
import PackageDescription

// PuzzleKit arayüzden tamamen bağımsız (brief b.9): UIKit/SwiftUI/Foundation bağımlılığı yok.
// Foundation'dan da kaçınıyoruz — tarih/saat dilimi politikası uygulama katmanına ait,
// motor yalnızca sayılarla çalışır. Bu sayede testler Linux'ta da koşar (ucuz CI).
let package = Package(
    name: "PuzzleKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PuzzleKit", targets: ["PuzzleKit"])
    ],
    targets: [
        .target(
            name: "PuzzleKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "PuzzleKitTests",
            dependencies: ["PuzzleKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
