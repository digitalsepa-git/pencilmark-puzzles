import Testing
import PuzzleKit

@Suite("DigitSet")
struct DigitSetTests {
    @Test("Ekleme, silme ve içerme")
    func insertRemoveContains() {
        var set = DigitSet()
        #expect(set.isEmpty)
        set.insert(5)
        set.insert(9)
        #expect(set.contains(5))
        #expect(set.contains(9))
        #expect(!set.contains(1))
        #expect(set.count == 2)
        set.remove(5)
        #expect(!set.contains(5))
        #expect(set.count == 1)
    }

    @Test("1...9 dışındaki değerler sessizce yok sayılır")
    func outOfRangeDigitsAreIgnored() {
        var set = DigitSet([0, 10, 42, -3, 7])
        #expect(set.count == 1)
        #expect(set.contains(7))
        set.insert(0)
        set.insert(10)
        #expect(set.count == 1)
    }

    @Test("toggle kalem işareti döngüsünü verir")
    func toggleFlipsMembership() {
        var set = DigitSet()
        set.toggle(3)
        #expect(set.contains(3))
        set.toggle(3)
        #expect(!set.contains(3))
    }

    @Test("singleDigit yalnızca tek aday kaldığında döner")
    func singleDigitOnlyWhenOneCandidate() {
        #expect(DigitSet([4]).singleDigit == 4)
        #expect(DigitSet([4, 6]).singleDigit == nil)
        #expect(DigitSet.empty.singleDigit == nil)
    }

    @Test("Küme işlemleri")
    func setOperations() {
        let a = DigitSet([1, 2, 3])
        let b = DigitSet([3, 4])
        #expect(a.union(b) == DigitSet([1, 2, 3, 4]))
        #expect(a.intersection(b) == DigitSet([3]))
        #expect(a.subtracting(b) == DigitSet([1, 2]))
    }

    @Test("upTo Calcudoku aday havuzunu verir")
    func upToBuildsCandidatePool() {
        #expect(DigitSet.upTo(4) == DigitSet([1, 2, 3, 4]))
        #expect(DigitSet.upTo(9) == DigitSet.all)
        #expect(DigitSet.all.count == 9)
    }

    @Test("Sıralı gezinme küçükten büyüğe")
    func iterationIsAscending() {
        #expect(Array(DigitSet([9, 1, 5])) == [1, 5, 9])
        #expect(DigitSet([2, 8]).description == "{2,8}")
    }
}
