/// Kakuro'nun kural doğrulayıcısı.
public struct KakuroRules: PuzzleRules {
    public typealias Definition = KakuroPuzzle
    public typealias Board = KakuroBoard
    public typealias Move = KakuroMove

    public init() {}

    /// Hamle kurallara uygun mu.
    ///
    /// İpucu hücresine yazmak engelleniyor (orada oynanacak bir şey yok) ve 1-9 dışı rakam
    /// engelleniyor. Kesitte zaten var olan rakamı yazmak engellenmiyor: yanlış ama kurallara
    /// uygun, ve `violations` ile gösteriliyor.
    public func isLegal(
        _ move: KakuroMove,
        on board: KakuroBoard,
        in definition: KakuroPuzzle
    ) -> Bool {
        guard definition.size.contains(move.position) else { return false }
        guard definition.cells[move.position].isEntry else { return false }
        guard board[move.position] == move.previous else { return false }
        guard move.next != move.previous else { return false }
        if let value = move.next.value {
            guard (1...9).contains(value) else { return false }
        }
        for digit in move.next.candidates where !(1...9).contains(digit) {
            return false
        }
        return true
    }

    /// Kesin hatalar. Eksik hücre hata değil, tamamlanmamışlık.
    ///
    /// Üç tür: kesit içinde tekrar eden rakam, dolu bir kesitin toplamı tutmaması, ve kısmen
    /// dolu bir kesitin toplama artık ulaşamaması. Üçüncüsü Calcudoku'dakiyle aynı gerekçeyle
    /// dahil: oyuncunun hatayı kesit tamamen dolmadan görmesi gerekiyor.
    public func violations(
        on board: KakuroBoard,
        in definition: KakuroPuzzle
    ) -> [Position] {
        var result: [Position] = []

        for run in definition.runs {
            let values = run.cells.compactMap { board.value(at: definition.position(of: $0)) }

            if Set(values).count != values.count {
                result.append(contentsOf: run.cells.map { definition.position(of: $0) })
                continue
            }

            if values.count == run.length {
                guard values.reduce(0, +) != run.sum else { continue }
            } else {
                guard !values.isEmpty, isUnreachable(run, filled: values) else { continue }
            }
            result.append(contentsOf: run.cells.map { definition.position(of: $0) })
        }

        return Array(Set(result)).sorted()
    }

    /// Bütün giriş hücreleri dolu ve her kesit tekrarsız biçimde toplamını tutuyor.
    public func isSolved(_ board: KakuroBoard, in definition: KakuroPuzzle) -> Bool {
        guard board.isComplete(in: definition) else { return false }

        for run in definition.runs {
            let values = run.cells.map { board.value(at: definition.position(of: $0)) ?? 0 }
            guard Set(values).count == values.count else { return false }
            guard values.reduce(0, +) == run.sum else { return false }
        }
        return true
    }

    // MARK: - Yardımcılar

    /// Kısmen dolu kesit toplamına artık ulaşabilir mi.
    ///
    /// Kalan hücrelere yazılabilecek en küçük ve en büyük toplam, kullanılmamış rakamlardan
    /// hesaplanıyor: kesit içinde tekrar yasak olduğu için "kalan hücre sayısı × 1" sınırı
    /// gevşek kalırdı.
    func isUnreachable(_ run: KakuroRun, filled: [Int]) -> Bool {
        let used = DigitSet(filled)
        let remaining = run.length - filled.count
        guard remaining > 0 else { return false }

        let available = DigitSet.all.subtracting(used).sorted()
        guard available.count >= remaining else { return true }

        let partial = filled.reduce(0, +)
        let smallest = available.prefix(remaining).reduce(0, +)
        let largest = available.suffix(remaining).reduce(0, +)
        return partial + smallest > run.sum || partial + largest < run.sum
    }
}
