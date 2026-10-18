/// Kafesin işlemi.
///
/// Markalı adlar kullanılmıyor (brief b.4): bu bulmaca uygulama içinde "Calcudoku" ya da
/// "Mathdoku", asla "KenKen".
public enum CageOperation: String, Hashable, Sendable, CaseIterable, Codable {
    /// Tek hücreli kafes: değer doğrudan verilmiş.
    case given
    case add
    case subtract
    case multiply
    case divide

    /// Çıkarma ve bölme yalnız iki hücrede tanımlı: üç sayının "farkı" diye bir şey yok.
    public var requiresExactlyTwoCells: Bool {
        self == .subtract || self == .divide
    }

    /// Arayüzde kafesin köşesinde görünen simge.
    public var symbol: String {
        switch self {
        case .given: ""
        case .add: "+"
        case .subtract: "−"
        case .multiply: "×"
        case .divide: "÷"
        }
    }
}

/// Bir kafes: hücreler, hedef sayı ve işlem.
public struct CalcudokuCage: Hashable, Sendable {
    /// Düz hücre indeksleri, artan sırada. Kanonik sıra, aynı tohumun aynı bulmacayı
    /// vermesi için (ADR 0006).
    public let cells: [Int]
    public let target: Int
    public let operation: CageOperation

    public init(cells: [Int], target: Int, operation: CageOperation) {
        precondition(!cells.isEmpty, "Kafes boş olamaz")
        precondition(target > 0, "Hedef sayı pozitif olmalı")
        if operation.requiresExactlyTwoCells {
            precondition(cells.count == 2, "\(operation) yalnız iki hücreli kafeste tanımlı")
        }
        if operation == .given {
            precondition(cells.count == 1, "given yalnız tek hücreli kafeste")
        }
        self.cells = cells.sorted()
        self.target = target
        self.operation = operation
    }

    public var size: Int { cells.count }

    /// Verilen değerler bu kafesin hedefini tutuyor mu. Değerler hücre sırasıyla gelmiyor;
    /// işlemlerin hiçbiri sıraya duyarlı değil (çıkarma ve bölmede mutlak değer / büyük-küçük).
    public func isSatisfied(by values: [Int]) -> Bool {
        guard values.count == cells.count else { return false }
        switch operation {
        case .given:
            return values[0] == target
        case .add:
            return values.reduce(0, +) == target
        case .multiply:
            return values.reduce(1, *) == target
        case .subtract:
            return abs(values[0] - values[1]) == target
        case .divide:
            let high = max(values[0], values[1])
            let low = min(values[0], values[1])
            return low > 0 && high % low == 0 && high / low == target
        }
    }
}

/// Calcudoku bulmacasının tanımı: kafes bölüntüsü.
///
/// Izgarada verilmiş rakam yok (tek hücreli kafesler hariç); bütün bilgi kafeslerde.
public struct CalcudokuPuzzle: Sendable {
    public let side: Int
    public let cages: [CalcudokuCage]
    /// Hücre indeksi → kafes indeksi.
    public let cageOfCell: [Int]
    /// Hücre indeksi → aynı satır veya sütunu paylaşan hücrelerin indeksleri.
    ///
    /// Çözücü Latin kısıtını bunun üzerinden yayıyor ve her yayılım geçişinde okuyor.
    public let peers: [[Int]]

    public init(side: Int, cages: [CalcudokuCage]) {
        precondition((4...9).contains(side), "Calcudoku kenarı 4...9 aralığında (ADR 0005)")
        self.side = side
        self.cages = cages

        var ownership = [Int](repeating: -1, count: side * side)
        for (index, cage) in cages.enumerated() {
            for cell in cage.cells {
                precondition(ownership[cell] < 0, "\(cell) birden fazla kafeste")
                precondition((0..<side * side).contains(cell), "Kafes ızgara dışında: \(cell)")
                ownership[cell] = index
            }
            precondition(Self.isConnected(cage.cells, side: side), "Kafes bağlı değil: \(cage.cells)")
        }
        precondition(!ownership.contains(-1), "Bazı hücreler hiçbir kafeste değil")
        self.cageOfCell = ownership
        self.peers = Self.buildPeers(side: side)
    }

    public var size: GridSize { GridSize(square: side) }
    public var cellCount: Int { side * side }

    public func index(of position: Position) -> Int {
        position.row * side + position.column
    }

    public func position(of index: Int) -> Position {
        Position(row: index / side, column: index % side)
    }

    public func cage(of cell: Int) -> CalcudokuCage {
        cages[cageOfCell[cell]]
    }

    // MARK: - Türetme ve doğrulama

    /// Kafes hücreleri dört yönlü komşuluktan tek parça mı.
    ///
    /// Kuralların gereği değil ama kafesin ekranda tek bir çerçeve olarak çizilebilmesi
    /// için şart; bağlı olmayan bir kafes oyuncuya iki ayrı kafes gibi görünür.
    ///
    /// Dışa açık: Faz 3'teki öğreticide elle kurulmuş bulmacalar olacak (ADR 0009) ve
    /// onların kafeslerinin de bu kontrolden geçmesi gerekiyor.
    public static func isConnected(_ cells: [Int], side: Int) -> Bool {
        guard let start = cells.first else { return false }
        let members = Set(cells)
        var seen: Set<Int> = [start]
        var stack = [start]

        while let cell = stack.popLast() {
            let row = cell / side
            let column = cell % side
            for (deltaRow, deltaColumn) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                let nextRow = row + deltaRow
                let nextColumn = column + deltaColumn
                guard (0..<side).contains(nextRow), (0..<side).contains(nextColumn) else { continue }
                let neighbor = nextRow * side + nextColumn
                guard members.contains(neighbor), seen.insert(neighbor).inserted else { continue }
                stack.append(neighbor)
            }
        }
        return seen.count == cells.count
    }

    private static func buildPeers(side: Int) -> [[Int]] {
        var result = [[Int]](repeating: [], count: side * side)
        for cell in 0..<(side * side) {
            let row = cell / side
            let column = cell % side
            for other in 0..<side where other != column {
                result[cell].append(row * side + other)
            }
            for other in 0..<side where other != row {
                result[cell].append(other * side + column)
            }
        }
        return result
    }
}

extension CalcudokuPuzzle: Hashable {
    public static func == (lhs: CalcudokuPuzzle, rhs: CalcudokuPuzzle) -> Bool {
        lhs.side == rhs.side && lhs.cages == rhs.cages
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(side)
        hasher.combine(cages)
    }
}
