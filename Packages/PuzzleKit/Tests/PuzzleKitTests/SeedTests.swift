import Testing
import PuzzleKit

@Suite("Tohum ve rastgele üretici")
struct SeedTests {
    // Bu dosyadaki sabit değerler bilinçli olarak koda yazıldı.
    // Günlük bulmacanın "herkes aynı bulmacayı görür" gereksinimi (brief b.5) üreticinin
    // bit bit aynı diziyi vermesine bağlı. Bu sayılar değişirse test kırılır ve
    // kırılması gerekir: kimse farkında olmadan tüm günlük bulmaca geçmişini değiştirmesin.
    @Test("SplitMix64 bilinen diziyi üretir")
    func generatorProducesKnownSequence() {
        var rng = SeededGenerator(seed: 0)
        let first = (0..<3).map { _ in rng.next() }
        #expect(first == [
            0xE220_A839_7B1D_CDAF,
            0x6E78_9E6A_A1B9_65F4,
            0x06C4_5D18_8009_454F
        ])
    }

    @Test("Aynı tohum aynı diziyi verir, farklı tohum farklı")
    func sameSeedSameSequence() {
        var a = SeededGenerator(seed: 12345)
        var b = SeededGenerator(seed: 12345)
        var c = SeededGenerator(seed: 12346)
        let fromA = (0..<10).map { _ in a.next() }
        let fromB = (0..<10).map { _ in b.next() }
        let fromC = (0..<10).map { _ in c.next() }
        #expect(fromA == fromB)
        #expect(fromA != fromC)
    }

    @Test("Alt akışlar birbirinden bağımsız")
    func substreamsAreIndependent() {
        let base = SeededGenerator(seed: 999)
        var first = base.substream(1)
        var second = base.substream(2)
        var firstAgain = base.substream(1)
        var firstOnceMore = base.substream(1)
        #expect(first.next() != second.next())
        #expect(firstOnceMore.makeValues(5) == firstAgain.makeValues(5))
    }

    @Test("FNV-1a tohumu bileşen sırasına duyarlı")
    func seedIsOrderSensitive() {
        #expect(Seed.make("a", "b") != Seed.make("b", "a"))
        #expect(Seed.make("a", "b") == Seed.make("a", "b"))
        // Bileşen ayracı olmasa "ab"+"c" ile "a"+"bc" aynı tohumu verirdi.
        #expect(Seed.make("ab", "c") != Seed.make("a", "bc"))
    }

    @Test("Günlük tohum tarih ve varyanta bağlı, serbest oyundan ayrı")
    func dailySeedDependsOnDateAndVariant() {
        let monday = Seed.daily(variant: .kakuro, year: 2026, month: 10, day: 19)
        #expect(monday == Seed.daily(variant: .kakuro, year: 2026, month: 10, day: 19))
        #expect(monday != Seed.daily(variant: .kakuro, year: 2026, month: 10, day: 20))
        #expect(monday != Seed.daily(variant: .hitori, year: 2026, month: 10, day: 19))
        #expect(monday != Seed.free(variant: .kakuro, difficulty: .medium, counter: 0))
    }

    @Test("Tarih bileşenleri sıfır dolgusuz da ayrışır")
    func dateComponentsDoNotCollide() {
        // "2026-1-12" ile "2026-11-2" ayracı olmasa çakışırdı.
        #expect(
            Seed.daily(variant: .hashi, year: 2026, month: 1, day: 12)
                != Seed.daily(variant: .hashi, year: 2026, month: 11, day: 2)
        )
    }
}

private extension SeededGenerator {
    mutating func makeValues(_ count: Int) -> [UInt64] {
        (0..<count).map { _ in next() }
    }
}
