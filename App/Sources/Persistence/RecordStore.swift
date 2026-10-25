import Foundation
import GameCore
import PuzzleKit
import SwiftData

/// Bitmiş bulmacaların SwiftData kaydı.
///
/// SwiftData Apple'a özgü, bu yüzden bu katman App hedefinde; hesap GameCore'da kaldı
/// (ADR 0015'in modül sınırı kararı). Ayrım pratik bir fayda veriyor: seri ve özet
/// hesabı simülatör açmadan sınanıyor, burada sınanan şey yalnız yazma/okuma.
@Model
final class StoredRecord {
    /// `rawValue` olarak saklanıyor, enum olarak değil: enum'un case adı değişirse ya da
    /// yeni case eklenirse eski satırlar okunamaz hale gelmesin. `PuzzleVariantID`'nin
    /// `rawValue`'ları zaten "kayıt şemasında kullanılıyor, sabit kalmak zorunda" diye
    /// işaretli.
    var variantID: String
    var difficultyID: String
    var kindID: String
    var year: Int
    var month: Int
    var day: Int
    var seconds: Int
    var hintCount: Int
    /// Satırın yazıldığı an. Aynı günün kayıtlarını sıralamak için; gün bilgisi ayrı
    /// tutuluyor çünkü "hangi gün" kararı yerel takvime ait (ADR 0006).
    var createdAt: Date

    init(record: PuzzleRecord, createdAt: Date = Date()) {
        self.variantID = record.variant.rawValue
        self.difficultyID = record.difficulty.rawValue
        self.kindID = record.kind.rawValue
        self.year = record.day.year
        self.month = record.day.month
        self.day = record.day.day
        self.seconds = record.seconds
        self.hintCount = record.hintCount
        self.createdAt = createdAt
    }

    /// Tanınmayan bir `rawValue` varsa satır atlanıyor.
    ///
    /// Eski bir sürümün yazdığı, bu sürümde artık olmayan bir varyant olabilir. Böyle bir
    /// satır yüzünden bütün istatistiğin çökmesi kabul edilemez; sessizce atlamak da
    /// değil, ama bunun doğru yeri bir günlük kaydı ve o Faz 4'ün işi.
    var asRecord: PuzzleRecord? {
        guard let variant = PuzzleVariantID(rawValue: variantID),
              let difficulty = Difficulty(rawValue: difficultyID),
              let kind = PuzzleRecord.Kind(rawValue: kindID),
              (1...12).contains(month),
              (1...CalendarDay.daysInMonth(year: year, month: month)).contains(day) else {
            return nil
        }
        return PuzzleRecord(
            variant: variant,
            difficulty: difficulty,
            kind: kind,
            day: CalendarDay(year: year, month: month, day: day),
            seconds: seconds,
            hintCount: hintCount
        )
    }
}

/// Kayıtları yazan ve okuyan ince katman.
///
/// SwiftData'nın `ModelContext`'i doğrudan ekranlara verilmiyor: ekranların ihtiyacı olan
/// şey `PuzzleRecord` ve `StatsSummary`, `StoredRecord` değil. Araya bu tip girince
/// saklama biçimi değişse de arayüz tarafı aynı kalıyor.
@MainActor
struct RecordStore {
    let context: ModelContext

    func add(_ record: PuzzleRecord) throws {
        context.insert(StoredRecord(record: record))
        try context.save()
    }

    func allRecords() throws -> [PuzzleRecord] {
        let descriptor = FetchDescriptor<StoredRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).compactMap(\.asRecord)
    }

    func summary(today: CalendarDay) throws -> StatsSummary {
        StatsSummary.summarise(try allRecords(), today: today)
    }

    /// Bitmiş bulmaca sayısı. Paywall kapısı buna bakıyor (brief b.8, `PaywallPolicy`);
    /// bütün kayıtları çözümlemek yalnız saymak için gereksiz.
    func solvedCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<StoredRecord>())
    }

    /// Verilen günün günlük bulmacası çözüldü mü.
    func hasSolvedDaily(on day: CalendarDay) throws -> Bool {
        let kind = PuzzleRecord.Kind.daily.rawValue
        let year = day.year
        let month = day.month
        let dayOfMonth = day.day
        var descriptor = FetchDescriptor<StoredRecord>(
            predicate: #Predicate { stored in
                stored.kindID == kind
                    && stored.year == year
                    && stored.month == month
                    && stored.day == dayOfMonth
            }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }
}
