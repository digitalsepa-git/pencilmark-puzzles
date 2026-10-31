import Testing
import CoreGraphics
import SwiftUI
import PuzzleKit
import GameCore
@testable import Pencilmark

/// VoiceOver metinleri gözle kontrol edilemiyor — ekranda görünmüyorlar. Doğruluklarını
/// koruyan tek şey bu testler.
@Suite("Izgara erişilebilirlik metinleri")
struct GridAccessibilityTests {
    @Test("Konumlar 1'den sayılıyor")
    func placesAreOneBased() {
        #expect(GridAccessibility.place(Position(row: 0, column: 0)) == "Row 1, column 1")
        #expect(GridAccessibility.place(Position(row: 3, column: 7)) == "Row 4, column 8")
    }

    @Test("Kakuro ipucu hücresi iki toplamı da söylüyor")
    func kakuroClueReadsBothSums() {
        let scenario = TutorialScenarios.kakuro()
        let puzzle = scenario.definition

        #expect(GridAccessibility.kakuroLabel(at: Position(row: 1, column: 0), in: puzzle)
            == "Row 2, column 1, clue, across 3")
        #expect(GridAccessibility.kakuroLabel(at: Position(row: 0, column: 1), in: puzzle)
            == "Row 1, column 2, clue, down 9")
        #expect(GridAccessibility.kakuroLabel(at: Position(row: 0, column: 0), in: puzzle)
            == "Row 1, column 1, blocked")
        #expect(GridAccessibility.kakuroLabel(at: Position(row: 1, column: 1), in: puzzle)
            == "Row 2, column 2")
    }

    @Test("Rakam hücresinin değeri")
    func digitCellValues() {
        #expect(GridAccessibility.digitValue(DigitCell(value: 5)) == "5")
        #expect(GridAccessibility.digitValue(.empty) == "Empty")
        #expect(GridAccessibility.digitValue(DigitCell(value: nil, candidates: DigitSet([1, 4, 9])))
            == "Pencil marks 1, 4, 9")
        // Kesin değer varken adaylar gizleniyor (bkz. `DigitCell`); okuma da öyle.
        #expect(GridAccessibility.digitValue(DigitCell(value: 2, candidates: DigitSet([3])))
            == "2")
    }

    // Calcudoku'da rakam aralığı ızgara kenarı kadar; kalem işaretleri de o aralıkta
    // okunmalı, 9'a kadar değil.
    @Test("Calcudoku kalem işaretleri ızgara aralığında")
    func calcudokuPencilMarksRespectTheGridRange() {
        let cell = DigitCell(value: nil, candidates: DigitSet([1, 3]))
        #expect(GridAccessibility.digitValue(cell, upTo: 4) == "Pencil marks 1, 3")
    }

    @Test("Calcudoku kafesi işlemiyle okunuyor")
    func calcudokuCagesReadWithTheirOperation() {
        #expect(GridAccessibility.cageDescription(
            CalcudokuCage(cells: [0, 1], target: 7, operation: .add)) == "7 plus")
        #expect(GridAccessibility.cageDescription(
            CalcudokuCage(cells: [0, 1], target: 2, operation: .divide)) == "2 divided")
        #expect(GridAccessibility.cageDescription(
            CalcudokuCage(cells: [0], target: 3, operation: .given)) == "3")
    }

    @Test("Hitori hücresi sayısıyla ve durumuyla okunuyor")
    func hitoriCellsReadValueAndState() {
        let scenario = TutorialScenarios.hitori()
        #expect(GridAccessibility.hitoriLabel(at: Position(row: 0, column: 0),
                                              in: scenario.definition) == "Row 1, column 1, 3")
        #expect(GridAccessibility.shadeValue(.unknown) == "Undecided")
        #expect(GridAccessibility.shadeValue(.shaded) == "Shaded")
        #expect(GridAccessibility.shadeValue(.marked) == "Marked as kept")
    }

    // Kenar indeksi VoiceOver kullanıcısına hiçbir şey söylemez; kenar iki ucunun
    // arasındaki yer olarak anlatılıyor.
    @Test("Slitherlink kenarı uçlarıyla anlatılıyor")
    func slitherlinkEdgesReadTheirEndpoints() {
        let puzzle = TutorialScenarios.slitherlink().definition
        let label = GridAccessibility.slitherlinkEdgeLabel(0, in: puzzle)
        #expect(label == "Horizontal edge between point 1, 1 and point 1, 2")

        let vertical = GridAccessibility.slitherlinkEdgeLabel(puzzle.horizontalCount, in: puzzle)
        #expect(vertical.hasPrefix("Vertical edge between"))
    }

    @Test("Slitherlink ipucu hücresi")
    func slitherlinkCluesRead() {
        let puzzle = TutorialScenarios.slitherlink().definition
        #expect(GridAccessibility.slitherlinkClueLabel(at: 4, in: puzzle)
            == "Row 2, column 2, clue 0")
    }

    @Test("Slitherlink kenar durumu")
    func slitherlinkEdgeValues() {
        #expect(GridAccessibility.edgeValue(.unknown) == "Undecided")
        #expect(GridAccessibility.edgeValue(.line) == "Line")
        #expect(GridAccessibility.edgeValue(.cross) == "Crossed out")
    }

    // Adanın değeri kaç köprü gerektiğini **ve** kaçının çekildiğini söylüyor: VoiceOver
    // kullanıcısı köprüleri ekranda sayamıyor.
    @Test("Hashi adası kaç köprü gerektiğini ve kaçının çekildiğini söylüyor")
    func hashiIslandsReadProgress() {
        let scenario = TutorialScenarios.hashi()
        let puzzle = scenario.definition
        var board = HashiBoard(puzzle)

        #expect(GridAccessibility.hashiIslandLabel(0, in: puzzle)
            == "Row 1, column 1, island needing 2")
        #expect(GridAccessibility.hashiIslandValue(0, board: board, in: puzzle) == "0 of 2")

        // Adanın komşu kenarları indeks sırasına göre değil; hangi kenarların o adaya
        // değdiğini bulmacanın kendisi söylüyor.
        let incident = puzzle.incidentEdges[0]
        board[incident[0]] = 1
        #expect(GridAccessibility.hashiIslandValue(0, board: board, in: puzzle) == "1 of 2")
        board[incident[1]] = 1
        #expect(GridAccessibility.hashiIslandValue(0, board: board, in: puzzle)
            == "2 of 2, complete")
    }

    @Test("Hashi köprüsü iki adasıyla okunuyor")
    func hashiBridgesReadBothIslands() {
        let puzzle = TutorialScenarios.hashi().definition
        let label = GridAccessibility.hashiEdgeLabel(0, in: puzzle)
        #expect(label.hasPrefix("Bridge between Row "))
        #expect(label.contains(" and Row "))
    }

    @Test("Köprü sayısı")
    func bridgeCounts() {
        #expect(GridAccessibility.bridgeValue(0) == "No bridge")
        #expect(GridAccessibility.bridgeValue(1) == "Single bridge")
        #expect(GridAccessibility.bridgeValue(2) == "Double bridge")
    }

    // Çerçeve hesabı yanlışsa VoiceOver imleci ekranda yanlış yeri gösterir ve dokunarak
    // gezinme çalışmaz.
    @Test("Kenar çerçevesi doğru parçasını sarıyor")
    func edgeFramesWrapTheSegment() {
        let horizontal = SlitherlinkGridView.frame(
            from: CGPoint(x: 10, y: 20), to: CGPoint(x: 50, y: 20), thickness: 8
        )
        #expect(horizontal == CGRect(x: 10, y: 16, width: 40, height: 8))

        let vertical = SlitherlinkGridView.frame(
            from: CGPoint(x: 30, y: 10), to: CGPoint(x: 30, y: 60), thickness: 8
        )
        #expect(vertical == CGRect(x: 26, y: 10, width: 8, height: 50))
    }
}

/// Brief b.5 Dynamic Type'ı V1 kapsamına koyuyor; #59 "en büyük adımda hiçbir metin
/// kırpılmıyor" diyor. Kırpılma gözle görülen bir şey, ama en azından metnin büyüdüğünü
/// ve yerleşimin değiştiğini ölçebiliyoruz.
@Suite("Dynamic Type")
@MainActor
struct DynamicTypeTests {
    private let size = CGSize(width: 320, height: 420)

    private func differs(_ view: some View) throws -> Bool {
        let standard = SnapshotHarness.render(
            view, size: size, colorScheme: .light, dynamicTypeSize: .large
        )
        let largest = SnapshotHarness.render(
            view, size: size, colorScheme: .light, dynamicTypeSize: .accessibility5
        )
        let a = try #require(standard)
        let b = try #require(largest)
        return SnapshotHarness.compare(a, b).ratio > SnapshotHarness.allowedPixelRatio
    }

    @Test("Varyant satırı en büyük adımda büyüyor")
    func variantCardScales() throws {
        #expect(try differs(VariantRow(variant: .calcudoku, isAnimated: false)))
    }

    @Test("Günün satırı en büyük adımda büyüyor")
    func dailyCardScales() throws {
        #expect(try differs(
            DailyRow(day: CalendarDay(year: 2026, month: 10, day: 24), isSolved: false)
        ))
    }

    @Test("İstatistik ekranı en büyük adımda büyüyor")
    func statsScale() throws {
        #expect(try differs(StatsContent(summary: StatsFixtures.summary())))
    }

    // Izgara rakamları bilinçli olarak Dynamic Type'a uymuyor, hücreyle büyüyorlar
    // (gerekçesi `GridStyle`'da). Bu testin işi o kararın kazara değişmediğini korumak.
    @Test("Izgara rakamları Dynamic Type ile büyümüyor")
    func gridDigitsIgnoreDynamicType() throws {
        let fixture = SnapshotFixtures.kakuro()
        #expect(try !differs(
            KakuroGridView(puzzle: fixture.puzzle, board: fixture.board)
        ))
    }
}
