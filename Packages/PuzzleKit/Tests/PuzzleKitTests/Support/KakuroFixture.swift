import PuzzleKit

// Kakuro bulmacalarını testlerde okunabilir yazmak için metin biçimi ve yardımcılar.
enum KakuroFixture {
    /// Boşlukla ayrılmış simgelerden bulmaca kurar:
    ///
    /// - `.` giriş hücresi
    /// - `#` toplamı olmayan ipucu hücresi
    /// - `A\B` ipucu hücresi: `A` altındaki dikey kesidin, `B` sağındaki yatay kesidin
    ///   toplamı. Biri yoksa o taraf boş bırakılıyor (`8\` yalnız dikey, `\7` yalnız yatay).
    ///
    ///       #   #    8\  15\
    ///       #   \7   .   .
    ///       #   \16  .   .
    static func parse(_ text: String) -> KakuroPuzzle {
        let rows = text
            .split(separator: "\n")
            .map { $0.split(whereSeparator: \.isWhitespace).map(String.init) }
            .filter { !$0.isEmpty }

        guard let width = rows.first?.count else {
            preconditionFailure("Boş bulmaca metni")
        }
        precondition(rows.allSatisfy { $0.count == width }, "Satır uzunlukları eşit değil")

        var cells = Grid(
            size: GridSize(rows: rows.count, columns: width),
            repeating: KakuroCell.entry
        )
        for (row, tokens) in rows.enumerated() {
            for (column, token) in tokens.enumerated() {
                cells[row, column] = cell(from: token)
            }
        }
        return KakuroPuzzle(cells: cells)
    }

    private static func cell(from token: String) -> KakuroCell {
        if token == "." { return .entry }
        if token == "#" { return .clue(down: nil, right: nil) }

        let parts = token.split(separator: "\\", omittingEmptySubsequences: false)
        precondition(parts.count == 2, "Beklenmeyen simge: \(token)")
        return .clue(down: Int(parts[0]), right: Int(parts[1]))
    }

    /// Verilen rakamlardan çözüm kurar. Konumlar `(satır, sütun)`.
    static func solution(for puzzle: KakuroPuzzle, entries: [Position: Int]) -> KakuroSolution {
        var values = Grid(size: puzzle.size, repeating: 0)
        for (position, value) in entries {
            values[position] = value
        }
        return KakuroSolution(values: values)
    }

    /// Dört giriş hücreli, tek çözümlü bulmaca. Sol sütundaki ipucu hücreleri ızgaranın
    /// kenarında değil: kesit türetmenin ızgara ortasındaki ipucu hücrelerini de doğru
    /// okuduğunun testi.
    ///
    /// Çözüm:  1 6 / 7 9
    static var unique2x2: KakuroPuzzle {
        parse("""
        #   #    8\\  15\\
        #   \\7   .    .
        #   \\16  .    .
        """)
    }

    static var unique2x2Solution: KakuroSolution {
        solution(for: unique2x2, entries: [
            Position(row: 1, column: 2): 1,
            Position(row: 1, column: 3): 6,
            Position(row: 2, column: 2): 7,
            Position(row: 2, column: 3): 9
        ])
    }

    /// Aynı yerleşim, bozulmuş toplamlar: satır toplamları 23, sütun toplamları 24.
    /// Çözümü yok ve sebebi tek bir kesitte değil, kesitler arasındaki tutarsızlıkta.
    static var impossible2x2: KakuroPuzzle {
        parse("""
        #   #    9\\  15\\
        #   \\7   .    .
        #   \\16  .    .
        """)
    }

    /// Dolu 3×3 blok: yalnız satır ve sütun toplamlarıyla kısıtlanmış, çok çözümlü.
    ///
    /// Gerçek Kakuro'yu benzersiz yapan şeyin iç siyah hücreler olduğunun testi — dolu bir
    /// blok, toplamlar doğru olsa bile yetmiyor.
    static var ambiguous3x3: KakuroPuzzle {
        parse("""
        #     12\\  15\\  18\\
        \\6    .     .     .
        \\15   .     .     .
        \\24   .     .     .
        """)
    }
}
