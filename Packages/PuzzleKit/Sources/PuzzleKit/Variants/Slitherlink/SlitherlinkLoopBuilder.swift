// Rastgele tek kapalı döngü kurulumu.
//
// Doğrudan kenar seçerek döngü kurmak zor: her noktanın derecesini 0 ya da 2 tutmak ve
// tek parça kalmak gerekiyor. Bunun yerine **içteki hücre kümesi** kuruluyor ve döngü o
// kümenin sınırı oluyor.
//
// Bir hücre kümesinin sınırının tek kapalı döngü olması iki koşula denk:
// - küme bağlı ve **deliksiz** (dışı da bağlı) — delik ikinci bir döngü demek,
// - hiçbir nokta derece 4 olmuyor — köşe köşeye değen iki iç hücre o noktada dört kenar
//   üretiyor ve döngü orada kendisiyle kesişiyor.
//
// İkisi sağlandığında sınır kendiliğinden tek döngü.
public enum SlitherlinkLoopBuilder {
    /// İçteki hücreleri büyüterek rastgele bir döngü kuruyor.
    ///
    /// `nil` döndürmesi: hedef büyüklüğe ulaşılamadı. Çağıran yeni bir tohumla denemeli.
    public static func inside(
        size: GridSize,
        target: Int,
        using rng: inout SeededGenerator
    ) -> Set<Int>? {
        precondition(target >= 4, "Döngünün içinde en az dört hücre olmalı")
        guard size.rows >= 2, size.columns >= 2 else { return nil }

        // Çekirdek 2×2: tek hücreyle başlamak derece 4 kontrolünü gereksiz zorlaştırıyor
        // ve ilk büyümelerde sık sık tıkanıyor.
        let row = Int.random(in: 0..<(size.rows - 1), using: &rng)
        let column = Int.random(in: 0..<(size.columns - 1), using: &rng)
        var inside: Set<Int> = [
            row * size.columns + column,
            row * size.columns + column + 1,
            (row + 1) * size.columns + column,
            (row + 1) * size.columns + column + 1
        ]

        var attempts = 0
        let limit = target * 60

        while inside.count < target && attempts < limit {
            attempts += 1
            var candidates = frontier(of: inside, size: size)
            guard !candidates.isEmpty else { break }
            candidates.shuffle(using: &rng)

            var grew = false
            for candidate in candidates {
                inside.insert(candidate)
                if isValid(inside, size: size) {
                    grew = true
                    break
                }
                inside.remove(candidate)
            }
            guard grew else { break }
        }

        return inside.count >= 4 ? inside : nil
    }

    /// İçteki kümeye komşu, kümede olmayan hücreler.
    static func frontier(of inside: Set<Int>, size: GridSize) -> [Int] {
        var result = Set<Int>()
        for cell in inside {
            let position = Position(row: cell / size.columns, column: cell % size.columns)
            for neighbor in position.orthogonalNeighbors where size.contains(neighbor) {
                let index = neighbor.row * size.columns + neighbor.column
                if !inside.contains(index) { result.insert(index) }
            }
        }
        return result.sorted()
    }

    /// Kümenin sınırı tek kapalı döngü mü.
    public static func isValid(_ inside: Set<Int>, size: GridSize) -> Bool {
        guard inside.count >= 4 else { return false }
        guard isConnected(inside, size: size) else { return false }
        guard isOutsideConnected(inside, size: size) else { return false }
        return !hasPinchedDot(inside, size: size)
    }

    private static func isConnected(_ inside: Set<Int>, size: GridSize) -> Bool {
        guard let start = inside.min() else { return false }
        var seen: Set<Int> = [start]
        var stack = [start]
        while let cell = stack.popLast() {
            let position = Position(row: cell / size.columns, column: cell % size.columns)
            for neighbor in position.orthogonalNeighbors where size.contains(neighbor) {
                let index = neighbor.row * size.columns + neighbor.column
                guard inside.contains(index), seen.insert(index).inserted else { continue }
                stack.append(index)
            }
        }
        return seen.count == inside.count
    }

    /// Dıştaki bölge bağlı mı — yani içte delik var mı.
    ///
    /// Izgaranın dışı da dış bölgenin parçası, o yüzden gezinme kenar hücrelerinden
    /// başlıyor: bir dış hücreye yalnız içten dolanarak ulaşılıyorsa o bir delik.
    private static func isOutsideConnected(_ inside: Set<Int>, size: GridSize) -> Bool {
        var outside = Set<Int>()
        for cell in 0..<size.cellCount where !inside.contains(cell) {
            outside.insert(cell)
        }
        guard !outside.isEmpty else { return false }

        var stack: [Int] = []
        var seen = Set<Int>()
        for cell in outside {
            let position = Position(row: cell / size.columns, column: cell % size.columns)
            let onBorder = position.row == 0 || position.column == 0
                || position.row == size.rows - 1 || position.column == size.columns - 1
            if onBorder, seen.insert(cell).inserted { stack.append(cell) }
        }

        while let cell = stack.popLast() {
            let position = Position(row: cell / size.columns, column: cell % size.columns)
            for neighbor in position.orthogonalNeighbors where size.contains(neighbor) {
                let index = neighbor.row * size.columns + neighbor.column
                guard outside.contains(index), seen.insert(index).inserted else { continue }
                stack.append(index)
            }
        }
        return seen.count == outside.count
    }

    /// Köşe köşeye değen iki iç hücre var mı — o nokta derece 4 olur ve döngü kesişir.
    private static func hasPinchedDot(_ inside: Set<Int>, size: GridSize) -> Bool {
        for row in 0..<(size.rows - 1) {
            for column in 0..<(size.columns - 1) {
                let topLeft = inside.contains(row * size.columns + column)
                let topRight = inside.contains(row * size.columns + column + 1)
                let bottomLeft = inside.contains((row + 1) * size.columns + column)
                let bottomRight = inside.contains((row + 1) * size.columns + column + 1)

                if topLeft && bottomRight && !topRight && !bottomLeft { return true }
                if topRight && bottomLeft && !topLeft && !bottomRight { return true }
            }
        }
        return false
    }

    /// Kümenin sınırındaki kenarlar: iki komşu hücreden tam biri içte olan kenarlar.
    ///
    /// Izgara dışı daima dış sayılıyor, yani ızgaranın kenarına değen iç hücrenin o kenarı
    /// sınıra dahil.
    public static func boundary(of inside: Set<Int>, in puzzleSize: GridSize) -> [Bool] {
        let rows = puzzleSize.rows
        let columns = puzzleSize.columns
        let horizontalCount = (rows + 1) * columns
        var lines = [Bool](repeating: false, count: horizontalCount + rows * (columns + 1))

        for row in 0...rows {
            for column in 0..<columns {
                let above = row > 0 && inside.contains((row - 1) * columns + column)
                let below = row < rows && inside.contains(row * columns + column)
                lines[row * columns + column] = above != below
            }
        }
        for row in 0..<rows {
            for column in 0...columns {
                let left = column > 0 && inside.contains(row * columns + column - 1)
                let right = column < columns && inside.contains(row * columns + column)
                lines[horizontalCount + row * (columns + 1) + column] = left != right
            }
        }
        return lines
    }
}
