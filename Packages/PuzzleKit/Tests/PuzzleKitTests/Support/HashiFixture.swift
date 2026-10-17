import PuzzleKit

/// Testlerde konum yazmayı kısaltıyor: `pos(0, 2)` yerine uzun kurucu satırları
/// 110 karakter sınırını aşıyordu.
func pos(_ row: Int, _ column: Int) -> Position {
    Position(row: row, column: column)
}

// Hashi bulmacalarını testlerde okunabilir yazmak için metin biçimi.
//
// Rakamlar ada ve derecesi, nokta boş hücre. Satırlar eşit uzunlukta olmak zorunda.
// Boşluklar yok sayılıyor, böylece ızgara testte kare görünüyor:
//
//     2 . 2
//     . . .
//     2 . 2
enum HashiFixture {
    static func parse(_ text: String) -> HashiPuzzle {
        let lines = text
            .split(separator: "\n")
            .map { $0.filter { !$0.isWhitespace } }
            .filter { !$0.isEmpty }

        guard let width = lines.first?.count else {
            preconditionFailure("Boş bulmaca metni")
        }
        for line in lines {
            precondition(line.count == width, "Satır uzunlukları eşit değil: \(line)")
        }

        var islands: [HashiIsland] = []
        for (row, line) in lines.enumerated() {
            for (column, character) in line.enumerated() {
                if let value = character.wholeNumberValue, (1...8).contains(value) {
                    islands.append(
                        HashiIsland(position: Position(row: row, column: column), required: value)
                    )
                } else {
                    precondition(character == ".", "Beklenmeyen karakter: \(character)")
                }
            }
        }

        return HashiPuzzle(
            size: GridSize(rows: lines.count, columns: width),
            islands: islands
        )
    }

    /// Kenar indeksini uç adaların konumundan bulur. Testte indeks sabitleri yazmaktan
    /// kaçınmak için: kenar sıralaması değişirse testler yanlış yeri göstermesin.
    static func edge(
        _ puzzle: HashiPuzzle,
        from first: Position,
        to second: Position
    ) -> Int {
        guard
            let a = puzzle.island(at: first),
            let b = puzzle.island(at: second)
        else {
            preconditionFailure("Konumlarda ada yok: \(first), \(second)")
        }
        guard let index = puzzle.edges.firstIndex(where: {
            ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a)
        }) else {
            preconditionFailure("\(first) ile \(second) arasında kenar yok")
        }
        return index
    }

    /// Dört adanın köşelerde durduğu, çözümü tek bir kare döngü olan 3×3 bulmaca.
    ///
    /// Küçük ama öğretici: yalnız derecelere bakan bir çözücü burada iki çözüm bulur
    /// (karşılıklı iki kenara çifte köprü), ama o dizilim ağı ikiye ayırıyor. Bağlılık
    /// kısıtının testi bu bulmaca.
    static var loop3x3: HashiPuzzle {
        parse("""
        2 . 2
        . . .
        2 . 2
        """)
    }

    /// Üç çözümü olan simetrik bulmaca. Benzersizlik elemesinin testi.
    ///
    /// Köşeler 2, kenar ortaları 3. Dikey ve yatay köprüler arasında serbestlik kalıyor:
    /// hem tek köprülerle çevrilen bir çerçeve, hem çifte köprülerle kurulan iki ayrı
    /// dizilim geçerli. Hat böyle bir adayı elemek zorunda.
    static var ambiguous5x5: HashiPuzzle {
        parse("""
        2 . 3 . 2
        . . . . .
        . . . . .
        . . . . .
        2 . 3 . 2
        """)
    }

    /// Ortadaki ada dört komşusundan toplam 8 köprü almak zorunda kalıyor ama derecesi 4.
    /// Çözümü yok; kenar kapasitesi ve derece kısıtının birlikte çalıştığının testi.
    static var impossiblePlus5x5: HashiPuzzle {
        parse("""
        . . 2 . .
        . . . . .
        2 . 4 . 2
        . . . . .
        . . 2 . .
        """)
    }

    /// Ortada kesişmek zorunda kalan iki köprü. Çözümü yok.
    static var crossing5x5: HashiPuzzle {
        parse("""
        . . 1 . .
        . . . . .
        1 . . . 1
        . . . . .
        . . 1 . .
        """)
    }
}
