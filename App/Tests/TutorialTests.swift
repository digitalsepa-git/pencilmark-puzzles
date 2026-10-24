import Testing
import SwiftUI
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("Öğretici tercihi")
@MainActor
struct TutorialPreferenceTests {
    private func preferences() throws -> Preferences {
        Preferences(defaults: try #require(UserDefaults(suiteName: UUID().uuidString)))
    }

    // ADR 0009: ilk kez bir varyant açıldığında öğretici kendiliğinden başlıyor.
    @Test("Başlangıçta hiçbir öğretici görülmemiş")
    func nothingSeenInitially() throws {
        let preferences = try preferences()
        for variant in PuzzleVariantID.allCases {
            #expect(!preferences.hasSeenTutorial(variant))
        }
    }

    @Test("Görülen öğretici işaretleniyor ve saklanıyor")
    func seenTutorialsPersist() throws {
        let suite = UUID().uuidString
        let store = try #require(UserDefaults(suiteName: suite))

        let first = Preferences(defaults: store)
        first.markTutorialSeen(.hashi)
        first.markTutorialSeen(.kakuro)

        let second = Preferences(defaults: store)
        #expect(second.hasSeenTutorial(.hashi))
        #expect(second.hasSeenTutorial(.kakuro))
        #expect(!second.hasSeenTutorial(.hitori))
    }

    @Test("Sıfırlama hepsini yeniden açıyor")
    func resetMakesTutorialsStartAgain() throws {
        let preferences = try preferences()
        preferences.markTutorialSeen(.slitherlink)
        preferences.resetTutorials()
        #expect(!preferences.hasSeenTutorial(.slitherlink))
        #expect(preferences.seenTutorials.isEmpty)
    }

    @Test("Tanınmayan varyant kaydı atılıyor")
    func unknownVariantsAreIgnored() throws {
        let suite = UUID().uuidString
        let store = try #require(UserDefaults(suiteName: suite))
        store.set(["hashi", "boyle-bir-varyant-yok"], forKey: "tercih.gorulenOgreticiler")

        let preferences = Preferences(defaults: store)
        #expect(preferences.seenTutorials == [.hashi])
    }
}

@Suite("Öğretici ekranı")
@MainActor
struct TutorialChromeTests {
    // Düzeltme uyarısı görünür bir fark yaratmalı: ADR 0009 yanlış hamlenin nazikçe
    // düzeltilmesini istiyor ve görünmeyen bir uyarı düzeltmiyor.
    @Test("Düzeltme uyarısı ekranı değiştiriyor")
    func correctionChangesTheScreen() throws {
        let size = CGSize(width: 320, height: 520)
        let scenario = TutorialScenarios.hitori()
        let run = TutorialRun(scenario: scenario)

        func render(correction: String?) -> UIImage? {
            SnapshotHarness.render(
                TutorialChrome(
                    stepNumber: 1,
                    stepCount: scenario.steps.count,
                    text: scenario.steps[0].text,
                    correction: correction,
                    isFinished: false,
                    onUndo: {},
                    onSkip: {},
                    onDone: {},
                    grid: {
                        HitoriGridView(
                            puzzle: scenario.definition,
                            board: run.session.board
                        )
                    }
                ),
                size: size,
                colorScheme: .light
            )
        }

        let plain = try #require(render(correction: nil))
        let warned = try #require(render(correction: "Nope, try again."))
        #expect(SnapshotHarness.compare(plain, warned).ratio > SnapshotHarness.allowedPixelRatio)
    }
}
