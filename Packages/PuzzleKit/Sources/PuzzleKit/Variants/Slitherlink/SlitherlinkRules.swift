/// Slitherlink'in kural doğrulayıcısı.
public struct SlitherlinkRules: PuzzleRules {
    public typealias Definition = SlitherlinkPuzzle
    public typealias Board = SlitherlinkBoard
    public typealias Move = SlitherlinkMove

    public init() {}

    /// Her hamle kurallara uygun.
    ///
    /// Hitori'deki gibi: üç çizgiyi aynı noktada birleştirmek mümkün, yalnız yanlış.
    /// Bütün hatalar `violations` ile gösteriliyor.
    public func isLegal(
        _ move: SlitherlinkMove,
        on board: SlitherlinkBoard,
        in definition: SlitherlinkPuzzle
    ) -> Bool {
        guard (0..<definition.edgeCount).contains(move.edge) else { return false }
        guard board[move.edge] == move.previous else { return false }
        return move.next != move.previous
    }

    /// Kesin hatalar, hücre konumu olarak.
    ///
    /// Üç tür: ipucunu aşan ya da artık tutturamayacak hücre, derecesi üçe çıkan nokta, ve
    /// tamamlanmış tahtada birden fazla döngü.
    ///
    /// Nokta hataları, o noktaya değen hücrelerin konumu olarak bildiriliyor. `PuzzleRules`
    /// hücre konumu döndürüyor ve nokta ızgarası hücre ızgarasından farklı — noktayı hücre
    /// konumu gibi döndürmek arayüzde yanlış yeri işaretlerdi.
    public func violations(
        on board: SlitherlinkBoard,
        in definition: SlitherlinkPuzzle
    ) -> [Position] {
        var result: [Position] = []

        for cell in definition.cluedCells {
            guard let clue = definition.clue(at: cell) else { continue }
            let lines = board.lineCount(ofCell: cell, in: definition)
            let unknown = board.unknownCount(ofCell: cell, in: definition)
            if lines > clue || lines + unknown < clue {
                result.append(definition.position(of: cell))
            }
        }

        for dot in 0..<definition.dotCount where board.degree(ofDot: dot, in: definition) > 2 {
            result.append(contentsOf: cells(around: dot, in: definition))
        }

        if board.isComplete, result.isEmpty, loopCount(on: board, in: definition) != 1 {
            // Tamamlanmış ama tek döngü değil: çizgili kenarların dokunduğu bütün hücreler.
            for cell in 0..<definition.cellCount
            where definition.edgesOfCell[cell].contains(where: { board[$0] == .line }) {
                result.append(definition.position(of: cell))
            }
        }

        return Array(Set(result)).sorted()
    }

    /// Üç şey birlikte: her noktanın derecesi 0 veya 2, bütün ipuçlar tutuyor, çizgiler
    /// tek bir kapalı döngü.
    public func isSolved(_ board: SlitherlinkBoard, in definition: SlitherlinkPuzzle) -> Bool {
        for dot in 0..<definition.dotCount {
            let degree = board.degree(ofDot: dot, in: definition)
            guard degree == 0 || degree == 2 else { return false }
        }
        for cell in definition.cluedCells {
            guard let clue = definition.clue(at: cell) else { continue }
            guard board.lineCount(ofCell: cell, in: definition) == clue else { return false }
        }
        return loopCount(on: board, in: definition) == 1
    }

    // MARK: - Yardımcılar

    /// Çizgili kenarların oluşturduğu bağlı bileşen sayısı.
    ///
    /// Bütün noktaların derecesi 0 veya 2 ise çizgi kümesi ayrık döngülerin birleşimidir;
    /// o zaman bileşen sayısı döngü sayısına eşit. Derece koşulu sağlanmadığında bu sayı
    /// döngü sayısı değil, yalnız "kaç parça" — `isSolved` derece kontrolünü önce yapıyor.
    public func loopCount(on board: SlitherlinkBoard, in definition: SlitherlinkPuzzle) -> Int {
        var seen = [Bool](repeating: false, count: definition.dotCount)
        var components = 0

        for start in 0..<definition.dotCount
        where !seen[start] && board.degree(ofDot: start, in: definition) > 0 {
            components += 1
            var stack = [start]
            seen[start] = true
            while let dot = stack.popLast() {
                for edge in definition.edgesOfDot[dot] where board[edge] == .line {
                    let ends = definition.endpointsOfEdge[edge]
                    let other = ends.first == dot ? ends.second : ends.first
                    guard !seen[other] else { continue }
                    seen[other] = true
                    stack.append(other)
                }
            }
        }
        return components
    }

    /// Noktaya değen hücrelerin konumları (köşede 1, kenarda 2, içte 4).
    private func cells(around dot: Int, in definition: SlitherlinkPuzzle) -> [Position] {
        let dotPosition = definition.dotPosition(of: dot)
        var result: [Position] = []
        for rowOffset in [-1, 0] {
            for columnOffset in [-1, 0] {
                let candidate = Position(
                    row: dotPosition.row + rowOffset,
                    column: dotPosition.column + columnOffset
                )
                if definition.size.contains(candidate) {
                    result.append(candidate)
                }
            }
        }
        return result
    }
}
