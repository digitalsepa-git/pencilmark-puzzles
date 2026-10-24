import PuzzleKit

/// Tek bir bulmaca oturumu: tahta, geri alma yığını, ipucu sayacı, hata kontrolü.
///
/// Değer tipi ve `Sendable`; arayüzden bağımsız olduğu için Linux'ta test ediliyor. Kayıt
/// (otomatik kaydetme) burada değil: oturumun ne zaman yazılacağı uygulama katmanının
/// kararı ve `Persistence` ayrı bir iş.
public struct GameSession<Runtime: PuzzleRuntime>: Sendable {
    /// Brief b.7: "Hata kontrolü iki modda: kullanıcı isterse anlık, varsayılan manuel."
    public enum ErrorChecking: Sendable, Hashable {
        /// Yanlış giriş anında kızarır.
        case immediate
        /// Yanlışlar yalnız oyuncu kontrol isteyince işaretlenir.
        case manual
    }

    public let definition: Runtime.Definition
    public let solution: Runtime.Solution

    public private(set) var board: Runtime.Board
    public private(set) var history = MoveHistory<Runtime.Move>()

    /// Kaç ipucu açıldı. Brief b.7: ipucu kullanılan bulmaca "çözüldü" sayılıyor ama
    /// istatistikte ayrı işaretleniyor, bu yüzden sayı oturumla birlikte taşınıyor.
    public private(set) var hintCount = 0

    /// Son kontrolde çözümle çelişen yerler. Manuel kipte `check()` çağrılana kadar boş.
    public private(set) var mistakes: Set<Runtime.Location> = []

    /// Oyuncunun seçili hücresi veya kenarı.
    public var selection: Runtime.Location?

    public var errorChecking: ErrorChecking {
        didSet {
            guard errorChecking != oldValue else { return }
            switch errorChecking {
            case .immediate: check()
            case .manual: mistakes.removeAll()
            }
        }
    }

    public init(
        definition: Runtime.Definition,
        solution: Runtime.Solution,
        errorChecking: ErrorChecking = .manual
    ) {
        self.definition = definition
        self.solution = solution
        self.board = Runtime.emptyBoard(for: definition)
        self.errorChecking = errorChecking
    }

    public var isSolved: Bool { Runtime.isSolved(board, in: definition) }
    public var usedHints: Bool { hintCount > 0 }
    public var canUndo: Bool { history.canUndo }
    public var canRedo: Bool { history.canRedo }

    /// Oyuncunun bir hareketi. Hamlenin tetiklediği yan hamleler aynı geri alma öbeğine
    /// giriyor, böylece tek dokunuşla yapılan şey tek dokunuşla geri alınıyor.
    public mutating func perform(_ move: Runtime.Move) {
        move.apply(to: &board)
        var group = [move]
        for companion in Runtime.companionMoves(after: move, on: board, in: definition) {
            companion.apply(to: &board)
            group.append(companion)
        }
        history.record(group)
        refreshIfImmediate()
    }

    @discardableResult
    public mutating func undo() -> Bool {
        guard let group = history.undo() else { return false }
        for move in group.reversed() {
            move.undo(on: &board)
        }
        refreshIfImmediate()
        return true
    }

    @discardableResult
    public mutating func redo() -> Bool {
        guard let group = history.redo() else { return false }
        for move in group {
            move.apply(to: &board)
        }
        refreshIfImmediate()
        return true
    }

    /// Tek bir hücreyi veya kenarı açıyor ve sayacı artırıyor.
    ///
    /// İpucu hamlesi geri alınabilir ama sayaç geri alınmıyor: istatistikte ipucunun
    /// kullanıldığı, sonra geri alınıp alınmadığından bağımsız olarak doğru.
    @discardableResult
    public mutating func revealHint() -> Runtime.Location? {
        guard let move = Runtime.hintMove(for: board, toward: solution, in: definition) else {
            return nil
        }
        perform(move)
        hintCount += 1
        return Runtime.location(of: move)
    }

    /// Oyuncunun istediği kontrol (manuel kip).
    public mutating func check() {
        mistakes = Runtime.mistakes(in: board, against: solution, in: definition)
    }

    private mutating func refreshIfImmediate() {
        guard errorChecking == .immediate else { return }
        check()
    }
}
