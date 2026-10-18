/// Calcudoku'nun kural doğrulayıcısı.
public struct CalcudokuRules: PuzzleRules {
    public typealias Definition = CalcudokuPuzzle
    public typealias Board = CalcudokuBoard
    public typealias Move = CalcudokuMove

    public init() {}

    /// Hamle kurallara uygun mu — doğru olup olmadığını söylemiyor.
    ///
    /// Yalnız ızgara boyutuna sığmayan rakam engelleniyor. Satırda zaten var olan bir
    /// rakamı yazmak engellenmiyor: yanlış ama kurallara uygun ve oyuncunun deneyip görmesi
    /// oyunun kendisi. O durum `violations` ile gösteriliyor.
    public func isLegal(
        _ move: CalcudokuMove,
        on board: CalcudokuBoard,
        in definition: CalcudokuPuzzle
    ) -> Bool {
        guard definition.size.contains(move.position) else { return false }
        guard board[move.position] == move.previous else { return false }
        guard move.next != move.previous else { return false }
        if let value = move.next.value {
            guard (1...definition.side).contains(value) else { return false }
        }
        for digit in move.next.candidates where !(1...definition.side).contains(digit) {
            return false
        }
        return true
    }

    /// Kesin hatalar. Eksik hücre hata değil, tamamlanmamışlık.
    ///
    /// Üç tür: satır veya sütunda tekrar eden rakam, dolu bir kafesin hedefi tutmaması, ve
    /// kısmen dolu bir kafesin hedefe artık ulaşamaması. Üçüncüsü bilerek dahil edildi —
    /// "toplamı 7 olan kafese 5 ve 4 yazmak" en sık yapılan hata ve oyuncunun bunu kafes
    /// tamamen dolmadan görmesi gerekiyor.
    public func violations(
        on board: CalcudokuBoard,
        in definition: CalcudokuPuzzle
    ) -> [Position] {
        var result: [Position] = []
        result.append(contentsOf: duplicatePositions(on: board, in: definition))

        for cage in definition.cages {
            let values = cage.cells.compactMap { board.value(at: definition.position(of: $0)) }
            let complete = values.count == cage.size

            if complete {
                guard !cage.isSatisfied(by: values) else { continue }
            } else {
                guard !values.isEmpty, isUnreachable(cage, filled: values, side: definition.side) else {
                    continue
                }
            }
            result.append(contentsOf: cage.cells.map { definition.position(of: $0) })
        }

        return Array(Set(result)).sorted()
    }

    /// Bütün hücreler dolu, satır ve sütunlar 1..n'in birer kopyası, bütün kafesler tutuyor.
    public func isSolved(_ board: CalcudokuBoard, in definition: CalcudokuPuzzle) -> Bool {
        guard board.isComplete else { return false }
        guard duplicatePositions(on: board, in: definition).isEmpty else { return false }

        for cage in definition.cages {
            let values = cage.cells.map { board.value(at: definition.position(of: $0)) ?? 0 }
            guard cage.isSatisfied(by: values) else { return false }
        }
        return true
    }

    // MARK: - Yardımcılar

    /// Satır veya sütununda aynı rakamı paylaşan hücreler.
    public func duplicatePositions(
        on board: CalcudokuBoard,
        in definition: CalcudokuPuzzle
    ) -> [Position] {
        var result: [Position] = []
        for cell in 0..<definition.cellCount {
            let position = definition.position(of: cell)
            guard let value = board.value(at: position) else { continue }
            for peer in definition.peers[cell]
            where board.value(at: definition.position(of: peer)) == value {
                result.append(position)
                result.append(definition.position(of: peer))
            }
        }
        return result
    }

    /// Kısmen dolu kafes hedefe artık ulaşabilir mi.
    ///
    /// Yalnız kesin olarak imkânsız olan durumlar: toplamada kalan hücrelere en az 1
    /// yazılsa bile hedefin aşılması, çarpmada kısmi çarpımın hedefi bölmemesi, ve iki
    /// hücrelilerde tek değerin hedefi tutturabileceği bir eş bırakmaması.
    func isUnreachable(_ cage: CalcudokuCage, filled: [Int], side: Int) -> Bool {
        let remaining = cage.size - filled.count

        switch cage.operation {
        case .given:
            return false
        case .add:
            let sum = filled.reduce(0, +)
            return sum + remaining > cage.target || sum + remaining * side < cage.target
        case .multiply:
            let product = filled.reduce(1, *)
            return product == 0 || cage.target % product != 0
        case .subtract:
            guard let value = filled.first else { return false }
            return !(1...side).contains(value + cage.target)
                && !(1...side).contains(value - cage.target)
        case .divide:
            guard let value = filled.first else { return false }
            let up = value * cage.target
            let divides = value % cage.target == 0
            return !(1...side).contains(up) && !(divides && (1...side).contains(value / cage.target))
        }
    }
}
