import Foundation
import GameCore
import PuzzleKit
import Testing
@testable import Pencilmark

/// Ana ekrandaki mini önizlemeler (ADR 0027).
///
/// Önizleme `GameSession.revealHint()`'i tekrar tekrar çağırarak kendini çiziyor.
/// Buradaki testler o varsayımın tuttuğunu koruyor: her senaryo sonlu adımda çözülüyor
/// ve sıra belirlenimci. Tutmazsa ana ekranda ya hiç bitmeyen bir döngü ya da yarım
/// kalmış bir ızgara kalırdı.
@Suite("Önizleme")
struct VariantPreviewTests {
    @Test("Her senaryo sonlu adımda çözülüyor")
    func everyScenarioSolvesItself() {
        #expect(steps(TutorialScenarios.kakuro()) != nil)
        #expect(steps(TutorialScenarios.calcudoku()) != nil)
        #expect(steps(TutorialScenarios.hitori()) != nil)
        #expect(steps(TutorialScenarios.slitherlink()) != nil)
        #expect(steps(TutorialScenarios.hashi()) != nil)
    }

    /// Önizleme kadrajı küçük; bir senaryo yüzlerce adım sürerse izleyen kimse sonunu
    /// görmez. Elle hazırlanmış ızgaralar küçük, sınır onu koruyor.
    @Test("Senaryolar kısa")
    func scenariosAreShort() throws {
        let counts = [
            try #require(steps(TutorialScenarios.kakuro())),
            try #require(steps(TutorialScenarios.calcudoku())),
            try #require(steps(TutorialScenarios.hitori())),
            try #require(steps(TutorialScenarios.slitherlink())),
            try #require(steps(TutorialScenarios.hashi()))
        ]
        for count in counts {
            #expect(count > 0)
            #expect(count <= 40, "\(count) adım, önizleme için uzun")
        }
    }

    // İpucu seçimi belirlenimci (ADR'nin dayandığı davranış): aynı senaryo her
    // açılışta aynı sırayla doluyor, yani önizleme her turda aynı şeyi anlatıyor.
    @Test("Açılış sırası her turda aynı")
    func revealOrderIsDeterministic() {
        let scenario = TutorialScenarios.slitherlink()
        #expect(order(scenario) == order(scenario))
    }

    /// Çözüme kaç adımda gidildiği; gitmiyorsa `nil`.
    private func steps<Runtime: PuzzleRuntime>(_ scenario: TutorialScenario<Runtime>) -> Int? {
        var session = GameSession<Runtime>(
            definition: scenario.definition, solution: scenario.solution
        )
        var count = 0
        while !session.isSolved {
            guard session.revealHint() != nil else { return nil }
            count += 1
            guard count < 500 else { return nil }
        }
        return count
    }

    private func order<Runtime: PuzzleRuntime>(
        _ scenario: TutorialScenario<Runtime>
    ) -> [Runtime.Location] {
        var session = GameSession<Runtime>(
            definition: scenario.definition, solution: scenario.solution
        )
        var locations: [Runtime.Location] = []
        while !session.isSolved, let location = session.revealHint() {
            locations.append(location)
        }
        return locations
    }
}
