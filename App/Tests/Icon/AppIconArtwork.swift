import SwiftUI

/// Uygulama ikonunun çizimi.
///
/// İkon bir çizim programında değil kodda duruyor ve PNG'ler buradan üretiliyor. Sebebi
/// anlık görüntü referanslarıyla aynı (ADR 0016): ikili bir dosyanın diff'i okunamıyor ve
/// "bu rengi neden seçtik" sorusu dosyanın içine yazılamıyor. Kodda duran bir ikon
/// gözden geçirilebiliyor.
///
/// Test hedefinde, çünkü uygulamanın çalışırken bu görünüme ihtiyacı yok — ikon derleme
/// zamanı varlığı. Üretim `AppIconRecordingTests` ile, açık bir derleme koşuluyla.
struct AppIconArtwork: View {
    enum Appearance {
        case light
        case dark
        /// iOS'un tonlu ikonu: tek renkli, sistem renklendiriyor. Şekil yalnız parlaklıkla
        /// okunmak zorunda.
        case tinted
    }

    let appearance: Appearance
    /// 1024'lük tuvale göre ölçek; bütün ölçüler buna oranlı.
    let side: CGFloat

    private var background: Color {
        switch appearance {
        case .light: Color(red: 0.973, green: 0.961, blue: 0.933)
        case .dark: Color(white: 0.071)
        case .tinted: .black
        }
    }

    private var ink: Color {
        switch appearance {
        case .light: Color(white: 0.118)
        case .dark: Color(red: 0.937, green: 0.929, blue: 0.906)
        case .tinted: .white
        }
    }

    private var unit: CGFloat { side / 1_024 }

    var body: some View {
        ZStack {
            background

            // İki şey var ve ikisi de okunur boyutta: karalı bir hücre (Hitori,
            // Kakuro'nun siyah hücreleri) ve kapalı bir döngü (Slitherlink). Üçüncü bir
            // öğe — kalem işareti noktaları — 40 pt'de kayboluyordu, atıldı.
            Canvas { context, size in
                let inset = 118 * unit
                let board = CGRect(
                    x: inset,
                    y: inset,
                    width: size.width - inset * 2,
                    height: size.height - inset * 2
                )
                let cell = board.width / 3

                var grid = Path()
                for step in 1..<3 {
                    let offset = CGFloat(step) * cell
                    grid.move(to: CGPoint(x: board.minX + offset, y: board.minY))
                    grid.addLine(to: CGPoint(x: board.minX + offset, y: board.maxY))
                    grid.move(to: CGPoint(x: board.minX, y: board.minY + offset))
                    grid.addLine(to: CGPoint(x: board.maxX, y: board.minY + offset))
                }
                context.stroke(grid, with: .color(ink.opacity(0.3)), lineWidth: 12 * unit)
                context.stroke(
                    Path(roundedRect: board, cornerRadius: 28 * unit),
                    with: .color(ink),
                    lineWidth: 34 * unit
                )

                // Karalı hücre: sol üst.
                let shaded = CGRect(
                    x: board.minX + 18 * unit,
                    y: board.minY + 18 * unit,
                    width: cell - 36 * unit,
                    height: cell - 36 * unit
                )
                context.fill(Path(roundedRect: shaded, cornerRadius: 12 * unit), with: .color(ink))

                // Kapalı döngü: orta hücrenin çevresi. 3×3'te orta hücre, dört yandan
                // da çerçeveden ayrık duran tek yer; 2×2 blok denendiğinde döngü dış
                // çerçeveyle birleşip tek bir kalın leke gibi okunuyordu.
                let loop = CGRect(
                    x: board.minX + cell,
                    y: board.minY + cell,
                    width: cell,
                    height: cell
                ).insetBy(dx: 22 * unit, dy: 22 * unit)
                context.stroke(
                    Path(roundedRect: loop, cornerRadius: 18 * unit),
                    with: .color(ink),
                    style: StrokeStyle(lineWidth: 44 * unit, lineJoin: .round)
                )
            }
        }
        .frame(width: side, height: side)
    }
}
