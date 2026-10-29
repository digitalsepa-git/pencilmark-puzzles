import GameCore
import PuzzleKit
import SwiftData
import SwiftUI

/// Zorluk seçimi (brief b.7, ekran 2).
///
/// Ücretsiz katmanın iki kısıtı burada görünüyor (ADR 0007): Hard ve Expert kilitli,
/// günlük üç bulmacalık hak bitince Easy ve Medium da yeni oyun açmıyor. İkisi de
/// kilitli satırı gizlemiyor — gizlenen bir şey açıklanamaz ve oyuncu neyi
/// kaçırdığını göremez.
struct DifficultyScreen: View {
    let variant: PuzzleVariantID

    @Environment(\.modelContext) private var modelContext
    @Environment(Preferences.self) private var preferences
    @Environment(PlayLimits.self) private var limits
    @Environment(StoreService.self) private var store
    @State private var inProgress: Set<Difficulty> = []
    @State private var isShowingTutorial = false
    @State private var notice: PlayLimitNotice?
    @State private var solvedPuzzles = 0

    var body: some View {
        List {
            Section {
                Button {
                    isShowingTutorial = true
                } label: {
                    howToPlayRow
                }
                .buttonStyle(.plain)
            }

            Section {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    if let blocked = blockedReason(difficulty) {
                        Button { notice = blocked } label: {
                            row(difficulty, blocked: blocked)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            PuzzleScreen(variant: variant, difficulty: difficulty)
                        } label: {
                            row(difficulty, blocked: nil)
                        }
                    }
                }
            } footer: {
                // Kalan hak bölümün altbilgisinde: serbest duran bir cümle değil,
                // sistemin listeye verdiği yer.
                if let remaining = limits.allowance.remainingPuzzles {
                    Text(Self.remainingSummary(remaining))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .task {
            inProgress =
                (try? GameStore(context: modelContext).difficultiesInProgress(variant: variant))
                ?? []
            limits.refresh()
            solvedPuzzles = (try? RecordStore(context: modelContext).solvedCount()) ?? 0
            // ADR 0009: ilk kez bir varyant açıldığında öğretici kendiliğinden başlıyor.
            if !preferences.hasSeenTutorial(variant) {
                isShowingTutorial = true
            }
        }
        .sheet(item: $notice) { notice in
            PlayLimitGate(
                notice: notice,
                solvedPuzzles: solvedPuzzles,
                store: store
            ) { self.notice = nil }
        }
        .fullScreenCover(isPresented: $isShowingTutorial) {
            NavigationStack {
                TutorialScreen(variant: variant) {
                    preferences.markTutorialSeen(variant)
                    isShowingTutorial = false
                }
                .navigationTitle("How to play \(variant.displayName)")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationTitle(variant.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func blockedReason(_ difficulty: Difficulty) -> PlayLimitNotice? {
        Self.blockedReason(
            difficulty,
            allowance: limits.allowance,
            isResuming: inProgress.contains(difficulty)
        )
    }

    /// Satıra dokunmak oyunu açmıyorsa sebebi; açıyorsa `nil`.
    ///
    /// Yarım kalan oyun kotadan önce geliyor: hak bitmiş olsa da başlanmış bir bulmaca
    /// bitirilebiliyor (ADR 0007).
    ///
    /// `nonisolated`: `View` tipleri Swift 6'da MainActor'a bağlı sayılıyor ve bu saf
    /// karar ekrandan bağımsız sınanıyor.
    nonisolated static func blockedReason(
        _ difficulty: Difficulty,
        allowance: PlayAllowance,
        isResuming: Bool
    ) -> PlayLimitNotice? {
        guard allowance.isUnlocked(difficulty) else { return .lockedDifficulty }
        let canStart = allowance.canStart(difficulty, kind: .free, isResuming: isResuming)
        return canStart ? nil : .puzzleQuota
    }

    /// Kalan hakkın tek cümlelik hâli. Sayıyı göstermek, kotanın oyuncuyu bulmacanın
    /// kapısında yakalamasını engelliyor.
    nonisolated static func remainingSummary(_ remaining: Int) -> String {
        switch remaining {
        case 0: localized("No free puzzles left today. The Daily Puzzle is still free.")
        case 1: localized("1 free puzzle left today")
        default: localized("\(remaining) free puzzles left today")
        }
    }

    private func row(_ difficulty: Difficulty, blocked: PlayLimitNotice?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(difficulty.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ink)
                // Yarım kalan oyun zorluk başına saklanıyor: Easy'ye başlamak yarım
                // kalan Medium'u silmiyor (ADR 0018).
                if inProgress.contains(difficulty) {
                    Text("In progress")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                } else if blocked == .lockedDifficulty {
                    Text("Plus")
                        .font(.footnote)
                        .foregroundStyle(Color.inkSoft)
                }
            }
            Spacer()
            // Açık satırın göstergesini `NavigationLink` koyuyor; buradaki yalnız
            // kilitli satırın kilidi.
            if blocked != nil {
                Image(systemName: "lock")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .frame(minHeight: Metrics.minimumTapTarget)
        // Soluk ama okunur: kilitli satır da bir teklif ve okunamayan bir teklif
        // işe yaramıyor.
        .opacity(blocked == nil ? 1 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(blocked?.title ?? "")
    }
}

extension DifficultyScreen {
    /// ADR 0009: öğretici her zaman yeniden oynanabiliyor.
    private var howToPlayRow: some View {
        HStack {
            Text("How to play")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.ink)
            Spacer()
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Color.inkSoft)
        }
        .frame(minHeight: Metrics.minimumTapTarget)
    }
}
