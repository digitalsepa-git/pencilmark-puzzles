import Foundation
import PuzzleKit

/// Izgaraların VoiceOver metinleri.
///
/// Saf fonksiyonlar: `Canvas` çizimi VoiceOver'a hiçbir şey vermiyor, bu yüzden ızgaranın
/// mantıksal yapısı ayrıca bildirilmek zorunda ve bildirilen metnin doğruluğu gözle
/// kontrol edilemiyor. Burada durmalarının sebebi bu — test edilebilir olmaları.
///
/// Konumlar insan için 1'den başlıyor: "Row 1, column 1" VoiceOver kullanıcısının
/// ızgarada nerede olduğunu sayarak takip etmesini sağlıyor.
enum GridAccessibility {
    static func place(_ position: Position) -> String {
        localized("Row \(position.row + 1), column \(position.column + 1)")
    }

    // MARK: - Kakuro

    static func kakuroLabel(at position: Position, in puzzle: KakuroPuzzle) -> String {
        switch puzzle.cells[position] {
        case .entry:
            return place(position)
        case .clue(let down, let right):
            var parts = [place(position), localized("clue")]
            if let right {
                parts.append(localized("across \(right)"))
            }
            if let down {
                parts.append(localized("down \(down)"))
            }
            if right == nil, down == nil {
                parts = [place(position), localized("blocked")]
            }
            return parts.joined(separator: ", ")
        }
    }

    static func digitValue(_ cell: DigitCell, upTo maximum: Int = 9) -> String {
        if let value = cell.value {
            return "\(value)"
        }
        let candidates = (1...maximum).filter { cell.candidates.contains($0) }
        if candidates.isEmpty {
            return localized("Empty")
        }
        let list = candidates.map(String.init).joined(separator: ", ")
        return localized("Pencil marks \(list)")
    }

    // MARK: - Calcudoku

    static func calcudokuLabel(at position: Position, in puzzle: CalcudokuPuzzle) -> String {
        let cage = puzzle.cages[puzzle.cageOfCell[puzzle.index(of: position)]]
        let cageText = cageDescription(cage)
        return localized("\(place(position)), cage \(cageText)")
    }

    static func cageDescription(_ cage: CalcudokuCage) -> String {
        switch cage.operation {
        case .given: "\(cage.target)"
        case .add: localized("\(cage.target) plus")
        case .subtract: localized("\(cage.target) minus")
        case .multiply: localized("\(cage.target) times")
        case .divide: localized("\(cage.target) divided")
        }
    }

    // MARK: - Hitori

    static func hitoriLabel(at position: Position, in puzzle: HitoriPuzzle) -> String {
        "\(place(position)), \(puzzle.values[position])"
    }

    static func shadeValue(_ state: ShadeState) -> String {
        switch state {
        case .unknown: localized("Undecided")
        case .shaded: localized("Shaded")
        case .marked: localized("Marked as kept")
        }
    }

    // MARK: - Slitherlink

    static func slitherlinkClueLabel(at cell: Int, in puzzle: SlitherlinkPuzzle) -> String {
        let position = puzzle.position(of: cell)
        guard let clue = puzzle.clue(at: cell) else {
            return localized("\(place(position)), no clue")
        }
        return localized("\(place(position)), clue \(clue)")
    }

    /// Kenar, iki ucunun arasındaki yer olarak anlatılıyor: "between row 1 column 1 and
    /// row 1 column 2". Kenar indeksini okumak VoiceOver kullanıcısına hiçbir şey
    /// söylemezdi.
    static func slitherlinkEdgeLabel(_ edge: Int, in puzzle: SlitherlinkPuzzle) -> String {
        let endpoints = puzzle.endpointsOfEdge[edge]
        let first = puzzle.dotPosition(of: endpoints.first)
        let second = puzzle.dotPosition(of: endpoints.second)
        let from = dot(first)
        let to = dot(second)
        return puzzle.isHorizontal(edge)
            ? localized("Horizontal edge between \(from) and \(to)")
            : localized("Vertical edge between \(from) and \(to)")
    }

    static func edgeValue(_ state: EdgeState) -> String {
        switch state {
        case .unknown: localized("Undecided")
        case .line: localized("Line")
        case .cross: localized("Crossed out")
        }
    }

    /// Nokta ızgarası hücre ızgarasından ayrı sayılıyor; karışmasın diye "point" deniyor.
    private static func dot(_ position: Position) -> String {
        localized("point \(position.row + 1), \(position.column + 1)")
    }

    // MARK: - Hashi

    static func hashiIslandLabel(_ island: Int, in puzzle: HashiPuzzle) -> String {
        let model = puzzle.islands[island]
        return localized("\(place(model.position)), island needing \(model.required)")
    }

    static func hashiIslandValue(_ island: Int, board: HashiBoard, in puzzle: HashiPuzzle) -> String {
        let degree = board.degree(ofIsland: island, in: puzzle)
        let required = puzzle.islands[island].required
        if degree == required {
            return localized("\(degree) of \(required), complete")
        }
        return localized("\(degree) of \(required)")
    }

    static func hashiEdgeLabel(_ edge: Int, in puzzle: HashiPuzzle) -> String {
        let model = puzzle.edges[edge]
        let first = puzzle.islands[model.a].position
        let second = puzzle.islands[model.b].position
        let from = place(first)
        let to = place(second)
        return localized("Bridge between \(from) and \(to)")
    }

    static func bridgeValue(_ count: Int) -> String {
        switch count {
        case 0: localized("No bridge")
        case 1: localized("Single bridge")
        default: localized("Double bridge")
        }
    }
}
