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
    /// Yakınlaştırma ve kaydırma. Çizimin sahibi değil: durum ekranda duruyor, buraya
    /// bağ olarak geliyor. Varsayılan sabit bir 1 kat, böylece anlık görüntü ve ölçüm
    /// testleri ızgarayı istediği ölçekte kurabiliyor.
    var zoom: Binding<GridZoom> = .constant(.identity)
    var onTapEdge: ((Int) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let geometry = self.geometry(for: proxy.size)
            Canvas { context, _ in
                let style = GridStyle(geometry: geometry)

                drawClues(
                    geometry: geometry,
                    text: GridDigitText(
                        context: context,
                        digits: 0...3,
                        font: style.slitherlinkClueFont,
                        color: .ink
                    ),
                    into: &context
                )
                drawEdges(geometry: geometry, style: style, into: &context)
                drawDots(geometry: geometry, style: style, into: &context)
            }
            .onTapGesture(coordinateSpace: .local) { location in
                let segments = puzzle.edgeSegments(in: geometry)
                // Tolerans hücre kenarının üçte biri: komşu kenarlar bir hücre kenarı
                // uzaklıkta, yani bu pay iki kenarı karıştırmıyor ama çizginin tam
                // üstüne basmayı da gerektirmiyor.
                if let edge = GridGeometry.nearestSegment(
                    to: location,
                    among: segments,
                    tolerance: geometry.cellSide * 0.33
                ) {
                    onTapEdge?(edge)
                }
            }
            .accessibilityChildren {
                ZStack(alignment: .topLeading) {
                    // İpuçları okunur ama dokunulmaz: Slitherlink'te oynanan şey kenarlar.
                    GridAccessibilityLayer(
                        geometry: geometry,
                        positions: puzzle.size.allPositions
                    ) { position in
                        AccessibilityCell(
                            label: GridAccessibility.slitherlinkClueLabel(
                                at: puzzle.index(of: position),
                                in: puzzle
                            ),
                            isInteractive: false,
                            action: {}
                        )
                        .padding(geometry.cellSide * 0.25)
                    }

                    GridAccessibilityItems(
                        frames: Self.edgeFrames(puzzle: puzzle, geometry: geometry)
                    ) { edge in
                        AccessibilityCell(
                            label: GridAccessibility.slitherlinkEdgeLabel(edge, in: puzzle),
                            value: GridAccessibility.edgeValue(board[edge]),
                            action: { onTapEdge?(edge) }
                        )
                    }
                }
            }
            .gridZoomGestures(
                zoom,
                board: GridGeometry.fittedBoardSize(of: puzzle.size, in: rect(for: proxy.size)),
                viewport: proxy.size
            )
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    /// Kenarın dokunma/okuma çerçevesi: doğru parçasını saran ince bir dikdörtgen.
    nonisolated static func edgeFrames(
        puzzle: SlitherlinkPuzzle,
        geometry: GridGeometry
    ) -> [CGRect] {
        puzzle.edgeSegments(in: geometry).map { segment in
            frame(from: segment.start, to: segment.end, thickness: geometry.cellSide * 0.4)
        }
    }

    private func rect(for size: CGSize) -> CGRect {
        CGRect(origin: .zero, size: size).insetBy(dx: dotInset, dy: dotInset)
    }

    private func geometry(for size: CGSize) -> GridGeometry {
        GridGeometry(fitting: puzzle.size, in: rect(for: size), zoom: zoom.wrappedValue)
    }

    /// Nokta ızgarası hücre ızgarasından bir satır ve bir sütun geniş; dıştaki noktaların
    /// kesilmemesi için kenarlarda pay bırakılıyor.
    private var dotInset: CGFloat { 8 }

    private var aspectRatio: CGFloat {
        CGFloat(puzzle.size.columns) / CGFloat(puzzle.size.rows)
    }

    private func drawClues(
        geometry: GridGeometry,
        text: GridDigitText,
        into context: inout GraphicsContext
    ) {
        for cell in puzzle.cluedCells {
            guard let clue = puzzle.clue(at: cell) else { continue }
            let center = geometry.center(of: puzzle.position(of: cell))
            context.draw(text.text(clue), at: center, anchor: .center)
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
    /// Yakınlaştırma ve kaydırma. Çizimin sahibi değil: durum ekranda duruyor, buraya
    /// bağ olarak geliyor. Varsayılan sabit bir 1 kat, böylece anlık görüntü ve ölçüm
    /// testleri ızgarayı istediği ölçekte kurabiliyor.
    var zoom: Binding<GridZoom> = .constant(.identity)
    var onTapEdge: ((Int) -> Void)?
    @State private var dragIntent: DragIntent?

    /// Tek parmak sürüklemesinin ne anlama geldiği, başladığı yere göre.
    ///
    /// Hashi hem köprüyü sürüklemeyle kuruyor hem de yakınlaştırılmış ızgarada
    /// kaydırmaya ihtiyaç duyuyor; ikisi de tek parmak. Ayrım adanın kendisi: ada
    /// üzerinden başlayan sürükleme köprü, boşluktan başlayan kaydırma. Diğer dört
    /// varyantta böyle bir çakışma yok, bu yüzden bu ayrım burada duruyor
    /// (bkz. `GridZoomGestures.pansWithDrag`).
    private enum DragIntent {
        case bridge
        case pan(GridZoom)
    }

    var body: some View {
        GeometryReader { proxy in
            let geometry = self.geometry(for: proxy.size)
            Canvas { context, _ in
                let style = GridStyle(geometry: geometry)

                drawBridges(geometry: geometry, style: style, into: &context)
                drawIslands(
                    geometry: geometry,
                    style: style,
                    text: GridDigitText(
                        context: context,
                        digits: 1...8,
                        font: style.islandFont,
                        color: .ink
                    ),
                    into: &context
                )
            }
            // Brief b.7: "Adadan adaya sürükle; tekrar dokunmak köprüyü ikiye çıkarır,
            // üçüncüsü siler." Sürükleme köprüyü kuruyor, dokunma döndürüyor; ikisi de
            // aynı hamleye iniyor.
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        if dragIntent == nil {
                            dragIntent = island(at: value.startLocation, in: geometry) == nil
                                ? .pan(zoom.wrappedValue)
                                : .bridge
                        }
                        if case .pan(let base) = dragIntent {
                            zoom.wrappedValue = base.panned(
                                by: value.translation,
                                board: GridGeometry.fittedBoardSize(
                                    of: puzzle.size,
                                    in: rect(for: proxy.size)
                                ),
                                viewport: proxy.size
                            )
                        }
                    }
                    .onEnded { value in
                        defer { dragIntent = nil }
                        guard case .bridge = dragIntent else { return }
                        guard let from = island(at: value.startLocation, in: geometry),
                              let to = island(at: value.location, in: geometry),
                              from != to,
                              let edge = edge(between: from, and: to) else { return }
                        onTapEdge?(edge)
                    }
            )
            .onTapGesture(coordinateSpace: .local) { location in
                let segments = puzzle.edgeSegments(in: geometry)
                if let edge = GridGeometry.nearestSegment(
                    to: location,
                    among: segments,
                    tolerance: geometry.cellSide * 0.4
                ) {
                    onTapEdge?(edge)
                }
            }
            .accessibilityChildren {
                ZStack(alignment: .topLeading) {
                    // Adalar okunur ama dokunulmaz: oynanan şey köprüler. Adanın değeri
                    // kaç köprü gerektiğini ve kaçının çekildiğini söylüyor.
                    GridAccessibilityItems(
                        frames: puzzle.islands.map { island in
                            geometry.rect(of: island.position)
                        }
                    ) { island in
                        AccessibilityCell(
                            label: GridAccessibility.hashiIslandLabel(island, in: puzzle),
                            value: GridAccessibility.hashiIslandValue(
                                island,
                                board: board,
                                in: puzzle
                            ),
                            isInteractive: false,
                            action: {}
                        )
                    }

                    GridAccessibilityItems(
                        frames: puzzle.edgeSegments(in: geometry).map { segment in
                            SlitherlinkGridView.frame(
                                from: segment.start,
                                to: segment.end,
                                thickness: geometry.cellSide * 0.4
                            )
                        }
                    ) { edge in
                        AccessibilityCell(
                            label: GridAccessibility.hashiEdgeLabel(edge, in: puzzle),
                            value: GridAccessibility.bridgeValue(board[edge]),
                            action: { onTapEdge?(edge) }
                        )
                    }
                }
            }
            // Sürükleme burada kaydırma yapmıyor: köprü sürüklemesiyle çakışmaması için
            // kararı yukarıdaki `DragGesture` veriyor.
            .gridZoomGestures(
                zoom,
                board: GridGeometry.fittedBoardSize(of: puzzle.size, in: rect(for: proxy.size)),
                viewport: proxy.size,
                pansWithDrag: false
            )
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private func rect(for size: CGSize) -> CGRect {
        CGRect(origin: .zero, size: size)
    }

    private func geometry(for size: CGSize) -> GridGeometry {
        GridGeometry(fitting: puzzle.size, in: rect(for: size), zoom: zoom.wrappedValue)
    }

    /// Dokunulan noktadaki ada. Ada dairesi hücrenin %38'i; pay biraz daha geniş
    /// tutuluyor ki sürüklemenin başı adanın tam ortasına denk gelmek zorunda kalmasın.
    private func island(at point: CGPoint, in geometry: GridGeometry) -> Int? {
        guard let position = geometry.cell(at: point) else { return nil }
        return puzzle.island(at: position)
    }

    private func edge(between a: Int, and b: Int) -> Int? {
        puzzle.incidentEdges[a].first { edge in
            let candidate = puzzle.edges[edge]
            return (candidate.a == a && candidate.b == b) || (candidate.a == b && candidate.b == a)
        }
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
        text: GridDigitText,
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
            context.draw(text.text(island.required), at: center, anchor: .center)
        }
    }
}

extension SlitherlinkGridView {
    /// İki nokta arasındaki doğru parçasını saran dikdörtgen.
    ///
    /// Hashi de kullanıyor: iki varyantta da erişilebilirlik öğesinin çerçevesi aynı
    /// şekilde hesaplanıyor ve ikinci bir kopya ayrışmaya açık olurdu.
    /// `nonisolated`: `View` tipleri Swift 6'da MainActor'a bağlı sayılıyor ve bu saf
    /// hesabın ekrandan bağımsız test edilmesi gerekiyor.
    nonisolated static func frame(
        from start: CGPoint,
        to end: CGPoint,
        thickness: CGFloat
    ) -> CGRect {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)
        return CGRect(
            x: width == 0 ? minX - thickness / 2 : minX,
            y: height == 0 ? minY - thickness / 2 : minY,
            width: width == 0 ? thickness : width,
            height: height == 0 ? thickness : height
        )
    }
}
