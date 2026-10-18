import PuzzleKit

// Hitori bulmacalarını testlerde okunabilir yazmak için metin biçimi.
// Rakamlar hücre değerleri; boşluklar yok sayılıyor, ızgara testte kare görünüyor.
enum HitoriFixture {
    static func parse(_ text: String) -> HitoriPuzzle {
        let lines = text
            .split(separator: "\n")
            .map { $0.filter { !$0.isWhitespace } }
            .filter { !$0.isEmpty }

        guard let width = lines.first?.count else {
            preconditionFailure("Boş bulmaca metni")
        }
        var elements: [Int] = []
        for line in lines {
            precondition(line.count == width, "Satır uzunlukları eşit değil: \(line)")
            for character in line {
                guard let value = character.wholeNumberValue, (1...9).contains(value) else {
                    preconditionFailure("Beklenmeyen karakter: \(character)")
                }
                elements.append(value)
            }
        }

        return HitoriPuzzle(
            values: Grid(size: GridSize(rows: lines.count, columns: width), elements: elements)
        )
    }

    /// Elle kurulmuş 4×4. Beyazlar bir Latin karesinden geliyor, karalanacak üç hücrenin
    /// değeri satır veya sütundaki bir beyazı tekrarlıyor — yani üretici algoritmasının
    /// (ADR 0011) elle yapılmış hali.
    ///
    /// Amaçlanan çözüm: (0,0), (1,2) ve (3,3) karalı.
    static var handmade4x4: HitoriPuzzle {
        parse("""
        3 2 3 4
        2 3 1 1
        3 4 1 2
        4 1 2 4
        """)
    }

    /// Çözümü olmayan en küçük bulmaca.
    ///
    /// Dört hücre de aynı değerde. Her satırda ve her sütunda en fazla bir beyaz kalabilir,
    /// komşu iki hücre birden karalanamaz — bu ikisi birlikte beyazları köşegene zorluyor
    /// ve köşegendeki iki hücre komşu olmadığı için beyaz bölge kopuk kalıyor.
    static var impossible2x2: HitoriPuzzle {
        parse("""
        1 1
        1 1
        """)
    }

    /// Yan yana üç aynı sayı: ortadaki beyaz, dıştakiler karalı olmak zorunda.
    ///
    /// Klasik "üçlü" kuralının testi ve tek grubu olan en küçük benzersiz bulmaca.
    /// Alt satırlar tekrar içermiyor, tek işleri beyaz bölgeyi bağlı tutmak — tek satırlık
    /// bir ızgarada herhangi bir karalama beyazları kopardığı için çözüm olmazdı.
    static var triple3x5: HitoriPuzzle {
        parse("""
        2 1 1 1 3
        4 5 6 7 8
        9 2 3 4 5
        """)
    }
}
