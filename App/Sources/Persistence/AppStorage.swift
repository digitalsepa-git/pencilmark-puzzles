import Foundation
import GameCore
import SwiftData

/// Uygulamanın SwiftData kabı.
///
/// Şema tek bir yerde tanımlı ve sürümleme henüz yok: V1'de tek bir model var ve hiç
/// yayınlanmadı, yani taşınacak veri de yok. İlk sürüm mağazaya çıktıktan **sonra** bu
/// şemaya dokunmak `VersionedSchema` ve `SchemaMigrationPlan` gerektirecek; o güne kadar
/// kurulum eklemek, kullanılmayan bir soyutlamayı bakmak demek.
enum AppStorage {
    static let schema = Schema([StoredRecord.self])

    static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        )
    }
}

/// "Bugün" tek bir yerden geliyor.
///
/// ADR 0006: gün, cihazın yerel takvim günü. Bu dönüşümün uygulamada tek bir yeri olması
/// gerekiyor — ikinci bir yer, günlük bulmacayla seri hesabının farklı günlerde çalışmaya
/// başlaması demek.
enum LocalCalendar {
    static func today(now: Date = Date(), calendar: Calendar = .current) -> CalendarDay {
        day(of: now, calendar: calendar)
    }

    static func day(of date: Date, calendar: Calendar = .current) -> CalendarDay {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return CalendarDay(
            year: parts.year ?? 1970,
            month: parts.month ?? 1,
            day: parts.day ?? 1
        )
    }
}
