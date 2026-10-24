import PuzzleKit

/// Etkileşimli öğreticinin tek adımı (ADR 0009).
///
/// Adımın tamamlandığı **tahtaya bakılarak** anlaşılıyor, belirli bir hamle beklenerek
/// değil. Sebebi ADR'nin "kullanıcı gerçekten hamle yapıyor" maddesi: bir adım çoğu zaman
/// "şu iki hücreden birini karala" gibi birden çok doğru hamleye açık ve beklenen hamleyi
/// tek tek yazmak o esnekliği öldürürdü.
public struct TutorialStep<Runtime: PuzzleRuntime>: Sendable {
    /// Izgaranın üstünde duran tek cümle (ADR 0009).
    public let text: String
    /// Yanlış hamle sonrası gösterilen tek cümle. ADR 0009: yanlış hamle engellenmiyor,
    /// nazikçe düzeltiliyor — kuralı ihlal eden hamle kullanıcıya kuralı öğretiyor.
    public let correction: String
    /// Adım tamamlandı mı.
    public let isComplete: @Sendable (Runtime.Board) -> Bool

    public init(
        text: String,
        correction: String,
        isComplete: @escaping @Sendable (Runtime.Board) -> Bool
    ) {
        self.text = text
        self.correction = correction
        self.isComplete = isComplete
    }
}

/// Bir varyantın öğretici senaryosu.
///
/// Izgara **elle hazırlanmış**, üretilmiş değil (ADR 0009): öğretici belirli bir tekniği
/// belirli bir sırada göstermek zorunda ve üretilmiş bulmaca bunu garanti etmiyor. Bu
/// yüzden burada `GenerationPipeline` yok — motor kullanılıyor, hat kullanılmıyor.
/// Senaryoların benzersizliği ayrı bir testte çözücüyle doğrulanıyor.
public struct TutorialScenario<Runtime: PuzzleRuntime>: Sendable {
    public let definition: Runtime.Definition
    public let solution: Runtime.Solution
    public let steps: [TutorialStep<Runtime>]

    public init(
        definition: Runtime.Definition,
        solution: Runtime.Solution,
        steps: [TutorialStep<Runtime>]
    ) {
        precondition(!steps.isEmpty, "Öğretici en az bir adım içermeli")
        self.definition = definition
        self.solution = solution
        self.steps = steps
    }
}

/// Öğreticinin durumu: hangi adımdayız, oyuncu hata yaptı mı, bitti mi.
///
/// Oyun oturumunun üstüne biniyor, yerine geçmiyor: tahta, geri alma ve kurallar yine
/// `GameSession`'da. Buradaki tek iş adımları ilerletmek.
public struct TutorialRun<Runtime: PuzzleRuntime>: Sendable {
    public let scenario: TutorialScenario<Runtime>
    public private(set) var session: GameSession<Runtime>
    public private(set) var stepIndex = 0
    /// Son hamle çözümle çelişiyorsa gösterilecek cümle.
    public private(set) var correction: String?

    public init(scenario: TutorialScenario<Runtime>) {
        self.scenario = scenario
        self.session = GameSession<Runtime>(
            definition: scenario.definition,
            solution: scenario.solution
        )
    }

    public var isFinished: Bool { stepIndex >= scenario.steps.count }

    public var currentStep: TutorialStep<Runtime>? {
        isFinished ? nil : scenario.steps[stepIndex]
    }

    public var stepNumber: Int { min(stepIndex + 1, scenario.steps.count) }
    public var stepCount: Int { scenario.steps.count }

    /// Oyuncunun hamlesi.
    ///
    /// Hamle her durumda uygulanıyor — ADR 0009 yanlış hamleyi engellemiyor. Çözümle
    /// çelişiyorsa düzeltme cümlesi gösteriliyor ve adım ilerlemiyor; oyuncu geri alıp
    /// devam ediyor.
    public mutating func perform(_ move: Runtime.Move) {
        guard let step = currentStep else { return }
        session.perform(move)

        let mistakes = Runtime.mistakes(
            in: session.board,
            against: scenario.solution,
            in: scenario.definition
        )
        if !mistakes.isEmpty {
            correction = step.correction
            return
        }

        correction = nil
        // Birden çok adım birden tamamlanmış olabilir: oyuncu istenenden fazlasını
        // yaptıysa öğretici geride kalmıyor.
        while let pending = currentStep, pending.isComplete(session.board) {
            stepIndex += 1
        }
    }

    /// Yanlış hamleyi geri alıyor; düzeltme uyarısı da kalkıyor.
    public mutating func undo() {
        session.undo()
        correction = nil
    }
}
