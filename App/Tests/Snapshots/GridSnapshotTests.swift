import Testing
import SwiftUI
import PuzzleKit
@testable import Pencilmark

/// Brief b.11'in istediği anlık görüntü testleri: ızgara çizimi, karanlık mod, Dynamic Type.
///
/// Yalnız sabitlenmiş çalışma zamanında koşuyorlar (ADR 0016). Başka sürümde **atlanıyorlar**,
/// sessizce geçmiyorlar: piksel karşılaştırması çalışma zamanına bağlı ve 18.2'de üretilen
/// bir referans 18.6'da tutmuyor.
@Suite("Anlık görüntüler", .enabled(if: SnapshotHarness.isPinnedRuntime))
@MainActor
struct GridSnapshotTests {
    private let gridSize = CGSize(width: 320, height: 320)

    private func check(_ outcome: SnapshotHarness.Outcome) {
        switch outcome {
        case .matched, .recorded:
            break
        case .missingReference(let name):
            Issue.record("Referans yok: \(name). SNAPSHOT_RECORD=1 ile üretilmeli.")
        case .differed(let name, let ratio, let path):
            Issue.record("\(name) referanstan farklı (%\(ratio * 100)). Fark görüntüsü: \(path)")
        case .renderFailed:
            Issue.record("Çizim başarısız")
        }
    }

    private func snapshot(
        _ view: some View,
        _ name: String,
        size: CGSize? = nil,
        dynamicTypeSize: DynamicTypeSize = .large
    ) {
        for scheme in [ColorScheme.light, .dark] {
            let image = SnapshotHarness.render(
                view,
                size: size ?? gridSize,
                colorScheme: scheme,
                dynamicTypeSize: dynamicTypeSize
            )
            check(SnapshotHarness.verify(image, named: "\(name)-\(scheme == .light ? "light" : "dark")"))
        }
    }

    @Test("Kakuro ızgarası")
    func kakuroGrid() {
        let fixture = SnapshotFixtures.kakuro()
        snapshot(
            KakuroGridView(
                puzzle: fixture.puzzle,
                board: fixture.board,
                selection: Position(row: 2, column: 2),
                mistakes: [Position(row: 3, column: 3)]
            ),
            "kakuro"
        )
    }

    @Test("Calcudoku ızgarası")
    func calcudokuGrid() {
        let fixture = SnapshotFixtures.calcudoku()
        snapshot(
            CalcudokuGridView(
                puzzle: fixture.puzzle,
                board: fixture.board,
                selection: Position(row: 1, column: 1)
            ),
            "calcudoku"
        )
    }

    @Test("Hitori ızgarası")
    func hitoriGrid() {
        let fixture = SnapshotFixtures.hitori()
        snapshot(
            HitoriGridView(puzzle: fixture.puzzle, board: fixture.board),
            "hitori"
        )
    }

    @Test("Slitherlink ızgarası")
    func slitherlinkGrid() {
        let fixture = SnapshotFixtures.slitherlink()
        snapshot(
            SlitherlinkGridView(puzzle: fixture.puzzle, board: fixture.board),
            "slitherlink"
        )
    }

    @Test("Hashi ızgarası")
    func hashiGrid() {
        let fixture = SnapshotFixtures.hashi()
        snapshot(
            HashiGridView(puzzle: fixture.puzzle, board: fixture.board),
            "hashi"
        )
    }

    // Izgaradaki rakamlar Dynamic Type ile değil hücreyle büyüyor (ADR 0015 kapsamı
    // dışında, `GridStyle`'da gerekçesi var), bu yüzden Dynamic Type referansı ızgaranın
    // değil kartın: büyüyen şey orası.
    @Test("Varyant kartı")
    func variantCard() {
        snapshot(
            VariantCard(variant: .kakuro),
            "variant-card",
            size: CGSize(width: 320, height: 110)
        )
    }

    @Test("Varyant kartı — büyük Dynamic Type")
    func variantCardAtLargeDynamicType() {
        snapshot(
            VariantCard(variant: .calcudoku),
            "variant-card-xl",
            size: CGSize(width: 320, height: 220),
            dynamicTypeSize: .accessibility1
        )
    }
}
