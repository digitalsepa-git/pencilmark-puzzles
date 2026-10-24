import Foundation
import GameCore
import PuzzleKit
import SwiftData

/// Yarım kalan bir oyunun saklanan hali.
///
/// Tahta yok, hamle dizisi var (ADR 0018). Bulmacanın kendisi de yok: tohumdan yeniden
/// üretiliyor. Tanım saklansaydı beş varyantın tanım tipinin de `Codable` olması
/// gerekirdi ve kazancı yoktu — üretim belirlenimci.
@Model
final class StoredGame {
    var variantID: String
    var difficultyID: String
    var kindID: String
    /// `UInt64` SwiftData'nın öznitelik tipleri arasında değil; bit deseni saklanıyor.
    var seedBits: Int64
    /// Hangi algoritma sürümüyle üretildi. Sürüm değişirse aynı tohum başka bulmaca
    /// verir ve saklanan hamleler o bulmacaya uymaz; böyle bir kayıt atılıyor.
    var algorithmVersion: Int
    /// `GameSnapshot`'ın JSON hali. Varyantın hamle tipine bağlı olduğu için burada
    /// çözümlenmiyor; çözen taraf hangi tipi beklediğini biliyor.
    var snapshotData: Data
    var seconds: Int
    var updatedAt: Date
    /// Günlük bulmacanın günü; serbest oyunda sıfır.
    var year: Int
    var month: Int
    var day: Int

    init(
        variant: PuzzleVariantID,
        difficulty: Difficulty,
        kind: PuzzleRecord.Kind,
        seed: UInt64,
        algorithmVersion: Int,
        snapshotData: Data,
        seconds: Int,
        day: CalendarDay?,
        updatedAt: Date = Date()
    ) {
        self.variantID = variant.rawValue
        self.difficultyID = difficulty.rawValue
        self.kindID = kind.rawValue
        self.seedBits = Int64(bitPattern: seed)
        self.algorithmVersion = algorithmVersion
        self.snapshotData = snapshotData
        self.seconds = seconds
        self.updatedAt = updatedAt
        self.year = day?.year ?? 0
        self.month = day?.month ?? 0
        self.day = day?.day ?? 0
    }

    var seed: UInt64 { UInt64(bitPattern: seedBits) }
    var variant: PuzzleVariantID? { PuzzleVariantID(rawValue: variantID) }
    var difficulty: Difficulty? { Difficulty(rawValue: difficultyID) }
}

/// Yarım kalan oyunları yazan ve okuyan katman.
///
/// Anahtar (varyant, zorluk, tür): Easy'ye başlamak yarım kalan Medium'u silmiyor.
/// Alternatifi varyant başına tek kayıttı ve o, oyuncunun haberi olmadan ilerlemesini
/// silerdi — onay sorarak çözülebilirdi ama sormamak daha iyi.
@MainActor
struct GameStore {
    /// Saklanan oyunun kimliği. Üçü birlikte anahtar olduğu için tek tip hâlinde
    /// taşınıyor; ayrı parametreler olarak gezdirmek çağrı yerlerini şişiriyordu.
    struct Key: Hashable {
        let variant: PuzzleVariantID
        let difficulty: Difficulty
        let kind: PuzzleRecord.Kind

        init(
            variant: PuzzleVariantID,
            difficulty: Difficulty,
            kind: PuzzleRecord.Kind = .free
        ) {
            self.variant = variant
            self.difficulty = difficulty
            self.kind = kind
        }
    }

    let context: ModelContext

    func save<Move: PuzzleMove>(
        _ snapshot: GameSnapshot<Move>,
        key: Key,
        seed: UInt64,
        seconds: Int,
        day: CalendarDay?
    ) throws {
        let data = try JSONEncoder().encode(snapshot)
        if let existing = try row(key) {
            existing.snapshotData = data
            existing.seconds = seconds
            existing.seedBits = Int64(bitPattern: seed)
            existing.updatedAt = Date()
        } else {
            context.insert(
                StoredGame(
                    variant: key.variant,
                    difficulty: key.difficulty,
                    kind: key.kind,
                    seed: seed,
                    algorithmVersion: Seed.algorithmVersion,
                    snapshotData: data,
                    seconds: seconds,
                    day: day
                )
            )
        }
        try context.save()
    }

    /// Saklanan oyunu çözümlüyor.
    ///
    /// Algoritma sürümü değişmişse ya da JSON çözümlenemiyorsa kayıt atılıyor: aynı
    /// tohum artık başka bir bulmaca veriyor ve saklanan hamleler ona uymaz. Oyuncuya
    /// yanlış tahta göstermektense baştan başlatmak daha az kötü.
    func load<Move: PuzzleMove>(_ type: Move.Type, key: Key) throws -> ResumedGame<Move>? {
        guard let row = try row(key) else {
            return nil
        }
        guard row.algorithmVersion == Seed.algorithmVersion,
              let snapshot = try? JSONDecoder().decode(GameSnapshot<Move>.self, from: row.snapshotData)
        else {
            context.delete(row)
            try context.save()
            return nil
        }
        return ResumedGame(snapshot: snapshot, seed: row.seed, seconds: row.seconds)
    }

    func delete(_ key: Key) throws {
        guard let row = try row(key) else {
            return
        }
        context.delete(row)
        try context.save()
    }

    /// Yarım kalan oyunu olan varyantlar; ana ekrandaki "devam et" satırı buna bakıyor.
    func variantsInProgress() throws -> Set<PuzzleVariantID> {
        let rows = try context.fetch(FetchDescriptor<StoredGame>())
        return Set(rows.compactMap(\.variant))
    }

    /// Bir varyantın yarım kalan zorlukları; zorluk ekranındaki işaret buna bakıyor.
    func difficultiesInProgress(variant: PuzzleVariantID) throws -> Set<Difficulty> {
        let id = variant.rawValue
        let free = PuzzleRecord.Kind.free.rawValue
        let rows = try context.fetch(
            FetchDescriptor<StoredGame>(
                predicate: #Predicate { $0.variantID == id && $0.kindID == free }
            )
        )
        return Set(rows.compactMap(\.difficulty))
    }

    private func row(_ key: Key) throws -> StoredGame? {
        let variantID = key.variant.rawValue
        let difficultyID = key.difficulty.rawValue
        let kindID = key.kind.rawValue
        var descriptor = FetchDescriptor<StoredGame>(
            predicate: #Predicate {
                $0.variantID == variantID
                    && $0.difficultyID == difficultyID
                    && $0.kindID == kindID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

/// Saklamadan geri gelen oyun.
struct ResumedGame<Move: PuzzleMove> {
    let snapshot: GameSnapshot<Move>
    let seed: UInt64
    let seconds: Int
}
