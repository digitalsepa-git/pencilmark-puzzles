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
        String(localized: "Row \(position.row + 1), column \(position.column + 1)")
    }

    // MARK: - Kakuro

    static func kakuroLabel(at position: Position, in puzzle: KakuroPuzzle) -> String {
        switch puzzle.cells[position] {
        case .entry:
            return place(position)
        case .clue(let down, let right):
            var parts = [place(position), String(localized: "clue")]
            if let right {
                parts.append(String(localized: "across \(right)"))
            }
            if let down {
                parts.append(String(localized: "down \(down)"))
            }
            if right == nil, down == nil {
                parts = [place(position), String(localized: "blocked")]
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
            return String(localized: "Empty")
        }
        let list = candidates.map(String.init).joined(separator: ", ")
        return String(localized: "Pencil marks \(list)")
    }

    // MARK: - Calcudoku

    static func calcudokuLabel(at position: Position, in puzzle: CalcudokuPuzzle) -> String {
        let cage = puzzle.cages[puzzle.cageOfCell[puzzle.index(of: position)]]
        let cageText = cageDescription(cage)
        return String(localized: "\(place(position)), cage \(cageText)")
    }

    static func cageDescription(_ cage: CalcudokuCage) -> String {
        switch cage.operation {
        case .given: "\(cage.target)"
        case .add: String(localized: "\(cage.target) plus")
        case .subtract: String(localized: "\(cage.target) minus")
        case .multiply: String(localized: "\(cage.target) times")
        case .divide: String(localized: "\(cage.target) divided")
        }
    }

    // MARK: - Hitori

    static func hitoriLabel(at position: Position, in puzzle: HitoriPuzzle) -> String {
        "\(place(position)), \(puzzle.values[position])"
    }

    static func shadeValue(_ state: ShadeState) -> String {
        switch state {
        case .unknown: String(localized: "Undecided")
        case .shaded: String(localized: "Shaded")
        case .marked: String(localized: "Marked as kept")
        }
    }

    // MARK: - Slitherlink

    static func slitherlinkClueLabel(at cell: Int, in puzzle: SlitherlinkPuzzle) -> String {
        let position = puzzle.position(of: cell)
        guard let clue = puzzle.clue(at: cell) else {
            return String(localized: "\(place(position)), no clue")
        }
        return String(localized: "\(place(position)), clue \(clue)")
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
            ? String(localized: "Horizontal edge between \(from) and \(to)")
            : String(localized: "Vertical edge between \(from) and \(to)")
    }

    static func edgeValue(_ state: EdgeState) -> String {
        switch state {
        case .unknown: String(localized: "Undecided")
        case .line: String(localized: "Line")
        case .cross: String(localized: "Crossed out")
        }
    }

    /// Nokta ızgarası hücre ızgarasından ayrı sayılıyor; karışmasın diye "point" deniyor.
    private static func dot(_ position: Position) -> String {
        String(localized: "point \(position.row + 1), \(position.column + 1)")
    }

    // MARK: - Hashi

    static func hashiIslandLabel(_ island: Int, in puzzle: HashiPuzzle) -> String {
        let model = puzzle.islands[island]
        return String(localized: "\(place(model.position)), island needing \(model.required)")
    }

    static func hashiIslandValue(_ island: Int, board: HashiBoard, in puzzle: HashiPuzzle) -> String {
        let degree = board.degree(ofIsland: island, in: puzzle)
        let required = puzzle.islands[island].required
        if degree == required {
            return String(localized: "\(degree) of \(required), complete")
        }
        return String(localized: "\(degree) of \(required)")
    }

    static func hashiEdgeLabel(_ edge: Int, in puzzle: HashiPuzzle) -> String {
        let model = puzzle.edges[edge]
        let first = puzzle.islands[model.a].position
        let second = puzzle.islands[model.b].position
        let from = place(first)
        let to = place(second)
        return String(localized: "Bridge between \(from) and \(to)")
    }

    static func bridgeValue(_ count: Int) -> String {
        switch count {
        case 0: String(localized: "No bridge")
        case 1: String(localized: "Single bridge")
        default: String(localized: "Double bridge")
        }
    }
}
