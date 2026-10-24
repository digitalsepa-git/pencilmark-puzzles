import Testing
import PuzzleKit
import GameCore

/// İpucuyla bulmacayı bitirmek beş varyantın hepsinde aynı testi veriyor: `hintMove`
/// doğruysa oturum er geç çözüme varır, yanlışsa ya takılır ya hiç bitmez.
private func solveWithHints<Runtime: PuzzleRuntime>(
    _ session: inout GameSession<Runtime>,
    limit: Int
) -> Int {
    var steps = 0
    while !session.isSolved && steps < limit {
        guard session.revealHint() != nil else { break }
        steps += 1
    }
    return steps
}

@Suite("Oyun oturumu")
struct GameSessionTests {
    private func kakuro(
        _ difficulty: Difficulty = .easy,
        seed: UInt64 = 11
    ) throws -> GameSession<KakuroRuntime> {
        let puzzle = try KakuroGenerator.pipeline().generate(difficulty: difficulty, seed: seed)
        return GameSession<KakuroRuntime>(
            definition: puzzle.definition,
            solution: puzzle.solution
        )
    }

    @Test("Yeni oturum boş tahtayla ve geçmişsiz başlıyor")
    func freshSessionStartsEmpty() throws {
        let session = try kakuro()
        #expect(session.board.isEmpty(in: session.definition))
        #expect(!session.isSolved)
        #expect(!session.canUndo)
        #expect(!session.canRedo)
        #expect(session.hintCount == 0)
        #expect(!session.usedHints)
        #expect(session.mistakes.isEmpty)
        #expect(session.errorChecking == .manual)
    }

    @Test("Hamle uygulanıyor, geri alınıyor ve ileri alınıyor")
    func moveAppliesUndoesAndRedoes() throws {
        var session = try kakuro()
        let position = session.definition.position(of: session.definition.entryCells[0])

        session.perform(.writing(3, at: position, on: session.board))
        #expect(session.board.value(at: position) == 3)
        #expect(session.canUndo)

        let didChange1 = session.undo()
        #expect(didChange1)
        #expect(session.board.value(at: position) == nil)
        #expect(session.canRedo)

        let didChange2 = session.redo()
        #expect(didChange2)
        #expect(session.board.value(at: position) == 3)
    }

    @Test("Boş geçmişte geri ve ileri alma yanlış dönüyor")
    func undoOnEmptyHistoryFails() throws {
        var session = try kakuro()
        let undone = session.undo()
        let redone = session.redo()
        #expect(!undone)
        #expect(!redone)
    }

    @Test("Kalem işareti geri alınabiliyor")
    func pencilMarksAreUndoable() throws {
        var session = try kakuro()
        let position = session.definition.position(of: session.definition.entryCells[0])

        session.perform(.togglingCandidate(4, at: position, on: session.board))
        session.perform(.togglingCandidate(7, at: position, on: session.board))
        #expect(session.board[position].candidates.contains(4))
        #expect(session.board[position].candidates.contains(7))

        let didChange3 = session.undo()
        #expect(didChange3)
        #expect(!session.board[position].candidates.contains(7))
        #expect(session.board[position].candidates.contains(4))
    }

    // Rakip analizindeki (PR #10) istek: bir rakam kesinleşince aynı kesitteki adaylar
    // kendiliğinden güncellensin. Bunun oturum tarafındaki şartı, hepsinin **tek** geri
    // alma öbeğinde olması: oyuncu tek dokunuşla yaptığını tek dokunuşla geri almalı.
    @Test("Rakam yazmak kesitteki adayları siliyor ve tek geri alma hepsini döndürüyor")
    func writingClearsPeerCandidatesAsOneAction() throws {
        var session = try kakuro()
        let definition = session.definition
        let origin = definition.entryCells[0]
        let run = definition.runs[definition.runsOfCell[origin][0]]
        let peers = run.cells.filter { $0 != origin }.map { definition.position(of: $0) }
        try #require(!peers.isEmpty)

        for peer in peers {
            session.perform(.togglingCandidate(5, at: peer, on: session.board))
        }
        let actionsBefore = session.history.actionCount

        session.perform(.writing(5, at: definition.position(of: origin), on: session.board))
        for peer in peers {
            #expect(!session.board[peer].candidates.contains(5))
        }
        #expect(session.history.actionCount == actionsBefore + 1)

        let didChange4 = session.undo()
        #expect(didChange4)
        for peer in peers {
            #expect(session.board[peer].candidates.contains(5))
        }
    }

    @Test("Aynı rakamı tekrar yazmak yan hamle üretmiyor")
    func rewritingTheSameDigitProducesNoCompanions() throws {
        var session = try kakuro()
        let definition = session.definition
        let position = definition.position(of: definition.entryCells[0])

        session.perform(.writing(5, at: position, on: session.board))
        let boardAfterFirst = session.board
        session.perform(.writing(5, at: position, on: session.board))
        #expect(session.board == boardAfterFirst)
    }

    @Test("İpucu doğru değeri yazıyor ve sayacı artırıyor")
    func hintWritesTheSolutionValue() throws {
        var session = try kakuro()
        let hinted = session.revealHint()
        let revealed = try #require(hinted)

        #expect(session.hintCount == 1)
        #expect(session.usedHints)
        #expect(session.board.value(at: revealed) == session.solution.values[revealed])
    }

    // İpucu hamlesi geri alınabiliyor ama sayaç geri alınmıyor: istatistikte "ipucu
    // kullanıldı" bilgisi, sonradan geri alınmasından bağımsız olarak doğru.
    @Test("İpucunun geri alınması sayacı düşürmüyor")
    func undoingAHintKeepsTheCounter() throws {
        var session = try kakuro()
        _ = session.revealHint()
        let didChange5 = session.undo()
        #expect(didChange5)
        #expect(session.hintCount == 1)
    }

    @Test("Hata kontrolü varsayılan olarak manuel")
    func errorCheckingIsManualByDefault() throws {
        var session = try kakuro()
        let position = session.definition.position(of: session.definition.entryCells[0])
        let correct = session.solution.values[position]
        let wrong = correct == 9 ? 1 : correct + 1

        session.perform(.writing(wrong, at: position, on: session.board))
        #expect(session.mistakes.isEmpty)

        session.check()
        #expect(session.mistakes.contains(position))
    }

    @Test("Anlık kipte hata yazılır yazılmaz işaretleniyor")
    func immediateModeFlagsMistakesAsTheyHappen() throws {
        var session = try kakuro()
        session.errorChecking = .immediate
        let position = session.definition.position(of: session.definition.entryCells[0])
        let correct = session.solution.values[position]
        let wrong = correct == 9 ? 1 : correct + 1

        session.perform(.writing(wrong, at: position, on: session.board))
        #expect(session.mistakes.contains(position))

        let didChange6 = session.undo()
        #expect(didChange6)
        #expect(session.mistakes.isEmpty)
    }

    @Test("Manuel kipe dönmek işaretleri temizliyor")
    func switchingBackToManualClearsFlags() throws {
        var session = try kakuro()
        session.errorChecking = .immediate
        let position = session.definition.position(of: session.definition.entryCells[0])
        let correct = session.solution.values[position]
        session.perform(.writing(correct == 9 ? 1 : correct + 1, at: position, on: session.board))
        #expect(!session.mistakes.isEmpty)

        session.errorChecking = .manual
        #expect(session.mistakes.isEmpty)
    }

    @Test("Boş hücre hata değil")
    func emptyCellsAreNotMistakes() throws {
        var session = try kakuro()
        session.check()
        #expect(session.mistakes.isEmpty)
    }
}

@Suite("Oturum — beş varyant")
struct RuntimeCoverageTests {
    @Test("Kakuro ipucuyla çözülüyor")
    func kakuroSolvesWithHints() throws {
        let puzzle = try KakuroGenerator.pipeline().generate(difficulty: .easy, seed: 21)
        var session = GameSession<KakuroRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )
        _ = solveWithHints(&session, limit: 200)
        #expect(session.isSolved)
        #expect(session.hintCount == puzzle.definition.entryCells.count)
    }

    @Test("Calcudoku ipucuyla çözülüyor")
    func calcudokuSolvesWithHints() throws {
        let puzzle = try CalcudokuGenerator.pipeline().generate(difficulty: .easy, seed: 22)
        var session = GameSession<CalcudokuRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )
        _ = solveWithHints(&session, limit: 200)
        #expect(session.isSolved)
    }

    @Test("Hitori ipucuyla çözülüyor")
    func hitoriSolvesWithHints() throws {
        let puzzle = try HitoriGenerator.pipeline().generate(difficulty: .easy, seed: 23)
        var session = GameSession<HitoriRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )
        _ = solveWithHints(&session, limit: 200)
        #expect(session.isSolved)
    }

    @Test("Hashi ipucuyla çözülüyor")
    func hashiSolvesWithHints() throws {
        let puzzle = try HashiGenerator.pipeline().generate(difficulty: .easy, seed: 24)
        var session = GameSession<HashiRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )
        _ = solveWithHints(&session, limit: 300)
        #expect(session.isSolved)
    }

    @Test("Slitherlink ipucuyla çözülüyor")
    func slitherlinkSolvesWithHints() throws {
        let puzzle = try SlitherlinkGenerator.pipeline().generate(difficulty: .easy, seed: 25)
        var session = GameSession<SlitherlinkRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )
        _ = solveWithHints(&session, limit: 400)
        #expect(session.isSolved)
    }

    // Hitori'de `unknown` hata değil: oyuncu her beyaz hücreyi ayrıca işaretlemek zorunda
    // değil. Karar verilmiş ama çözümle çelişen hücre hata.
    @Test("Hitori: karar verilmemiş hücre hata değil, yanlış karalama hata")
    func hitoriMistakesIgnoreUndecidedCells() throws {
        let puzzle = try HitoriGenerator.pipeline().generate(difficulty: .easy, seed: 26)
        var session = GameSession<HitoriRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )
        session.check()
        #expect(session.mistakes.isEmpty)

        let white = try #require(
            puzzle.definition.size.allPositions.first { !puzzle.solution.shaded[$0] }
        )
        session.perform(HitoriMove(position: white, previous: .unknown, next: .shaded))
        session.check()
        #expect(session.mistakes == [white])
    }

    // Hashi'de eksik köprü hata değil, eksik. Fazlası hata, çünkü geri almadan düzelmiyor.
    @Test("Hashi: eksik köprü hata değil, fazlası hata")
    func hashiMistakesOnlyCountExcessBridges() throws {
        let puzzle = try HashiGenerator.pipeline().generate(difficulty: .easy, seed: 27)
        var session = GameSession<HashiRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )

        let doubled = try #require(puzzle.solution.counts.firstIndex(of: 2))
        session.perform(HashiMove(edge: doubled, previous: 0, next: 1))
        session.check()
        #expect(session.mistakes.isEmpty)

        let empty = try #require(puzzle.solution.counts.firstIndex(of: 0))
        session.perform(HashiMove(edge: empty, previous: 0, next: 1))
        session.check()
        #expect(session.mistakes == [empty])
    }

    // Slitherlink'te çarpı da bir karar: çözümde çizgi olan kenara çarpı koymak hata.
    @Test("Slitherlink: yanlış çarpı hata")
    func slitherlinkMistakesIncludeWrongCrosses() throws {
        let puzzle = try SlitherlinkGenerator.pipeline().generate(difficulty: .easy, seed: 28)
        var session = GameSession<SlitherlinkRuntime>(
            definition: puzzle.definition, solution: puzzle.solution
        )

        let line = try #require(puzzle.solution.lines.firstIndex(of: true))
        session.perform(SlitherlinkMove(edge: line, previous: .unknown, next: .cross))
        session.check()
        #expect(session.mistakes == [line])

        let didChange7 = session.undo()
        #expect(didChange7)
        session.check()
        #expect(session.mistakes.isEmpty)
    }
}
