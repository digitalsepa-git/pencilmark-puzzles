import GameCore
import PuzzleKit
import SwiftUI

/// Beş varyantın bulmaca ekranı (brief b.7, ekran 3).
///
/// Her biri yalnız iki şeyi söylüyor: ızgara nasıl çiziliyor ve dokunuş hangi hamleye
/// dönüşüyor. Geri kalan her şey `PuzzleScaffold`'da.
///
/// Otomatik kayıt yok — oturum bellekte ve uygulama kapanırsa oyun kayboluyor. Kayıt
/// katmanı ayrı iş.
struct KakuroPuzzleScreen: View {
    @State private var model: PuzzleGameModel<KakuroRuntime>

    init(difficulty: Difficulty) {
        _model = State(initialValue: .freeplay(difficulty: difficulty))
    }

    /// Günlük bulmaca; gövde serbest oyunla aynı, değişen yalnız modelin nereden geldiği.
    init(day: CalendarDay) {
        _model = State(initialValue: .daily(on: day))
    }

    /// Yakınlaştırma ekranın durumu, oyunun değil: yarım kalan oyunla birlikte
    /// saklanmıyor ve ekrandan çıkınca sıfırlanıyor (ADR 0020).
    @State private var zoom = GridZoom.identity

    var body: some View {
        PuzzleScaffold(model: model) { session in
            KakuroGridView(
                puzzle: session.definition,
                board: session.board,
                selection: session.selection,
                mistakes: session.mistakes,
                zoom: $zoom,
                onTapEntry: { model.select($0) }
            )
        } footer: { session in
            NumberPad(
                digits: model.digits,
                isPencilMode: model.isPencilMode,
                isEnabled: session.selection != nil,
                onDigit: { model.enter($0) },
                onErase: { model.erase() }
            )
        }
    }
}

struct CalcudokuPuzzleScreen: View {
    @State private var model: PuzzleGameModel<CalcudokuRuntime>

    init(difficulty: Difficulty) {
        _model = State(initialValue: .freeplay(difficulty: difficulty))
    }

    /// Günlük bulmaca; gövde serbest oyunla aynı, değişen yalnız modelin nereden geldiği.
    init(day: CalendarDay) {
        _model = State(initialValue: .daily(on: day))
    }

    /// Yakınlaştırma ekranın durumu, oyunun değil: yarım kalan oyunla birlikte
    /// saklanmıyor ve ekrandan çıkınca sıfırlanıyor (ADR 0020).
    @State private var zoom = GridZoom.identity

    var body: some View {
        PuzzleScaffold(model: model) { session in
            CalcudokuGridView(
                puzzle: session.definition,
                board: session.board,
                selection: session.selection,
                mistakes: session.mistakes,
                zoom: $zoom,
                onTapCell: { model.select($0) }
            )
        } footer: { session in
            NumberPad(
                digits: model.digits,
                isPencilMode: model.isPencilMode,
                isEnabled: session.selection != nil,
                onDigit: { model.enter($0) },
                onErase: { model.erase() }
            )
        }
    }
}

/// Hitori'de rakam çubuğu yok: dokunuş hücreyi karala → işaretle → boş döngüsünde
/// çeviriyor (brief b.7).
struct HitoriPuzzleScreen: View {
    @State private var model: PuzzleGameModel<HitoriRuntime>

    init(difficulty: Difficulty) {
        _model = State(initialValue: .freeplay(difficulty: difficulty))
    }

    /// Günlük bulmaca; gövde serbest oyunla aynı, değişen yalnız modelin nereden geldiği.
    init(day: CalendarDay) {
        _model = State(initialValue: .daily(on: day))
    }

    /// Yakınlaştırma ekranın durumu, oyunun değil: yarım kalan oyunla birlikte
    /// saklanmıyor ve ekrandan çıkınca sıfırlanıyor (ADR 0020).
    @State private var zoom = GridZoom.identity

    var body: some View {
        PuzzleScaffold(model: model) { session in
            HitoriGridView(
                puzzle: session.definition,
                board: session.board,
                selection: session.selection,
                mistakes: session.mistakes,
                zoom: $zoom,
                onTapCell: { position in
                    model.select(position)
                    model.cycle(at: position)
                }
            )
        } footer: { _ in
            EmptyView()
        }
    }
}

/// Slitherlink'te oynanan şey kenarlar: dokunuş çizgi → çarpı → boş döngüsü.
struct SlitherlinkPuzzleScreen: View {
    @State private var model: PuzzleGameModel<SlitherlinkRuntime>

    init(difficulty: Difficulty) {
        _model = State(initialValue: .freeplay(difficulty: difficulty))
    }

    /// Günlük bulmaca; gövde serbest oyunla aynı, değişen yalnız modelin nereden geldiği.
    init(day: CalendarDay) {
        _model = State(initialValue: .daily(on: day))
    }

    /// Yakınlaştırma ekranın durumu, oyunun değil: yarım kalan oyunla birlikte
    /// saklanmıyor ve ekrandan çıkınca sıfırlanıyor (ADR 0020).
    @State private var zoom = GridZoom.identity

    var body: some View {
        PuzzleScaffold(model: model) { session in
            SlitherlinkGridView(
                puzzle: session.definition,
                board: session.board,
                mistakes: session.mistakes,
                zoom: $zoom,
                onTapEdge: { edge in
                    model.select(edge)
                    model.cycle(at: edge)
                }
            )
        } footer: { _ in
            EmptyView()
        }
    }
}

/// Hashi'de köprü sürüklemeyle kuruluyor, dokunuşla 0 → 1 → 2 → 0 döndürülüyor.
struct HashiPuzzleScreen: View {
    @State private var model: PuzzleGameModel<HashiRuntime>

    init(difficulty: Difficulty) {
        _model = State(initialValue: .freeplay(difficulty: difficulty))
    }

    /// Günlük bulmaca; gövde serbest oyunla aynı, değişen yalnız modelin nereden geldiği.
    init(day: CalendarDay) {
        _model = State(initialValue: .daily(on: day))
    }

    /// Yakınlaştırma ekranın durumu, oyunun değil: yarım kalan oyunla birlikte
    /// saklanmıyor ve ekrandan çıkınca sıfırlanıyor (ADR 0020).
    @State private var zoom = GridZoom.identity

    var body: some View {
        PuzzleScaffold(model: model) { session in
            HashiGridView(
                puzzle: session.definition,
                board: session.board,
                selection: session.selection,
                mistakes: session.mistakes,
                zoom: $zoom,
                onTapEdge: { edge in
                    model.select(edge)
                    model.cycle(at: edge)
                }
            )
        } footer: { _ in
            EmptyView()
        }
    }
}

/// Zorluk seçiminden doğru ekrana. `switch` burada tek yerde duruyor; varyant eklemek
/// ya da çıkarmak derleyicinin yakaladığı bir değişiklik oluyor.
struct PuzzleScreen: View {
    let variant: PuzzleVariantID
    let difficulty: Difficulty

    var body: some View {
        switch variant {
        case .kakuro: KakuroPuzzleScreen(difficulty: difficulty)
        case .calcudoku: CalcudokuPuzzleScreen(difficulty: difficulty)
        case .hitori: HitoriPuzzleScreen(difficulty: difficulty)
        case .slitherlink: SlitherlinkPuzzleScreen(difficulty: difficulty)
        case .hashi: HashiPuzzleScreen(difficulty: difficulty)
        }
    }
}

/// Günün bulmacasına götüren ekran. Varyant tarihten geliyor (ADR 0006).
///
/// Serbest oyunun `PuzzleScreen`'iyle aynı `switch`, farklı kurucu: günlük bulmacanın
/// ekranı serbest oyunun ekranından farklı değil, yalnız modeli farklı kuruluyor.
struct DailyPuzzleScreen: View {
    let day: CalendarDay

    var body: some View {
        switch DailyPuzzle.variant(on: day) {
        case .kakuro: KakuroPuzzleScreen(day: day)
        case .calcudoku: CalcudokuPuzzleScreen(day: day)
        case .hitori: HitoriPuzzleScreen(day: day)
        case .slitherlink: SlitherlinkPuzzleScreen(day: day)
        case .hashi: HashiPuzzleScreen(day: day)
        }
    }
}
