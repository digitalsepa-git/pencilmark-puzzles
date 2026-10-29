import GameCore
import PuzzleKit
import SwiftUI

/// İstatistik ekranının Plus bölümü (ADR 0008): günlük bulmaca takvimi, geçmiş ve
/// süre eğilimi.
///
/// Kilitliyken **gizlenmiyor**: başlıklar ve ne oldukları duruyor, içerik yerine kilit
/// var. ADR 0021 §5'teki duruşun aynısı — gizlenen bir şey açıklanamaz ve oyuncu neyi
/// kaçırdığını göremez.
///
/// Veri her katmanda toplanıyor (ADR 0008), yani Plus alındığı gün bu bölümler ilk
/// günden beri birikmiş geçmişle doluyor.
struct PlusStatsSection: View {
    let isUnlocked: Bool
    let records: [PuzzleRecord]
    let today: CalendarDay
    /// Kilitli bir satıra dokunulduğunda.
    let onLocked: () -> Void

    var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            header

            if isUnlocked {
                DailyCalendarCard(
                    calendar: PlusStats.calendar(
                        of: records,
                        year: today.year,
                        month: today.month,
                        today: today
                    )
                )
                NavigationLink {
                    HistoryScreen(records: records)
                } label: {
                    PlusRow(title: "History", detail: historyDetail, isLocked: false)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TrendsScreen(records: records)
                } label: {
                    PlusRow(title: "Time trend", detail: trendDetail, isLocked: false)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onLocked) {
                    PlusRow(
                        title: "Daily Puzzle calendar",
                        detail: String(localized: "Which days you solved the Daily Puzzle"),
                        isLocked: true
                    )
                }
                .buttonStyle(.plain)

                Button(action: onLocked) {
                    PlusRow(
                        title: "History",
                        detail: String(localized: "Every puzzle you have finished, with times"),
                        isLocked: true
                    )
                }
                .buttonStyle(.plain)

                Button(action: onLocked) {
                    PlusRow(
                        title: "Time trend",
                        detail: String(localized: "How your times change over time"),
                        isLocked: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Pencilmark Plus")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.inkSoft)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var historyDetail: String {
        String(localized: "\(records.count) finished puzzles")
    }

    private var trendDetail: String {
        let count = PlusStats.trends(from: records).count
        return count == 1
            ? String(localized: "1 difficulty with enough solves")
            : String(localized: "\(count) difficulties with enough solves")
    }
}

/// Plus bölümünün satırı; kilitliyken kilit simgesi, açıkken ok.
struct PlusRow: View {
    let title: LocalizedStringKey
    let detail: String
    let isLocked: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            Image(systemName: isLocked ? "lock" : "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.inkSoft)
        }
        .padding(Metrics.cardPadding)
        .frame(minHeight: Metrics.minimumTapTarget)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(Color.rule, lineWidth: Metrics.hairline)
        )
        .opacity(isLocked ? 0.55 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Ayın günlük bulmaca takvimi.
struct DailyCalendarCard: View {
    let calendar: PlusStats.Calendar

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        StatsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(monthName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text("\(calendar.solvedCount) / \(calendar.elapsedDays)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.inkSoft)
                }

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Weekday.allCases, id: \.self) { weekday in
                        Text(Self.initial(of: weekday))
                            .font(.caption2)
                            .foregroundStyle(Color.inkSoft)
                    }
                    ForEach(calendar.cells) { cell in
                        day(cell)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func day(_ cell: PlusStats.Calendar.Cell) -> some View {
        if let day = cell.day {
            Text("\(day.day)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(cell.isSolved ? Color.paper : Color.ink)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(cell.isSolved ? Color.ink : Color.clear)
                )
                .overlay(
                    // Bugün çerçeveyle işaretleniyor; çözülmüşse zaten dolu.
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(cell.isToday ? Color.ink : Color.clear, lineWidth: 1.5)
                )
                .opacity(cell.isFuture ? 0.3 : 1)
        } else {
            Color.clear.frame(minHeight: 28)
        }
    }

    private var monthName: String {
        Self.monthNames[calendar.month - 1]
    }

    private var accessibilityLabel: String {
        String(
            localized:
                "\(monthName): \(calendar.solvedCount) of \(calendar.elapsedDays) Daily Puzzles solved"
        )
    }

    /// Ay adları ve gün harfleri `Date.FormatStyle`'dan değil buradan geliyor: takvim
    /// bir tarih değil bir ızgara ve hücrelere sığan tek harf gerekiyor. Yerelleştirme
    /// geldiğinde ikisi de katalogdan çevrilecek (ADR 0019).
    private static let monthNames = [
        String(localized: "January"), String(localized: "February"), String(localized: "March"),
        String(localized: "April"), String(localized: "May"), String(localized: "June"),
        String(localized: "July"), String(localized: "August"), String(localized: "September"),
        String(localized: "October"), String(localized: "November"), String(localized: "December")
    ]

    private static func initial(of weekday: Weekday) -> String {
        switch weekday {
        case .monday: String(localized: "M", comment: "Monday, single letter")
        case .tuesday: String(localized: "T", comment: "Tuesday, single letter")
        case .wednesday: String(localized: "W", comment: "Wednesday, single letter")
        case .thursday: String(localized: "Th", comment: "Thursday, single letter")
        case .friday: String(localized: "F", comment: "Friday, single letter")
        case .saturday: String(localized: "Sa", comment: "Saturday, single letter")
        case .sunday: String(localized: "Su", comment: "Sunday, single letter")
        }
    }
}
