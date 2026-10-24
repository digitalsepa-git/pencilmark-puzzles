import PuzzleKit
import SwiftUI

/// Kenar oynanan iki varyantın çizimi (Slitherlink, Hashi).
///
/// İkisinde de oynanan şey hücre değil hücreler arası bağlantı, bu yüzden hem çizim hem
/// dokunma eşlemesi doğru parçaları üzerinden gidiyor.
extension SlitherlinkPuzzle {
    /// Kenar indeksinden ekrandaki doğru parçasına. Sıra `edgeCount` ile aynı, yani
    /// dizinin indeksi doğrudan kenar indeksi.
    func edgeSegments(in geometry: GridGeometry) -> [(start: CGPoint, end: CGPoint)] {
        (0..<edgeCount).map { edge in
            let endpoints = endpointsOfEdge[edge]
            return (
                start: geometry.dot(at: dotPosition(of: endpoints.first)),
                end: geometry.dot(at: dotPosition(of: endpoints.second))
            )
        }
    }
}

extension HashiPuzzle {
    func edgeSegments(in geometry: GridGeometry) -> [(start: CGPoint, end: CGPoint)] {
        edges.map { edge in
            (
                start: geometry.center(of: islands[edge.a].position),
                end: geometry.center(of: islands[edge.b].position)
            )
        }
    }
}

struct SlitherlinkGridView: View {
    let puzzle: SlitherlinkPuzzle
    let board: SlitherlinkBoard
    var mistakes: Set<Int> = []

    var body: some View {
        Canvas { context, size in
            let geometry = GridGeometry(
                fitting: puzzle.size,
                in: CGRect(origin: .zero, size: size).insetBy(dx: dotInset, dy: dotInset)
            )
            let style = GridStyle(geometry: geometry)

            drawClues(geometry: geometry, style: style, into: &context)
            drawEdges(geometry: geometry, style: style, into: &context)
            drawDots(geometry: geometry, style: style, into: &context)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    /// Nokta ızgarası hücre ızgarasından bir satır ve bir sütun geniş; dıştaki noktaların
    /// kesilmemesi için kenarlarda pay bırakılıyor.
    private var dotInset: CGFloat { 8 }

    private var aspectRatio: CGFloat {
        CGFloat(puzzle.size.columns) / CGFloat(puzzle.size.rows)
    }

    private func drawClues(
        geometry: GridGeometry,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        for cell in puzzle.cluedCells {
            guard let clue = puzzle.clue(at: cell) else { continue }
            let center = geometry.center(of: puzzle.position(of: cell))
            context.draw(
                Text("\(clue)").font(style.slitherlinkClueFont).foregroundStyle(Color.ink),
                at: center,
                anchor: .center
            )
        }
    }

    private func drawEdges(
        geometry: GridGeometry,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        let segments = puzzle.edgeSegments(in: geometry)
        var lines = Path()
        var wrongLines = Path()
        var crosses = Path()

        for (edge, segment) in segments.enumerated() {
            switch board[edge] {
            case .line:
                if mistakes.contains(edge) {
                    wrongLines.move(to: segment.start)
                    wrongLines.addLine(to: segment.end)
                } else {
                    lines.move(to: segment.start)
                    lines.addLine(to: segment.end)
                }
            case .cross:
                // Çarpı kenarın ortasında, küçük: oyuncunun "burada çizgi yok" notu,
                // çizginin kendisiyle karışmamalı.
                let center = CGPoint(
                    x: (segment.start.x + segment.end.x) / 2,
                    y: (segment.start.y + segment.end.y) / 2
                )
                let arm = geometry.cellSide * 0.12
                crosses.move(to: CGPoint(x: center.x - arm, y: center.y - arm))
                crosses.addLine(to: CGPoint(x: center.x + arm, y: center.y + arm))
                crosses.move(to: CGPoint(x: center.x - arm, y: center.y + arm))
                crosses.addLine(to: CGPoint(x: center.x + arm, y: center.y - arm))
            case .unknown:
                continue
            }
        }

        context.stroke(lines, with: .color(.ink), lineWidth: style.thickLine)
        context.stroke(wrongLines, with: .color(.mistake), lineWidth: style.thickLine)
        context.stroke(crosses, with: .color(.inkSoft), lineWidth: style.thinLine * 2)
    }

    private func drawDots(
        geometry: GridGeometry,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        let radius = max(geometry.cellSide * 0.05, 1)
        var path = Path()
        for row in 0...puzzle.size.rows {
            for column in 0...puzzle.size.columns {
                let point = geometry.dot(row: row, column: column)
                path.addEllipse(
                    in: CGRect(
                        x: point.x - radius,
                        y: point.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                )
            }
        }
        context.fill(path, with: .color(.inkSoft))
    }
}

struct HashiGridView: View {
    let puzzle: HashiPuzzle
    let board: HashiBoard
    var selection: Int?
    var mistakes: Set<Int> = []

    var body: some View {
        Canvas { context, size in
            let geometry = GridGeometry(
                fitting: puzzle.size,
                in: CGRect(origin: .zero, size: size)
            )
            let style = GridStyle(geometry: geometry)

            drawBridges(geometry: geometry, style: style, into: &context)
            drawIslands(geometry: geometry, style: style, into: &context)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private var aspectRatio: CGFloat {
        CGFloat(puzzle.size.columns) / CGFloat(puzzle.size.rows)
    }

    /// Çift köprü iki paralel çizgi. Aralık hücre kenarına oranlı, böylece küçük ızgarada
    /// birbirine girmiyor.
    private func drawBridges(
        geometry: GridGeometry,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        let segments = puzzle.edgeSegments(in: geometry)
        let gap = geometry.cellSide * 0.11

        for (edge, segment) in segments.enumerated() where board[edge] > 0 {
            let isHorizontal = puzzle.edges[edge].isHorizontal
            let offsets: [CGFloat] = board[edge] == 1 ? [0] : [-gap, gap]
            var path = Path()
            for offset in offsets {
                let dx = isHorizontal ? 0 : offset
                let dy = isHorizontal ? offset : 0
                path.move(to: CGPoint(x: segment.start.x + dx, y: segment.start.y + dy))
                path.addLine(to: CGPoint(x: segment.end.x + dx, y: segment.end.y + dy))
            }
            let color: Color = mistakes.contains(edge) ? .mistake : .ink
            context.stroke(path, with: .color(color), lineWidth: style.thinLine * 2.5)
        }
    }

    private func drawIslands(
        geometry: GridGeometry,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        let radius = geometry.cellSide * 0.38
        for island in puzzle.islands {
            let center = geometry.center(of: island.position)
            let circle = Path(
                ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
            )
            context.fill(circle, with: .color(.card))
            context.stroke(circle, with: .color(.ink), lineWidth: style.thinLine * 2)
            context.draw(
                Text("\(island.required)").font(style.islandFont).foregroundStyle(Color.ink),
                at: center,
                anchor: .center
            )
        }
    }
}
