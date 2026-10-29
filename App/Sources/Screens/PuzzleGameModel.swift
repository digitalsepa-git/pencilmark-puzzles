import Foundation
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
    /// Serbest oyun mu günlük bulmaca mı; kayda ve ücretsiz katman kotasına giriyor.
    let kind: PuzzleRecord.Kind
    let timer = PuzzleTimer()

    /// Devam eden oyunda tohum saklanandan geliyor: serbest oyunun tohumu her açılışta
    /// rastgele ve onunla başka bir bulmaca üretilirdi.
    private(set) var seed: UInt64
    private var hasRecorded = false
    private var pendingResume: GameSnapshot<Runtime.Move>?

    /// Bulmaca bittiğinde bir kez çağrılıyor. Kaydı kimin yazacağını model bilmiyor;
    /// bildiği şey kaydın içeriği.
    var onFinish: ((PuzzleRecord) -> Void)?

    /// Her hamleden sonra çağrılıyor (brief b.7: otomatik kayıt her hamlede).
    var onChange: ((GameSnapshot<Runtime.Move>, Int) -> Void)?

    /// Anlık kipte yeni bir hata belirdiğinde. Dokunsal geri bildirim buna bağlı.
    var onMistakeAppeared: (() -> Void)?

    /// Hata kontrolü kipi; kullanıcı tercihinden geliyor ve oturum kurulurken
    /// uygulanıyor (`start()` öncesinde verilmek zorunda).
    var errorChecking: ErrorChecking = .manual

    /// Önden üretilmiş bulmacaların önbelleği. `start()` öncesinde verilmek zorunda.
    var prefetcher: PuzzlePrefetcher?

    init(difficulty: Difficulty, seed: UInt64, kind: PuzzleRecord.Kind = .free) {
        self.difficulty = difficulty
        self.seed = seed
        self.kind = kind
    }

    /// Günlük bulmaca: tohum tarihten türüyor, zorluk sabit (ADR 0006).
    static func daily(on day: CalendarDay) -> PuzzleGameModel<Runtime> {
        PuzzleGameModel(
            difficulty: DailyPuzzle.difficulty,
            seed: DailyPuzzle.seed(on: day),
            kind: .daily
        )
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

    /// Saklanan bir oyunu benimsiyor: tohum, hamleler ve geçen süre oradan geliyor.
    /// `start()` çağrılmadan önce verilmek zorunda.
    func adopt(_ resumed: ResumedGame<Runtime.Move>) {
        seed = resumed.seed
        pendingResume = resumed.snapshot
        timer.restore(seconds: resumed.seconds)
    }

    func start() async {
        phase = .generating
        let difficulty = difficulty
        let seed = seed
        do {
            let puzzle: GeneratedPuzzle<Runtime.Definition, Runtime.Solution>
            // Yarım kalan oyun varsa önbellek kullanılmıyor: oyuncunun hamleleri o
            // bulmacaya ait ve başka bir bulmacaya uymaz.
            if pendingResume == nil, kind == .free,
               let waiting = prefetcher?.take(Runtime.self, difficulty: difficulty) {
                puzzle = waiting
                // Tohum önbellekten geliyor; saklama ve devam etme buna bakıyor.
                self.seed = waiting.seed
            } else {
                // Üretim ana iş parçacığının dışında: Expert Kakuro'nun en kötü ölçümü
                // 1.222 ms ve o süre boyunca arayüzün donması kabul edilemez (ADR 0013).
                puzzle = try await Task.detached(priority: .userInitiated) {
                    try Runtime.generate(difficulty: difficulty, seed: seed)
                }.value
            }
            if let pendingResume {
                session = GameSession<Runtime>(
                    definition: puzzle.definition,
                    solution: puzzle.solution,
                    snapshot: pendingResume,
                    errorChecking: errorChecking
                )
                self.pendingResume = nil
            } else {
                session = GameSession<Runtime>(
                    definition: puzzle.definition,
                    solution: puzzle.solution,
                    errorChecking: errorChecking
                )
            }
            phase = .playing
            // Sıradakini şimdiden üretmeye başla: oyuncu bu bulmacayı oynarken üretim
            // bitiyor ve bir sonraki açılış beklemesiz oluyor.
            prefetcher?.prime(Runtime.self, difficulty: difficulty)
            // Devam eden oyun zaten bitmiş olabilir: oyuncu son hamlesini yapıp kayıt
            // yazılamadan uygulamayı kapatmış olabilir.
            if isSolved {
                finishIfSolved()
            } else {
                timer.start()
            }
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    func select(_ location: Runtime.Location?) {
        session?.selection = location
    }

    func perform(_ move: Runtime.Move) {
        guard var session else { return }
        let mistakesBefore = session.mistakes.count
        session.perform(move)
        self.session = session
        // Yalnız **yeni** bir hata belirdiğinde: aynı hatayla dolu bir tahtada her
        // hamlede titremek, geri bildirimi gürültüye çeviriyor.
        if session.mistakes.count > mistakesBefore {
            onMistakeAppeared?()
        }
        finishIfSolved()
        persist()
    }

    /// Ekran arka plana alınınca sayaç duruyor, dönünce devam ediyor.
    func setActive(_ isActive: Bool) {
        guard phase == .playing, !isSolved else { return }
        if isActive {
            timer.start()
        } else {
            timer.pause()
            // Arka plana alınırken geçen süre de kaydediliyor; yoksa son hamleden
            // sonraki dakikalar kayboluyordu.
            persist()
        }
    }

    /// Yarım kalan oyunu bildiriyor. Bitmiş bulmacada çağrılmıyor: biten oyunun kaydı
    /// `onFinish` ile yazılıyor ve yarım kalan satırı siliniyor.
    private func persist() {
        guard let session, !isSolved else { return }
        onChange?(session.snapshot, timer.seconds)
    }

    /// Bulmaca bitti mi; bittiyse sayacı durdurup kaydı bir kez bildiriyor.
    private func finishIfSolved() {
        guard !hasRecorded, isSolved else { return }
        hasRecorded = true
        timer.stop()
        onFinish?(
            PuzzleRecord(
                variant: Runtime.variant,
                difficulty: difficulty,
                kind: kind,
                day: LocalCalendar.today(),
                seconds: Int(timer.elapsed),
                hintCount: hintCount
            )
        )
    }

    func undo() {
        guard var session else { return }
        session.undo()
        self.session = session
        persist()
    }

    func redo() {
        guard var session else { return }
        session.redo()
        self.session = session
        persist()
    }

    /// İpucu açıyor ve gerçekten bir şey açıldıysa `true` dönüyor.
    ///
    /// Dönüş değeri kota için: tahta doluyken ya da bitmiş bulmacada ipucu açılmıyor ve
    /// açılmayan bir ipucu hak harcamamalı (ADR 0007).
    @discardableResult
    func hint() -> Bool {
        guard var session else { return false }
        let revealed = session.revealHint()
        if let revealed {
            session.selection = revealed
        }
        self.session = session
        finishIfSolved()
        persist()
        return revealed != nil
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
