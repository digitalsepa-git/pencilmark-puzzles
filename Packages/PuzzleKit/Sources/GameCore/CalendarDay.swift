/// Yerel takvim günü: yıl, ay, gün.
///
/// `Foundation.Date` değil. İki sebep var. Birincisi GameCore'un Foundation'a bağımlı
/// olmaması (ADR 0015): oyun mantığı Linux'ta 1x maliyetle test ediliyor. İkincisi daha
/// önemli: günlük bulmaca ve seri hesabı **anı** değil **günü** soruyor. "Dün çözdü mü"
/// sorusunun saat, dakika ve saat dilimiyle işi yok; `Date` kullanmak o ayrıntıları
/// taşımak ve her karşılaştırmada yeniden kırpmak demekti.
///
/// Hangi takvime ve hangi saat dilimine göre "bugün" olduğuna uygulama katmanı karar
/// veriyor (cihaz yerel saati — ADR 0006) ve sonucu buraya üç tamsayı olarak veriyor.
public struct CalendarDay: Hashable, Sendable, Codable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        precondition((1...12).contains(month), "Ay 1-12 aralığında olmalı: \(month)")
        precondition(
            (1...Self.daysInMonth(year: year, month: month)).contains(day),
            "\(year)-\(month) ayında \(day). gün yok"
        )
        self.year = year
        self.month = month
        self.day = day
    }

    public static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: 31
        case 4, 6, 9, 11: 30
        default: isLeapYear(year) ? 29 : 28
        }
    }

    public static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    /// 1 Ocak 1970'ten beri geçen gün sayısı; öncesi negatif.
    ///
    /// Takvim aritmetiğinin tamamı bu sayı üzerinden yapılıyor: ardışıklık, fark ve
    /// haftanın günü tek bir çıkarma ya da bölme oluyor. Dönüşüm Howard Hinnant'ın
    /// yayınlanmış proleptik Gregoryen algoritması.
    public var dayNumber: Int {
        var y = year
        if month <= 2 { y -= 1 }
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let shifted = month > 2 ? month - 3 : month + 9
        let dayOfYear = (153 * shifted + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }

    public init(dayNumber: Int) {
        let shifted = dayNumber + 719_468
        let era = (shifted >= 0 ? shifted : shifted - 146_096) / 146_097
        let dayOfEra = shifted - era * 146_097
        let yearOfEra =
            (dayOfEra - dayOfEra / 1_460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        let monthIndex = (5 * dayOfYear + 2) / 153
        let day = dayOfYear - (153 * monthIndex + 2) / 5 + 1
        let month = monthIndex < 10 ? monthIndex + 3 : monthIndex - 9
        let year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0)
        self.init(year: year, month: month, day: day)
    }

    public func advanced(by days: Int) -> CalendarDay {
        CalendarDay(dayNumber: dayNumber + days)
    }

    /// Aradaki gün farkı; `other` daha eskiyse pozitif.
    public func days(since other: CalendarDay) -> Int {
        dayNumber - other.dayNumber
    }

    public var weekday: Weekday {
        // 1 Ocak 1970 perşembe; pazartesi tabanlı indekse kaydırılıyor.
        let index = (((dayNumber + 3) % 7) + 7) % 7
        return Weekday.allCases[index]
    }
}

extension CalendarDay: Comparable {
    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

extension CalendarDay: CustomStringConvertible {
    public var description: String { "\(year)-\(month)-\(day)" }
}

/// Haftanın günü, pazartesi tabanlı — ADR 0006'daki günlük bulmaca tablosunun sırası.
public enum Weekday: Int, CaseIterable, Hashable, Sendable, Codable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}
