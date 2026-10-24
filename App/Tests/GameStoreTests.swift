import Testing
import Foundation
import SwiftData
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("Yarım kalan oyun saklama")
@MainActor
struct GameStoreTests {
    private func store() throws -> GameStore {
        let container = try AppStorage.container(inMemory: true)
        return GameStore(context: ModelContext(container))
    }

    private func snapshot(writing digit: Int) -> GameSnapshot<KakuroMove> {
        var history = MoveHistory<KakuroMove>()
        let move = KakuroMove(
            position: Position(row: 1, column: 1),
            previous: .empty,
            next: DigitCell(value: digit)
        )
        history.record([move])
        return GameSnapshot(history: history, hintCount: 1)
    }

    private let kakuroEasy = GameStore.Key(variant: .kakuro, difficulty: .easy)

    @Test("Saklanan oyun geri okunuyor")
    func savedGameRoundTrips() throws {
        let store = try store()
        try store.save(snapshot(writing: 5), key: kakuroEasy, seed: 4_242, seconds: 93, day: nil)

        let loaded = try store.load(KakuroMove.self, key: kakuroEasy)
        let resumed = try #require(loaded)
        #expect(resumed.seed == 4_242)
        #expect(resumed.seconds == 93)
        #expect(resumed.snapshot.hintCount == 1)
        #expect(resumed.snapshot.history.canUndo)
    }

    @Test("Kaydı olmayan anahtar boş dönüyor")
    func missingKeyReturnsNothing() throws {
        let store = try store()
        #expect(try store.load(KakuroMove.self, key: kakuroEasy) == nil)
    }

    @Test("Aynı anahtara ikinci kayıt öncekini güncelliyor")
    func savingTwiceUpdatesTheSameRow() throws {
        let store = try store()
        try store.save(snapshot(writing: 1), key: kakuroEasy, seed: 1, seconds: 10, day: nil)
        try store.save(snapshot(writing: 2), key: kakuroEasy, seed: 1, seconds: 40, day: nil)

        let loaded = try store.load(KakuroMove.self, key: kakuroEasy)
        let resumed = try #require(loaded)
        #expect(resumed.seconds == 40)
        #expect(try store.difficultiesInProgress(variant: .kakuro) == [.easy])
    }

    // Easy'ye başlamak yarım kalan Medium'u silmemeli: anahtar zorluğu da içeriyor.
    @Test("Zorluklar birbirini silmiyor")
    func difficultiesDoNotOverwriteEachOther() throws {
        let store = try store()
        let medium = GameStore.Key(variant: .kakuro, difficulty: .medium)
        try store.save(snapshot(writing: 1), key: kakuroEasy, seed: 1, seconds: 10, day: nil)
        try store.save(snapshot(writing: 2), key: medium, seed: 2, seconds: 20, day: nil)

        #expect(try store.difficultiesInProgress(variant: .kakuro) == [.easy, .medium])
        #expect(try store.load(KakuroMove.self, key: kakuroEasy)?.seed == 1)
        #expect(try store.load(KakuroMove.self, key: medium)?.seed == 2)
    }

    @Test("Günlük bulmaca serbest oyundan ayrı")
    func dailyIsSeparateFromFreePlay() throws {
        let store = try store()
        let daily = GameStore.Key(variant: .kakuro, difficulty: .medium, kind: .daily)
        try store.save(
            snapshot(writing: 3),
            key: daily,
            seed: 9,
            seconds: 5,
            day: CalendarDay(year: 2026, month: 10, day: 24)
        )

        #expect(try store.load(KakuroMove.self, key: daily) != nil)
        #expect(try store.difficultiesInProgress(variant: .kakuro).isEmpty)
        #expect(try store.variantsInProgress() == [.kakuro])
    }

    @Test("Silinen oyun geri gelmiyor")
    func deletedGameIsGone() throws {
        let store = try store()
        try store.save(snapshot(writing: 1), key: kakuroEasy, seed: 1, seconds: 10, day: nil)
        try store.delete(kakuroEasy)

        #expect(try store.load(KakuroMove.self, key: kakuroEasy) == nil)
        #expect(try store.variantsInProgress().isEmpty)
    }

    // Algoritma sürümü değişince aynı tohum başka bir bulmaca veriyor ve saklanan
    // hamleler ona uymuyor. Oyuncuya yanlış tahta göstermektense baştan başlatmak.
    @Test("Başka sürümle yazılmış kayıt atılıyor")
    func rowsFromAnotherAlgorithmVersionAreDiscarded() throws {
        let container = try AppStorage.container(inMemory: true)
        let context = ModelContext(container)
        let store = GameStore(context: context)
        try store.save(snapshot(writing: 1), key: kakuroEasy, seed: 1, seconds: 10, day: nil)

        let rows = try context.fetch(FetchDescriptor<StoredGame>())
        let row = try #require(rows.first)
        row.algorithmVersion = Seed.algorithmVersion + 1
        try context.save()

        #expect(try store.load(KakuroMove.self, key: kakuroEasy) == nil)
        #expect(try context.fetch(FetchDescriptor<StoredGame>()).isEmpty, "Kayıt silinmeli")
    }

    @Test("Çözümlenemeyen kayıt atılıyor")
    func corruptedRowsAreDiscarded() throws {
        let container = try AppStorage.container(inMemory: true)
        let context = ModelContext(container)
        let store = GameStore(context: context)
        try store.save(snapshot(writing: 1), key: kakuroEasy, seed: 1, seconds: 10, day: nil)

        let rows = try context.fetch(FetchDescriptor<StoredGame>())
        let row = try #require(rows.first)
        row.snapshotData = Data("bozuk".utf8)
        try context.save()

        #expect(try store.load(KakuroMove.self, key: kakuroEasy) == nil)
        #expect(try context.fetch(FetchDescriptor<StoredGame>()).isEmpty)
    }

    @Test("Yarım kalan oyunu olan varyantlar")
    func variantsInProgressAreListed() throws {
        let store = try store()
        try store.save(snapshot(writing: 1), key: kakuroEasy, seed: 1, seconds: 1, day: nil)
        try store.save(
            snapshot(writing: 2),
            key: GameStore.Key(variant: .hitori, difficulty: .hard),
            seed: 2,
            seconds: 2,
            day: nil
        )
        #expect(try store.variantsInProgress() == [.kakuro, .hitori])
    }
}
