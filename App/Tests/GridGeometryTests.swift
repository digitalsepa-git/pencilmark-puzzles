import CoreGraphics
import Testing
import PuzzleKit
@testable import Pencilmark

@Suite("Izgara geometrisi")
struct GridGeometryTests {
    private let rect = CGRect(x: 0, y: 0, width: 400, height: 300)

    @Test("Hücreler kare ve ızgara ortalanmış")
    func cellsAreSquareAndCentred() {
        let geometry = GridGeometry(fitting: GridSize(square: 6), in: rect)
        // Kısa kenar belirliyor: 300 / 6 = 50.
        #expect(geometry.cellSide == 50)
        #expect(geometry.boardRect.width == 300)
        #expect(geometry.boardRect.height == 300)
        #expect(geometry.boardRect.midX == rect.midX)
        #expect(geometry.boardRect.midY == rect.midY)
    }

    @Test("Dikdörtgen ızgarada da hücreler kare")
    func rectangularGridsKeepSquareCells() {
        let geometry = GridGeometry(fitting: GridSize(rows: 3, columns: 6), in: rect)
        // Tam bölünmeyen bir değer: eşitlik yerine pay bırakarak karşılaştırılıyor.
        let expected = rect.width / 6
        #expect(abs(geometry.cellSide - expected) < 0.0001)
        #expect(geometry.boardRect.height == geometry.cellSide * 3)
    }

    @Test("Hücre dikdörtgeni ve merkezi")
    func cellRectAndCentre() {
        let geometry = GridGeometry(fitting: GridSize(square: 6), in: rect)
        let cell = geometry.rect(of: Position(row: 0, column: 0))
        #expect(cell.origin == geometry.origin)
        #expect(cell.width == 50)

        let centre = geometry.center(of: Position(row: 1, column: 2))
        #expect(centre.x == geometry.origin.x + 125)
        #expect(centre.y == geometry.origin.y + 75)
    }

    @Test("Nokta ızgarası hücre köşelerinde")
    func dotsSitOnCellCorners() {
        let geometry = GridGeometry(fitting: GridSize(square: 6), in: rect)
        #expect(geometry.dot(row: 0, column: 0) == geometry.origin)
        #expect(geometry.dot(row: 6, column: 6) == CGPoint(
            x: geometry.boardRect.maxX, y: geometry.boardRect.maxY
        ))
    }

    @Test("Dokunma noktası hücreye çevriliyor")
    func pointMapsToCell() {
        let geometry = GridGeometry(fitting: GridSize(square: 6), in: rect)
        let centre = geometry.center(of: Position(row: 2, column: 3))
        #expect(geometry.cell(at: centre) == Position(row: 2, column: 3))
    }

    // Izgara dışına dokunmak hiçbir hücreyi seçmemeli. Negatif tarafta tamsayıya çevirme
    // yukarı yuvarladığı için -0.5 de 0'a düşüyor; sınır ayrıca kontrol ediliyor.
    @Test("Izgara dışına dokunmak hücre vermiyor")
    func pointsOutsideTheGridMapToNothing() {
        let geometry = GridGeometry(fitting: GridSize(square: 6), in: rect)
        let board = geometry.boardRect
        #expect(geometry.cell(at: CGPoint(x: board.minX - 1, y: board.midY)) == nil)
        #expect(geometry.cell(at: CGPoint(x: board.midX, y: board.minY - 1)) == nil)
        #expect(geometry.cell(at: CGPoint(x: board.maxX + 1, y: board.midY)) == nil)
        #expect(geometry.cell(at: CGPoint(x: board.midX, y: board.maxY + 1)) == nil)
    }

    @Test("Sıfır boyutlu ızgara çökmüyor")
    func degenerateGridDoesNotCrash() {
        let geometry = GridGeometry(fitting: GridSize(square: 6), in: .zero)
        #expect(geometry.cellSide == 0)
        #expect(geometry.cell(at: .zero) == nil)
    }
}

@Suite("Kenar dokunma eşlemesi")
struct SegmentHitTests {
    private let segments: [(start: CGPoint, end: CGPoint)] = [
        (CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)),
        (CGPoint(x: 0, y: 100), CGPoint(x: 100, y: 100))
    ]

    @Test("En yakın parça seçiliyor")
    func nearestSegmentWins() {
        let index = GridGeometry.nearestSegment(
            to: CGPoint(x: 50, y: 10), among: segments, tolerance: 20
        )
        #expect(index == 0)
    }

    @Test("Tolerans dışındaki dokunma hiçbir parçayı seçmiyor")
    func touchesOutsideToleranceSelectNothing() {
        let index = GridGeometry.nearestSegment(
            to: CGPoint(x: 50, y: 50), among: segments, tolerance: 20
        )
        #expect(index == nil)
    }

    // Parçanın hizasının dışına dokunmak, uzaklığı uç noktaya göre ölçmeli; yoksa aynı
    // doğrultudaki uzak bir dokunuş yanlışlıkla yakın sayılır.
    @Test("Parça dışındaki izdüşüm uç noktaya çekiliyor")
    func projectionIsClampedToTheSegment() {
        let index = GridGeometry.nearestSegment(
            to: CGPoint(x: 160, y: 0), among: segments, tolerance: 20
        )
        #expect(index == nil)
    }

    @Test("Boş parça listesi hiçbir şey vermiyor")
    func emptySegmentsSelectNothing() {
        #expect(GridGeometry.nearestSegment(to: .zero, among: [], tolerance: 20) == nil)
    }
}

@Suite("Varyant kenar geometrisi")
struct VariantSegmentTests {
    private let rect = CGRect(x: 0, y: 0, width: 300, height: 300)

    @Test("Slitherlink parçaları kenar indeksiyle aynı sırada")
    func slitherlinkSegmentsMatchEdgeIndices() throws {
        let puzzle = try SlitherlinkGenerator.pipeline().generate(difficulty: .easy, seed: 31)
        let geometry = GridGeometry(fitting: puzzle.definition.size, in: rect)
        let segments = puzzle.definition.edgeSegments(in: geometry)

        #expect(segments.count == puzzle.definition.edgeCount)
        for edge in 0..<puzzle.definition.edgeCount {
            let segment = segments[edge]
            if puzzle.definition.isHorizontal(edge) {
                #expect(segment.start.y == segment.end.y)
                #expect(segment.end.x - segment.start.x == geometry.cellSide)
            } else {
                #expect(segment.start.x == segment.end.x)
                #expect(segment.end.y - segment.start.y == geometry.cellSide)
            }
        }
    }

    @Test("Hashi parçaları ada merkezlerini birleştiriyor")
    func hashiSegmentsConnectIslandCentres() throws {
        let puzzle = try HashiGenerator.pipeline().generate(difficulty: .easy, seed: 32)
        let geometry = GridGeometry(fitting: puzzle.definition.size, in: rect)
        let segments = puzzle.definition.edgeSegments(in: geometry)

        #expect(segments.count == puzzle.definition.edges.count)
        for (index, edge) in puzzle.definition.edges.enumerated() {
            let expectedStart = geometry.center(of: puzzle.definition.islands[edge.a].position)
            #expect(segments[index].start == expectedStart)
        }
    }
}
