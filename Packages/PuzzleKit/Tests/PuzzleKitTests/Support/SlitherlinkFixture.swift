import PuzzleKit

// Slitherlink bulmacalarını testlerde okunabilir yazmak için metin biçimi.
// Rakamlar ipucu, nokta ipucu olmayan hücre. Boşluklar yok sayılıyor.
enum SlitherlinkFixture {
    static func parse(_ text: String) -> SlitherlinkPuzzle {
        let lines = text
            .split(separator: "\n")
            .map { $0.filter { !$0.isWhitespace } }
            .filter { !$0.isEmpty }

        guard let width = lines.first?.count else {
            preconditionFailure("Boş bulmaca metni")
        }
        var elements: [Int?] = []
        for line in lines {
            precondition(line.count == width, "Satır uzunlukları eşit değil: \(line)")
            for character in line {
                if character == "." {
                    elements.append(nil)
                } else if let value = character.wholeNumberValue, (0...3).contains(value) {
                    elements.append(value)
                } else {
                    preconditionFailure("Beklenmeyen karakter: \(character)")
                }
            }
        }

        return SlitherlinkPuzzle(
            clues: Grid(size: GridSize(rows: lines.count, columns: width), elements: elements)
        )
    }

    /// En küçük Slitherlink: döngü 2×2 bloğun dış kenarı, dört hücrenin de ikisi onda.
    ///
    /// 1×1 ızgara kurulamıyor, çünkü tek hücreli döngü o hücreye 4 ipucu verirdi ve 4
    /// yalnız dejenere durumda mümkün (dört köşe derece 2'ye dolar, başka kenar kalmaz).
    static var square2x2: SlitherlinkPuzzle {
        parse("""
        2 2
        2 2
        """)
    }

    /// Döngü sol üstteki 2×2 bloğun çevresi; kalan hücreler ona değdiği kadar ipucu taşıyor.
    static var block3x3: SlitherlinkPuzzle {
        parse("""
        2 2 1
        2 2 1
        1 1 0
        """)
    }

    /// Bütün ipuçlar 3: her hücrenin üç kenarı çizgi olmak zorunda ve bu noktalarda
    /// derece 3'e çıkıyor. Çözümü yok.
    static var impossible2x2: SlitherlinkPuzzle {
        parse("""
        3 3
        3 3
        """)
    }

    /// Tek ipucu: döngünün nereden geçeceğini belirlemeye yetmiyor.
    static var ambiguous3x3: SlitherlinkPuzzle {
        parse("""
        . . .
        . 2 .
        . . .
        """)
    }
}
