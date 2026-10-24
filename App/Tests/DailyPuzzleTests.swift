import Testing
import Foundation
import GameCore
import PuzzleKit
@testable import Pencilmark

@Suite("Günlük bulmaca")
struct DailyPuzzleTests {
    // ADR 0006'daki tablo: Pzt Kakuro, Sal Calcudoku, Çar Slitherlink, Per Hashi,
    // Cum Hitori, Cmt Kakuro, Paz Calcudoku. Yanlış olursa oyuncular yanlış günde
    // yanlış varyantı görür ve "perşembe Hashi günü" alışkanlığı kurulamaz.
    @Test("Varyant eşlemesi ADR 0006'daki tablo")
    func variantMappingFollowsTheDecisionRecord() {
        // 26 Ekim 2026 pazartesi.
        let monday = CalendarDay(year: 2026, month: 10, day: 26)
        let expected: [PuzzleVariantID] = [
            .kakuro, .calcudoku, .slitherlink, .hashi, .hitori, .kakuro, .calcudoku
        ]
        for (offset, variant) in expected.enumerated() {
            let day = monday.advanced(by: offset)
            #expect(DailyPuzzle.variant(on: day) == variant, "\(day.weekday)")
        }
    }

    @Test("Eşleme haftadan haftaya aynı")
    func mappingRepeatsWeekly() {
        var day = CalendarDay(year: 2026, month: 1, day: 1)
        for _ in 0..<400 {
            #expect(DailyPuzzle.variant(on: day) == DailyPuzzle.variant(on: day.advanced(by: 7)))
            day = day.advanced(by: 1)
        }
    }

    @Test("Zorluk sabit Medium")
    func difficultyIsFixed() {
        #expect(DailyPuzzle.difficulty == .medium)
        #expect(DailyPuzzle.difficulty.isFreeTier)
    }

    @Test("Aynı gün aynı tohum, farklı gün farklı tohum")
    func seedsAreStablePerDay() {
        let day = CalendarDay(year: 2026, month: 10, day: 24)
        #expect(DailyPuzzle.seed(on: day) == DailyPuzzle.seed(on: day))
        #expect(DailyPuzzle.seed(on: day) != DailyPuzzle.seed(on: day.advanced(by: 1)))
    }

    // Tohum ayraçsız birleştirilseydi "2026-1-12" ile "2026-11-2" çakışırdı; PuzzleKit
    // tarafında korunuyor ama günlük bulmacanın bu çakışmaya en açık yer olduğu için
    // burada da sınanıyor.
    @Test("Tarih bileşenleri çakışmıyor")
    func dateComponentsDoNotCollide() {
        let first = DailyPuzzle.seed(on: CalendarDay(year: 2026, month: 1, day: 12))
        let second = DailyPuzzle.seed(on: CalendarDay(year: 2026, month: 11, day: 2))
        #expect(first != second)
    }
}

@Suite("Paylaşım kartı")
struct ShareCardTests {
    // Biçim artık kullanıcının diline göre; test sabit bir dil pinliyor, yoksa
    // çalıştığı makinenin diline göre kırılırdı.
    @Test("Tarih okunur biçimde")
    func dateIsHumanReadable() {
        let english = Locale(identifier: "en_US")
        #expect(ShareCard.longDate(CalendarDay(year: 2026, month: 10, day: 24), locale: english)
            == "October 24, 2026")
        #expect(ShareCard.longDate(CalendarDay(year: 2027, month: 1, day: 1), locale: english)
            == "January 1, 2027")
        #expect(ShareCard.longDate(CalendarDay(year: 2028, month: 12, day: 31), locale: english)
            == "December 31, 2028")
    }

    // Yerelleştirme altyapısının somut faydası: ay adları ve tarih sırası dile göre
    // değişiyor, elle yazılmış on iki ay adıyla bu mümkün değildi.
    @Test("Tarih biçimi dile göre değişiyor")
    func dateFollowsTheLocale() {
        let day = CalendarDay(year: 2026, month: 10, day: 24)
        let english = ShareCard.longDate(day, locale: Locale(identifier: "en_US"))
        let turkish = ShareCard.longDate(day, locale: Locale(identifier: "tr_TR"))
        #expect(english != turkish)
        #expect(turkish.contains("Ekim"))
    }
}
