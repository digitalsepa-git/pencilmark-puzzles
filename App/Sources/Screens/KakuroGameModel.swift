import GameCore
import PuzzleKit
import SwiftUI

/// Kakuro bulmaca ekranının durumu.
///
/// `GameSession` bir değer tipi ve bütün oyun mantığı orada; bu sınıfın işi yalnız onu
/// SwiftUI'ya bağlamak ve üretimi arayüzün dışına almak. Brief b.11: "Üretim arayüzü
/// kilitlemez; arka planda koşar ve ilerleme gösterilir."
@MainActor
@Observable
final class KakuroGameModel {
    enum Phase: Equatable {
        case generating
        case playing
        case failed(String)
    }

    private(set) var phase: Phase = .generating
    private(set) var session: GameSession<KakuroRuntime>?

    /// Kalem kipi. Brief b.7: Kakuro'da kalem işareti zorunlu.
    var isPencilMode = false

    let difficulty: Difficulty
    private let seed: UInt64

    init(difficulty: Difficulty, seed: UInt64) {
        self.difficulty = difficulty
        self.seed = seed
    }

    var isSolved: Bool { session?.isSolved ?? false }
    var hintCount: Int { session?.hintCount ?? 0 }
    var canUndo: Bool { session?.canUndo ?? false }
    var canRedo: Bool { session?.canRedo ?? false }

    func start() async {
        phase = .generating
        let difficulty = difficulty
        let seed = seed
        do {
            // Üretim ana iş parçacığının dışında: Expert Kakuro'nun en kötü ölçümü
            // 1.222 ms ve o süre boyunca arayüzün donması kabul edilemez (ADR 0013).
            let puzzle = try await Task.detached(priority: .userInitiated) {
                try KakuroGenerator.pipeline().generate(difficulty: difficulty, seed: seed)
            }.value
            session = GameSession<KakuroRuntime>(
                definition: puzzle.definition,
                solution: puzzle.solution
            )
            phase = .playing
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    func select(_ position: Position) {
        session?.selection = position
    }

    /// Rakam çubuğundan gelen giriş. Kalem kipinde aday, normal kipte kesin değer.
    func enter(_ digit: Int) {
        guard var session, let position = session.selection else { return }
        let move: KakuroMove = isPencilMode
            ? .togglingCandidate(digit, at: position, on: session.board)
            : .writing(digit, at: position, on: session.board)
        session.perform(move)
        self.session = session
    }

    func erase() {
        guard var session, let position = session.selection else { return }
        session.perform(.erasing(at: position, on: session.board))
        self.session = session
    }

    func undo() {
        guard var session else { return }
        session.undo()
        self.session = session
    }

    func redo() {
        guard var session else { return }
        session.redo()
        self.session = session
    }

    func hint() {
        guard var session else { return }
        if let revealed = session.revealHint() {
            session.selection = revealed
        }
        self.session = session
    }

    /// Oyuncunun istediği kontrol. Varsayılan kip manuel (brief b.7).
    func check() {
        guard var session else { return }
        session.check()
        self.session = session
    }
}
