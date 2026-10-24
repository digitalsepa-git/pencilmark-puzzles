import Foundation
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

    /// "October 24, 2026" — biçim ve ay adları kullanıcının diline göre.
    ///
    /// Ay adlarını elle yazmak hem on iki çeviri girdisi hem de yanlış sıralama demekti:
    /// tarih biçimi dilden dile değişiyor ("24 Ekim 2026"). Foundation'ın biçimlendiricisi
    /// ikisini birden çözüyor.
    ///
    /// Burada `Date`'e dönmek güvenli: hangi günde olduğumuz **zaten** karar verilmiş
    /// (ADR 0006) ve bu yalnız gösterim. Günü belirlemek için `Date`'ten kaçınmamızın
    /// sebebi saat dilimi belirsizliğiydi; gösterimde öyle bir belirsizlik yok.
    ///
    /// `nonisolated`: `View` tipleri Swift 6'da MainActor'a bağlı sayılıyor ve bu saf
    /// fonksiyonun ekrandan bağımsız test edilmesi gerekiyor.
    nonisolated static func longDate(
        _ day: CalendarDay,
        locale: Locale = .current,
        calendar: Calendar = .current
    ) -> String {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        // Günün ortası: saat dilimi kayması tarihi bir gün oynatmasın.
        components.hour = 12
        guard let date = calendar.date(from: components) else {
            return "\(day.year)-\(day.month)-\(day.day)"
        }
        return date.formatted(
            Date.FormatStyle(date: .long, time: .omitted, locale: locale, calendar: calendar)
        )
    }
}
