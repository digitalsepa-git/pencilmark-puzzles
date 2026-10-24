import GameCore
import PuzzleKit
import SwiftUI

/// Günlük bulmaca çözüldüğünde üretilen paylaşım kartı (brief b.7).
///
/// Brief bunu "tek organik yayılma kanalımız" diye işaretliyor. Kartın içeriği bilinçli
/// olarak dar: varyant adı, tarih, süre ve ipucu işareti. **Bulmacanın kendisi yok** —
/// ne ızgara, ne ipuçları, ne çözüm. Paylaşılan şey "aynı bulmacayı sen de çözdün mü",
/// bulmacanın cevabı değil.
struct ShareCard: View {
    let variant: PuzzleVariantID
    let day: CalendarDay
    let seconds: Int
    let usedHints: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text("Daily Puzzle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.inkSoft)
                .textCase(.uppercase)

            Text(variant.displayName)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.ink)

            Text(Self.longDate(day))
                .font(.subheadline)
                .foregroundStyle(Color.inkSoft)

            Divider().overlay(Color.rule).padding(.horizontal, 40)

            Text(PuzzleTimer.format(seconds))
                .font(.system(size: 40, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.ink)

            // İpucu kullanılan bulmaca çözüldü sayılıyor ama ayrı işaretleniyor (b.7).
            // Kartta da öyle: gizlemek, paylaşılan sayıyı yalan yapardı.
            Text(usedHints ? "Solved with hints" : "Solved without hints")
                .font(.footnote)
                .foregroundStyle(Color.inkSoft)

            Text("Kakuro & Calcudoku Puzzles")
                .font(.caption2)
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 6)
        }
        .padding(28)
        .frame(width: 320, height: 320)
        .background(Color.card)
    }

    /// "October 24, 2026". `DateFormatter` kullanılmıyor: elimizdeki şey bir `Date` değil
    /// takvim günü ve ona geri dönmek, kaçındığımız saat dilimi sorusunu geri getirirdi.
    static func longDate(_ day: CalendarDay) -> String {
        let months = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]
        let name = months[min(max(day.month, 1), 12) - 1]
        return "\(name) \(day.day), \(day.year)"
    }
}
