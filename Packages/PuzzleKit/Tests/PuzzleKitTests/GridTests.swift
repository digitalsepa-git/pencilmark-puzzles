import Testing
import PuzzleKit

@Suite("Grid ve konum modeli")
struct GridTests {
    @Test("Konum ile okuma/yazma satır öncelikli sırayla eşleşir")
    func subscriptMatchesRowMajorOrder() {
        var grid = Grid(size: GridSize(rows: 2, columns: 3), elements: [1, 2, 3, 4, 5, 6])
        #expect(grid[Position(row: 0, column: 2)] == 3)
        #expect(grid[1, 0] == 4)

        grid[1, 2] = 60
        #expect(grid.elements == [1, 2, 3, 4, 5, 60])
    }

    @Test("Sınır dışı erişim nil döner, çökmez")
    func outOfBoundsAccessReturnsNil() {
        let grid = Grid(size: GridSize(square: 2), repeating: 0)
        #expect(grid.element(at: Position(row: 2, column: 0)) == nil)
        #expect(grid.element(at: Position(row: -1, column: 0)) == nil)
        #expect(grid.element(at: Position(row: 1, column: 1)) == 0)
    }

    @Test("Satır ve sütun okuma doğru dilimi verir")
    func rowAndColumnReadCorrectSlice() {
        let grid = Grid(size: GridSize(rows: 3, columns: 2), elements: [1, 2, 3, 4, 5, 6])
        #expect(grid.row(1) == [3, 4])
        #expect(grid.column(0) == [1, 3, 5])
    }

    @Test("Komşular ızgara sınırında kırpılır")
    func neighborsAreClippedAtBorder() {
        let grid = Grid(size: GridSize(square: 3), repeating: 0)
        #expect(grid.neighbors(of: Position(row: 0, column: 0)).count == 2)
        #expect(grid.neighbors(of: Position(row: 1, column: 1)).count == 4)
        #expect(grid.neighbors(of: Position(row: 2, column: 1)).count == 3)
    }

    @Test("map boyutu korur")
    func mapPreservesSize() {
        let grid = Grid(size: GridSize(rows: 2, columns: 3), repeating: 2)
        let doubled = grid.map { $0 * 2 }
        #expect(doubled.size == grid.size)
        #expect(doubled.elements.allSatisfy { $0 == 4 })
    }

    @Test("Konumlar satır öncelikli sıralanır")
    func positionsSortRowMajor() {
        let positions = [
            Position(row: 1, column: 0),
            Position(row: 0, column: 2),
            Position(row: 0, column: 1)
        ].sorted()
        #expect(positions.map(\.description) == ["(0,1)", "(0,2)", "(1,0)"])
    }

    @Test("allPositions tüm hücreleri bir kez verir")
    func allPositionsCoversEveryCell() {
        let size = GridSize(rows: 4, columns: 3)
        #expect(size.allPositions.count == size.cellCount)
        #expect(Set(size.allPositions).count == size.cellCount)
    }
}
