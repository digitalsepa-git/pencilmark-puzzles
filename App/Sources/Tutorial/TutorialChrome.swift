import GameCore
import PuzzleKit
import SwiftUI

/// Öğretici ekranının ızgara dışındaki her şeyi: ilerleme, adım cümlesi, düzeltme
/// uyarısı, atlama ve bitiş.
///
/// Izgara dışarıdan geliyor çünkü beş varyantın ızgara görünümü ayrı tipler; geri kalan
/// her şey aynı.
struct TutorialChrome<Content: View>: View {
    let stepNumber: Int
    let stepCount: Int
    let text: String
    let correction: String?
    let isFinished: Bool
    let onUndo: () -> Void
    let onSkip: () -> Void
    let onDone: () -> Void
    @ViewBuilder let grid: Content

    var body: some View {
        VStack(spacing: 16) {
            if isFinished {
                finished
            } else {
                header
            }

            grid
                .padding(.horizontal, Metrics.screenPadding)

            Spacer(minLength: 0)

            if let correction {
                correctionBanner(correction)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !isFinished {
                    Button("Skip", action: onSkip)
                        .foregroundStyle(Color.inkSoft)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Step \(stepNumber) of \(stepCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.inkSoft)
                .textCase(.uppercase)
            // ADR 0009: adım anlatımı tek cümle, ızgaranın üstünde.
            Text(text)
                .font(.body)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Metrics.screenPadding)
        // Cümleler farklı uzunlukta; sabit yükseklik olmadan ızgara her adımda
        // zıplıyordu.
        .frame(minHeight: 96, alignment: .top)
    }

    private var finished: some View {
        VStack(spacing: 10) {
            Text("You're ready")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.ink)
            Button("Start playing", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(minHeight: 96)
    }

    /// ADR 0009: yanlış hamle engellenmiyor, nazikçe düzeltiliyor.
    private func correctionBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button("Undo", action: onUndo)
                .buttonStyle(.bordered)
        }
        .padding(Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(Color.mistake, lineWidth: Metrics.hairline * 2)
        )
        .padding(.horizontal, Metrics.screenPadding)
    }
}
