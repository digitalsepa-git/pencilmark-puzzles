import PuzzleKit
import SwiftUI

/// Hücre oynanan üç varyantın çizimi (Kakuro, Calcudoku, Hitori).
///
/// Hepsi tek bir `Canvas` kullanıyor, hücre başına görünüm değil. Brief b.9'un gerekçesi:
/// "grid'ler yüzlerce hücre; her hücre ayrı view olursa kaydırma takılır." 12×12 bir
/// Slitherlink'te 144 hücre + 312 kenar + 169 nokta ediyor.
struct KakuroGridView: View {
    let puzzle: KakuroPuzzle
    let board: KakuroBoard
    var selection: Position?
    var mistakes: Set<Position> = []

    var body: some View {
        Canvas { context, size in
            let geometry = GridGeometry(
                fitting: puzzle.size,
                in: CGRect(origin: .zero, size: size)
            )
            let style = GridStyle(geometry: geometry)

            for position in puzzle.size.allPositions {
                let rect = geometry.rect(of: position)
                switch puzzle.cells[position] {
                case .clue(let down, let right):
                    draw(clueCell: rect, down: down, right: right, style: style, into: &context)
                case .entry:
                    draw(entry: position, rect: rect, style: style, into: &context)
                }
            }
            strokeOutline(geometry: geometry, style: style, into: &context)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private var aspectRatio: CGFloat {
        CGFloat(puzzle.size.columns) / CGFloat(puzzle.size.rows)
    }

    private func draw(
        clueCell rect: CGRect,
        down: Int?,
        right: Int?,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        context.fill(Path(rect), with: .color(.ink))
        // Çapraz çizgi iki toplamı ayırıyor: sağdaki yatay kesit, soldaki dikey kesit.
        var diagonal = Path()
        diagonal.move(to: CGPoint(x: rect.minX, y: rect.minY))
        diagonal.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.stroke(diagonal, with: .color(.paper), lineWidth: style.thinLine)

        if let right {
            context.draw(
                Text("\(right)").font(style.clueFont).foregroundStyle(Color.paper),
                at: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.minY + rect.height * 0.3),
                anchor: .center
            )
        }
        if let down {
            context.draw(
                Text("\(down)").font(style.clueFont).foregroundStyle(Color.paper),
                at: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + rect.height * 0.7),
                anchor: .center
            )
        }
    }

    private func draw(
        entry position: Position,
        rect: CGRect,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        context.fill(Path(rect), with: .color(position == selection ? .selection : .card))
        context.stroke(Path(rect), with: .color(.rule), lineWidth: style.thinLine)

        let cell = board[position]
        if let value = cell.value {
            let color: Color = mistakes.contains(position) ? .mistake : .ink
            context.draw(
                Text("\(value)").font(style.valueFont).foregroundStyle(color),
                at: CGPoint(x: rect.midX, y: rect.midY),
                anchor: .center
            )
        } else {
            // Kesin değer varken adaylar gizleniyor ama silinmiyor (bkz. `DigitCell`).
            for digit in 1...9 where cell.candidates.contains(digit) {
                context.draw(
                    Text("\(digit)").font(style.candidateFont).foregroundStyle(Color.inkSoft),
                    at: style.candidateCenter(of: digit, in: rect),
                    anchor: .center
                )
            }
        }
    }
}

struct CalcudokuGridView: View {
    let puzzle: CalcudokuPuzzle
    let board: CalcudokuBoard
    var selection: Position?
    var mistakes: Set<Position> = []

    var body: some View {
        Canvas { context, size in
            let geometry = GridGeometry(
                fitting: puzzle.size,
                in: CGRect(origin: .zero, size: size)
            )
            let style = GridStyle(geometry: geometry)

            for position in puzzle.size.allPositions {
                let rect = geometry.rect(of: position)
                context.fill(Path(rect), with: .color(position == selection ? .selection : .card))
                context.stroke(Path(rect), with: .color(.rule), lineWidth: style.thinLine)
                draw(value: position, rect: rect, style: style, into: &context)
            }
            strokeCageBorders(geometry: geometry, style: style, into: &context)
            drawCageLabels(geometry: geometry, style: style, into: &context)
            strokeOutline(geometry: geometry, style: style, into: &context)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func draw(
        value position: Position,
        rect: CGRect,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        let cell = board[position]
        if let value = cell.value {
            let color: Color = mistakes.contains(position) ? .mistake : .ink
            context.draw(
                Text("\(value)").font(style.valueFont).foregroundStyle(color),
                at: CGPoint(x: rect.midX, y: rect.midY),
                anchor: .center
            )
        } else {
            for digit in 1...puzzle.side where cell.candidates.contains(digit) {
                context.draw(
                    Text("\(digit)").font(style.candidateFont).foregroundStyle(Color.inkSoft),
                    at: style.candidateCenter(of: digit, in: rect),
                    anchor: .center
                )
            }
        }
    }

    /// Kafes sınırı: iki komşu hücre farklı kafeslerdeyse aralarına kalın çizgi.
    private func strokeCageBorders(
        geometry: GridGeometry,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        var path = Path()
        for position in puzzle.size.allPositions {
            let cage = puzzle.cageOfCell[puzzle.index(of: position)]
            let rect = geometry.rect(of: position)
            let below = position.offset(byRows: 1, columns: 0)
            let right = position.offset(byRows: 0, columns: 1)

            if puzzle.size.contains(below),
               puzzle.cageOfCell[puzzle.index(of: below)] != cage {
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            if puzzle.size.contains(right),
               puzzle.cageOfCell[puzzle.index(of: right)] != cage {
                path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            }
        }
        context.stroke(path, with: .color(.ink), lineWidth: style.thickLine)
    }

    /// Hedef ve işlem kafesin **sol üst** hücresinde duruyor; yayınlanmış bulmacaların
    /// yerleşimi bu ve oyuncu orayı arıyor.
    private func drawCageLabels(
        geometry: GridGeometry,
        style: GridStyle,
        into context: inout GraphicsContext
    ) {
        for cage in puzzle.cages {
            guard let anchor = cage.cells.min() else { continue }
            let rect = geometry.rect(of: puzzle.position(of: anchor))
            context.draw(
                Text("\(cage.target)\(cage.operation.symbol)")
                    .font(style.cageFont)
                    .foregroundStyle(Color.ink),
                at: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.04),
                anchor: .topLeading
            )
        }
    }
}

struct HitoriGridView: View {
    let puzzle: HitoriPuzzle
    let board: HitoriBoard
    var selection: Position?
    var mistakes: Set<Position> = []

    var body: some View {
        Canvas { context, size in
            let geometry = GridGeometry(
                fitting: puzzle.size,
                in: CGRect(origin: .zero, size: size)
            )
            let style = GridStyle(geometry: geometry)

            for position in puzzle.size.allPositions {
                let rect = geometry.rect(of: position)
                let state = board[position]
                let fill: Color = switch state {
                case .shaded: mistakes.contains(position) ? .mistake : .ink
                case .marked, .unknown: position == selection ? .selection : .card
                }
                context.fill(Path(rect), with: .color(fill))
                context.stroke(Path(rect), with: .color(.rule), lineWidth: style.thinLine)

                if state != .shaded {
                    // İşaretli hücre rakamın etrafındaki ince daireyle ayrılıyor, soluk
                    // renkle değil: başlangıçta bütün hücreler kararsız ve soluk renk
                    // ızgaranın tamamını gri gösterirdi.
                    if state == .marked {
                        let radius = rect.width * 0.36
                        let circle = Path(
                            ellipseIn: CGRect(
                                x: rect.midX - radius,
                                y: rect.midY - radius,
                                width: radius * 2,
                                height: radius * 2
                            )
                        )
                        context.stroke(circle, with: .color(.inkSoft), lineWidth: style.thinLine * 2)
                    }
                    context.draw(
                        Text("\(puzzle.values[position])")
                            .font(style.valueFont)
                            .foregroundStyle(Color.ink),
                        at: CGPoint(x: rect.midX, y: rect.midY),
                        anchor: .center
                    )
                }
            }
            strokeOutline(geometry: geometry, style: style, into: &context)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Izgaranın dış çerçevesi; üç varyantta da aynı.
private func strokeOutline(
    geometry: GridGeometry,
    style: GridStyle,
    into context: inout GraphicsContext
) {
    context.stroke(Path(geometry.boardRect), with: .color(.ink), lineWidth: style.thickLine)
}
