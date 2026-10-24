import Testing
import GameCore

@Suite("Takvim günü")
struct CalendarDayTests {
    @Test("Bilinen günlerin gün numarası")
    func knownDayNumbers() {
        #expect(CalendarDay(year: 1970, month: 1, day: 1).dayNumber == 0)
        #expect(CalendarDay(year: 1969, month: 12, day: 31).dayNumber == -1)
        #expect(CalendarDay(year: 2000, month: 1, day: 1).dayNumber == 10_957)
    }

    // Dönüşüm iki yönlü ve kayıpsız olmak zorunda: seri hesabı gün numarası üzerinden
    // yapılıyor, gösterim yıl/ay/gün üzerinden.
    @Test("Gün numarası dönüşümü iki yönlü")
    func dayNumberRoundTrips() {
        var day = CalendarDay(year: 2024, month: 1, day: 1)
        for _ in 0..<(366 * 6) {
            #expect(CalendarDay(dayNumber: day.dayNumber) == day)
            day = day.advanced(by: 1)
        }
        #expect(day.year == 2030)
    }

    @Test("Ay sonu geçişi")
    func monthBoundary() {
        let day = CalendarDay(year: 2026, month: 1, day: 31).advanced(by: 1)
        #expect(day == CalendarDay(year: 2026, month: 2, day: 1))
    }

    @Test("Artık olmayan yılda şubat 28 çekiyor")
    func commonYearFebruary() {
        let day = CalendarDay(year: 2027, month: 2, day: 28).advanced(by: 1)
        #expect(day == CalendarDay(year: 2027, month: 3, day: 1))
        #expect(!CalendarDay.isLeapYear(2027))
    }

    @Test("Artık yılda şubat 29 çekiyor")
    func leapYearFebruary() {
        let day = CalendarDay(year: 2028, month: 2, day: 28).advanced(by: 1)
        #expect(day == CalendarDay(year: 2028, month: 2, day: 29))
        #expect(day.advanced(by: 1) == CalendarDay(year: 2028, month: 3, day: 1))
    }

    // Yüzyıl kuralı: 1900 artık yıl değil, 2000 artık yıl.
    @Test("Yüzyıl kuralı")
    func centuryRule() {
        #expect(!CalendarDay.isLeapYear(1900))
        #expect(CalendarDay.isLeapYear(2000))
        #expect(CalendarDay.daysInMonth(year: 1900, month: 2) == 28)
        #expect(CalendarDay.daysInMonth(year: 2000, month: 2) == 29)
    }

    @Test("Yıl sonu geçişi")
    func yearBoundary() {
        let day = CalendarDay(year: 2026, month: 12, day: 31).advanced(by: 1)
        #expect(day == CalendarDay(year: 2027, month: 1, day: 1))
    }

    @Test("Gün farkı")
    func differenceBetweenDays() {
        let earlier = CalendarDay(year: 2026, month: 10, day: 20)
        let later = CalendarDay(year: 2026, month: 11, day: 3)
        #expect(later.days(since: earlier) == 14)
        #expect(earlier.days(since: later) == -14)
    }

    // Haftanın günü ADR 0006'daki günlük bulmaca eşlemesinin girdisi; yanlış olursa
    // oyuncular yanlış günde yanlış varyantı görür.
    @Test("Haftanın günü")
    func weekdays() {
        #expect(CalendarDay(year: 1970, month: 1, day: 1).weekday == .thursday)
        #expect(CalendarDay(year: 2026, month: 10, day: 24).weekday == .saturday)
        #expect(CalendarDay(year: 2026, month: 10, day: 26).weekday == .monday)
        #expect(CalendarDay(year: 2026, month: 10, day: 25).weekday == .sunday)
    }

    @Test("Haftanın günü yedi günde bir dönüyor")
    func weekdaysCycle() {
        var day = CalendarDay(year: 2026, month: 1, day: 1)
        for _ in 0..<400 {
            #expect(day.advanced(by: 7).weekday == day.weekday)
            day = day.advanced(by: 1)
        }
    }

    @Test("Sıralama")
    func ordering() {
        #expect(CalendarDay(year: 2026, month: 1, day: 2) > CalendarDay(year: 2026, month: 1, day: 1))
        #expect(CalendarDay(year: 2026, month: 2, day: 1) > CalendarDay(year: 2026, month: 1, day: 31))
        #expect(CalendarDay(year: 2027, month: 1, day: 1) > CalendarDay(year: 2026, month: 12, day: 31))
    }
}
