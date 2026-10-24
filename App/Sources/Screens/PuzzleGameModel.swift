import GameCore
import PuzzleKit
import SwiftUI

/// Bulmaca ekranının durumu; beş varyantın hepsinde aynı.
///
/// Oyun mantığı `GameSession`'da ve o bir değer tipi; bu sınıfın işi yalnız onu SwiftUI'ya
/// bağlamak ve üretimi arayüzün dışına almak (brief b.11: "üretim arayüzü kilitlemez").
@MainActor
@Observable
final class PuzzleGameModel<Runtime: PuzzleRuntime> {
    enum Phase: Equatable {
        case generating
        case playing
        case failed(String)
    }

    private(set) var phase: Phase = .generating
    private(set) var session: GameSession<Runtime>?

    /// Kalem kipi. Yalnız rakam yazılan varyantlarda anlamlı; modelde durması, araç
    /// çubuğunun beş ekranda da aynı kalmasını sağlıyor.
    var isPencilMode = false

    let difficulty: Difficulty
    private let seed: UInt64

    init(difficulty: Difficulty, seed: UInt64) {
        self.difficulty = difficulty
        self.seed = seed
    }

    /// Serbest oyun için yeni bir model. Tohum her açılışta farklı: aynı zorlukta arka
    /// arkaya aynı bulmacayı vermek rakip şikâyetlerinden biri. Günlük bulmaca ayrı ve
    /// tarihten türüyor (ADR 0006).
    static func freeplay(difficulty: Difficulty) -> PuzzleGameModel<Runtime> {
        var generator = SystemRandomNumberGenerator()
        let counter = UInt64.random(in: 0..<UInt64.max, using: &generator)
        return PuzzleGameModel(
            difficulty: difficulty,
            seed: Seed.free(variant: Runtime.variant, difficulty: difficulty, counter: counter)
        )
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
                try Runtime.generate(difficulty: difficulty, seed: seed)
            }.value
            session = GameSession<Runtime>(
                definition: puzzle.definition,
                solution: puzzle.solution
            )
            phase = .playing
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    func select(_ location: Runtime.Location?) {
        session?.selection = location
    }

    func perform(_ move: Runtime.Move) {
        guard var session else { return }
        session.perform(move)
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

/// Rakam yazılan varyantların giriş davranışı.
extension PuzzleGameModel where Runtime: DigitPuzzleRuntime {
    /// Rakam çubuğundan gelen giriş. Kalem kipinde aday, normal kipte kesin değer.
    func enter(_ digit: Int) {
        guard let session, let position = session.selection else { return }
        perform(
            isPencilMode
                ? Runtime.toggleCandidate(digit, at: position, on: session.board)
                : Runtime.write(digit, at: position, on: session.board)
        )
    }

    func erase() {
        guard let session, let position = session.selection else { return }
        perform(Runtime.erase(at: position, on: session.board))
    }

    var digits: ClosedRange<Int> {
        guard let session else { return 1...9 }
        return Runtime.digits(in: session.definition)
    }
}

/// Dokunuşla durum döndürülen varyantların giriş davranışı.
extension PuzzleGameModel where Runtime: CyclingPuzzleRuntime {
    func cycle(at location: Runtime.Location) {
        guard let session else { return }
        perform(Runtime.cycle(at: location, on: session.board, in: session.definition))
    }
}
