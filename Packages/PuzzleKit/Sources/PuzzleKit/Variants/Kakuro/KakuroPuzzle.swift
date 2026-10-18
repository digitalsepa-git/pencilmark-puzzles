/// Kakuro ızgarasındaki bir hücre.
public enum KakuroCell: Hashable, Sendable {
    /// İpucu hücresi (siyah). Sağındaki yatay kesitin ve altındaki dikey kesitin
    /// toplamlarını taşıyor; biri yoksa `nil`.
    case clue(down: Int?, right: Int?)
    /// Giriş hücresi (beyaz). Oyuncu 1-9 arası bir rakam yazıyor.
    case entry

    public var isEntry: Bool {
        self == .entry
    }
}

/// Bir kesit: ipucu toplamının geçerli olduğu hücre dizisi.
///
/// Türkçe "kesit", kodda `run` (bkz. `docs/terimler.md`).
public struct KakuroRun: Hashable, Sendable {
    /// Düz hücre indeksleri, kesit boyunca sırayla.
    public let cells: [Int]
    public let sum: Int
    public let isHorizontal: Bool

    public var length: Int { cells.count }
}

/// Kakuro bulmacasının tanımı.
///
/// Kesitler ve hücre→kesit eşlemesi kurucuda bir kez türetiliyor; çözücü bunları
/// milyonlarca kez okuyacak.
public struct KakuroPuzzle: Sendable {
    public let size: GridSize
    public let cells: Grid<KakuroCell>

    public let runs: [KakuroRun]
    /// Hücre indeksi → üyesi olduğu kesit indeksleri. Giriş hücrelerinde tam iki tane
    /// (bir yatay, bir dikey); ipucu hücrelerinde boş.
    public let runsOfCell: [[Int]]
    /// Giriş hücrelerinin indeksleri, artan sırada.
    public let entryCells: [Int]

    public init(cells: Grid<KakuroCell>) {
        self.size = cells.size
        self.cells = cells
        self.runs = Self.buildRuns(cells: cells)

        var membership = [[Int]](repeating: [], count: cells.size.cellCount)
        for (index, run) in runs.enumerated() {
            for cell in run.cells {
                membership[cell].append(index)
            }
        }
        self.runsOfCell = membership
        self.entryCells = cells.allPositions
            .filter { cells[$0].isEntry }
            .map { $0.row * cells.size.columns + $0.column }

        for cell in entryCells {
            // Her giriş hücresi bir yatay ve bir dikey kesite ait olmak zorunda. Tek kesite
            // ait bir hücre, o yönde tek başına kalmış demek ve o kesit tek hücreli olurdu —
            // yani rakam doğrudan ipucunda yazılı olurdu, bulmaca değil.
            precondition(
                membership[cell].count == 2,
                "Giriş hücresi \(cell) iki kesite ait değil (\(membership[cell].count))"
            )
        }
        for run in runs {
            precondition((2...9).contains(run.length), "Kesit uzunluğu 2-9 dışında: \(run.length)")
            precondition(
                Self.isSumFeasible(run.sum, length: run.length),
                "Kesit toplamı \(run.sum) uzunluk \(run.length) için imkânsız"
            )
        }
    }

    public var entryCount: Int { entryCells.count }

    public func index(of position: Position) -> Int {
        position.row * size.columns + position.column
    }

    public func position(of index: Int) -> Position {
        Position(row: index / size.columns, column: index % size.columns)
    }

    public func isEntry(_ index: Int) -> Bool {
        cells.elements[index].isEntry
    }

    /// Verilen uzunlukta tekrarsız 1-9 rakamlarıyla bu toplama ulaşılabilir mi.
    ///
    /// En küçük toplam `1+2+...+k`, en büyük `9+8+...`. Üretici ve kurucu doğrulaması
    /// bunu kullanıyor; kesit araması da erken kesme için.
    public static func isSumFeasible(_ sum: Int, length: Int) -> Bool {
        guard (1...9).contains(length) else { return false }
        let minimum = length * (length + 1) / 2
        let maximum = length * (19 - length) / 2
        return (minimum...maximum).contains(sum)
    }

    // MARK: - Türetme

    private static func buildRuns(cells: Grid<KakuroCell>) -> [KakuroRun] {
        var result: [KakuroRun] = []
        let size = cells.size

        // Yatay kesitler: her ipucu hücresinin sağındaki kesintisiz giriş hücreleri.
        for row in 0..<size.rows {
            for column in 0..<size.columns {
                guard case .clue(_, let right) = cells[row, column], let sum = right else { continue }
                var members: [Int] = []
                var scan = column + 1
                while scan < size.columns, cells[row, scan].isEntry {
                    members.append(row * size.columns + scan)
                    scan += 1
                }
                result.append(KakuroRun(cells: members, sum: sum, isHorizontal: true))
            }
        }

        // Dikey kesitler.
        for column in 0..<size.columns {
            for row in 0..<size.rows {
                guard case .clue(let down, _) = cells[row, column], let sum = down else { continue }
                var members: [Int] = []
                var scan = row + 1
                while scan < size.rows, cells[scan, column].isEntry {
                    members.append(scan * size.columns + column)
                    scan += 1
                }
                result.append(KakuroRun(cells: members, sum: sum, isHorizontal: false))
            }
        }

        // Kanonik sıra: kesit indeksleri tanımdan deterministik türemeli (ADR 0006).
        return result.sorted {
            ($0.isHorizontal ? 0 : 1, $0.cells.first ?? -1) < ($1.isHorizontal ? 0 : 1, $1.cells.first ?? -1)
        }
    }
}

extension KakuroPuzzle: Hashable {
    public static func == (lhs: KakuroPuzzle, rhs: KakuroPuzzle) -> Bool {
        lhs.cells == rhs.cells
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cells)
    }
}
