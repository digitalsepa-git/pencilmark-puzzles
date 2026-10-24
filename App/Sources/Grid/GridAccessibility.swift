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
        "Row \(position.row + 1), column \(position.column + 1)"
    }

    // MARK: - Kakuro

    static func kakuroLabel(at position: Position, in puzzle: KakuroPuzzle) -> String {
        switch puzzle.cells[position] {
        case .entry:
            return place(position)
        case .clue(let down, let right):
            var parts = [place(position), "clue"]
            if let right {
                parts.append("across \(right)")
            }
            if let down {
                parts.append("down \(down)")
            }
            if right == nil, down == nil {
                parts = [place(position), "blocked"]
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
            return "Empty"
        }
        return "Pencil marks \(candidates.map(String.init).joined(separator: ", "))"
    }

    // MARK: - Calcudoku

    static func calcudokuLabel(at position: Position, in puzzle: CalcudokuPuzzle) -> String {
        let cage = puzzle.cages[puzzle.cageOfCell[puzzle.index(of: position)]]
        return "\(place(position)), cage \(cageDescription(cage))"
    }

    static func cageDescription(_ cage: CalcudokuCage) -> String {
        switch cage.operation {
        case .given: "\(cage.target)"
        case .add: "\(cage.target) plus"
        case .subtract: "\(cage.target) minus"
        case .multiply: "\(cage.target) times"
        case .divide: "\(cage.target) divided"
        }
    }

    // MARK: - Hitori

    static func hitoriLabel(at position: Position, in puzzle: HitoriPuzzle) -> String {
        "\(place(position)), \(puzzle.values[position])"
    }

    static func shadeValue(_ state: ShadeState) -> String {
        switch state {
        case .unknown: "Undecided"
        case .shaded: "Shaded"
        case .marked: "Marked as kept"
        }
    }

    // MARK: - Slitherlink

    static func slitherlinkClueLabel(at cell: Int, in puzzle: SlitherlinkPuzzle) -> String {
        let position = puzzle.position(of: cell)
        guard let clue = puzzle.clue(at: cell) else {
            return "\(place(position)), no clue"
        }
        return "\(place(position)), clue \(clue)"
    }

    /// Kenar, iki ucunun arasındaki yer olarak anlatılıyor: "between row 1 column 1 and
    /// row 1 column 2". Kenar indeksini okumak VoiceOver kullanıcısına hiçbir şey
    /// söylemezdi.
    static func slitherlinkEdgeLabel(_ edge: Int, in puzzle: SlitherlinkPuzzle) -> String {
        let endpoints = puzzle.endpointsOfEdge[edge]
        let first = puzzle.dotPosition(of: endpoints.first)
        let second = puzzle.dotPosition(of: endpoints.second)
        let direction = puzzle.isHorizontal(edge) ? "Horizontal" : "Vertical"
        return "\(direction) edge between \(dot(first)) and \(dot(second))"
    }

    static func edgeValue(_ state: EdgeState) -> String {
        switch state {
        case .unknown: "Undecided"
        case .line: "Line"
        case .cross: "Crossed out"
        }
    }

    /// Nokta ızgarası hücre ızgarasından ayrı sayılıyor; karışmasın diye "point" deniyor.
    private static func dot(_ position: Position) -> String {
        "point \(position.row + 1), \(position.column + 1)"
    }

    // MARK: - Hashi

    static func hashiIslandLabel(_ island: Int, in puzzle: HashiPuzzle) -> String {
        let model = puzzle.islands[island]
        return "\(place(model.position)), island needing \(model.required)"
    }

    static func hashiIslandValue(_ island: Int, board: HashiBoard, in puzzle: HashiPuzzle) -> String {
        let degree = board.degree(ofIsland: island, in: puzzle)
        let required = puzzle.islands[island].required
        if degree == required {
            return "\(degree) of \(required), complete"
        }
        return "\(degree) of \(required)"
    }

    static func hashiEdgeLabel(_ edge: Int, in puzzle: HashiPuzzle) -> String {
        let model = puzzle.edges[edge]
        let first = puzzle.islands[model.a].position
        let second = puzzle.islands[model.b].position
        return "Bridge between \(place(first)) and \(place(second))"
    }

    static func bridgeValue(_ count: Int) -> String {
        switch count {
        case 0: "No bridge"
        case 1: "Single bridge"
        default: "Double bridge"
        }
    }
}
