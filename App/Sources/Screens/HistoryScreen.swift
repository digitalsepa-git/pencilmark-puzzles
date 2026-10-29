import GameCore
import PuzzleKit
import SwiftUI

/// Bitmiş bulmacaların tam geçmişi (ADR 0008, Plus).
///
/// `List`, `ScrollView` değil: ADR 0008 hacmi "günde 4 bulmaca × 3 yıl ≈ 4.400 satır"
/// diye hesaplamıştı ve o kadar satırı bir `VStack`'e dizmek hepsini birden kurmak
/// demek. `List` yalnız görüneni kuruyor.
struct HistoryScreen: View {
    let records: [PuzzleRecord]

    var body: some View {
        List {
            ForEach(PlusStats.history(from: records)) { day in
                Section {
                    ForEach(Array(day.records.enumerated()), id: \.offset) { _, record in
                        row(record)
                    }
                } header: {
                    Text(ShareCard.longDate(day.day))
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .overlay {
            if records.isEmpty {
                Text("No finished puzzles yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ record: PuzzleRecord) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(record.variant.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.ink)
                    if record.kind == .daily {
                        Text("Daily")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.inkSoft)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .overlay(
                                Capsule().stroke(Color.rule, lineWidth: Metrics.hairline)
                            )
                    }
                }
                Text(subtitle(record))
                    .font(.footnote)
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            Text(PuzzleTimer.format(record.seconds))
                .font(.body.monospacedDigit())
                .foregroundStyle(Color.ink)
        }
        .listRowBackground(Color.paper)
        .accessibilityElement(children: .combine)
    }

    /// Zorluk ve ipucu. Brief b.7: ipuçlu bulmaca çözüldü sayılıyor ama ayrı
    /// işaretleniyor — geçmişte de öyle.
    private func subtitle(_ record: PuzzleRecord) -> String {
        guard record.hintCount > 0 else {
            return record.difficulty.displayName
        }
        return record.hintCount == 1
            ? String(localized: "\(record.difficulty.displayName) · 1 hint")
            : String(localized: "\(record.difficulty.displayName) · \(record.hintCount) hints")
    }
}
