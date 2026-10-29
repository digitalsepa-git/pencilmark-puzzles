import Testing
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("Önden üretim")
@MainActor
struct PuzzlePrefetcherTests {
    /// Hashi Easy ölçülen en ucuz üretim (cihazda 1 ms); testin beklemesi gereken süre
    /// bu yüzden ihmal edilebilir.
    private func primedPrefetcher() async -> PuzzlePrefetcher {
        let prefetcher = PuzzlePrefetcher()
        prefetcher.prime(HashiRuntime.self, difficulty: .easy)
        for _ in 0..<200 where !prefetcher.isReady(HashiRuntime.self, difficulty: .easy) {
            try? await Task.sleep(for: .milliseconds(20))
        }
        return prefetcher
    }

    @Test("Boş önbellek bulmaca vermiyor")
    func emptyCacheReturnsNothing() {
        let prefetcher = PuzzlePrefetcher()
        #expect(prefetcher.take(HashiRuntime.self, difficulty: .easy) == nil)
        #expect(!prefetcher.isReady(HashiRuntime.self, difficulty: .easy))
    }

    @Test("Üretilen bulmaca geri alınıyor")
    func primedPuzzleComesBack() async {
        let prefetcher = await primedPrefetcher()
        let puzzle = prefetcher.take(HashiRuntime.self, difficulty: .easy)
        #expect(puzzle != nil)
        #expect(puzzle?.difficulty == .easy)
        #expect(puzzle?.variant == .hashi)
    }

    // Aynı bulmacayı iki kez vermek, oyuncuya arka arkaya aynı ızgarayı göstermek
    // demek — rakip şikâyetlerinden biri.
    @Test("Alınan bulmaca yuvadan siliniyor")
    func takingEmptiesTheSlot() async {
        let prefetcher = await primedPrefetcher()
        _ = prefetcher.take(HashiRuntime.self, difficulty: .easy)
        #expect(!prefetcher.isReady(HashiRuntime.self, difficulty: .easy))
        #expect(prefetcher.take(HashiRuntime.self, difficulty: .easy) == nil)
    }

    @Test("Başka zorluk başka yuva")
    func difficultiesHaveTheirOwnSlots() async {
        let prefetcher = await primedPrefetcher()
        #expect(prefetcher.isReady(HashiRuntime.self, difficulty: .easy))
        #expect(!prefetcher.isReady(HashiRuntime.self, difficulty: .medium))
        #expect(prefetcher.take(HashiRuntime.self, difficulty: .medium) == nil)
    }

    @Test("Başka varyant başka yuva")
    func variantsHaveTheirOwnSlots() async {
        let prefetcher = await primedPrefetcher()
        #expect(prefetcher.isReady(HashiRuntime.self, difficulty: .easy))
        #expect(!prefetcher.isReady(HitoriRuntime.self, difficulty: .easy))
    }

    // Dolu yuvayı yeniden üretmek, bitmiş bir işi tekrarlamak ve pili boşuna harcamak.
    @Test("Dolu yuva yeniden üretilmiyor")
    func primingAFullSlotDoesNothing() async {
        let prefetcher = await primedPrefetcher()
        let first = prefetcher.take(HashiRuntime.self, difficulty: .easy)
        prefetcher.prime(HashiRuntime.self, difficulty: .easy)
        for _ in 0..<200 where !prefetcher.isReady(HashiRuntime.self, difficulty: .easy) {
            try? await Task.sleep(for: .milliseconds(20))
        }
        let second = prefetcher.take(HashiRuntime.self, difficulty: .easy)
        // İki ayrı üretim: tohumlar farklı olmalı, yani aynı bulmaca iki kez gelmiyor.
        #expect(first?.seed != second?.seed)
    }

    @Test("Günlük bulmacanın tohumu tarihten geliyor")
    func theDailyUsesItsDateSeed() async {
        let day = CalendarDay(year: 2026, month: 10, day: 29)
        let prefetcher = PuzzlePrefetcher()
        prefetcher.primeDaily(HashiRuntime.self, on: day)
        for _ in 0..<200 where !prefetcher.isReady(HashiRuntime.self, difficulty: DailyPuzzle.difficulty) {
            try? await Task.sleep(for: .milliseconds(20))
        }
        let puzzle = prefetcher.take(HashiRuntime.self, difficulty: DailyPuzzle.difficulty)
        #expect(puzzle?.seed == DailyPuzzle.seed(on: day))
    }
}
