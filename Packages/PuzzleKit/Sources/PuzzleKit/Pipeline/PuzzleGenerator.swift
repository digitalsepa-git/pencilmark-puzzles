/// Varyantın üreticisi.
///
/// Üretici yalnızca *aday* üretir. Adayın kullanıcıya gidip gitmeyeceğine
/// `GenerationPipeline` karar verir; benzersizlik kontrolü üreticinin elinde değil.
/// Bu ayrım bilinçli: üreticiyi yazan kişi "bu aday zaten benzersizdir" diye
/// kestirmeden geçemesin.
public protocol PuzzleGenerator: Sendable {
    associatedtype Definition: Sendable
    associatedtype Solution: Sendable
    associatedtype Solver: PuzzleSolver
        where Solver.Definition == Definition, Solver.Solution == Solution

    var variant: PuzzleVariantID { get }
    var solver: Solver { get }

    /// Hedef zorluğa uygun bir aday kurar. Benzersiz olup olmadığını kontrol etmez.
    func makeCandidate(
        difficulty: Difficulty,
        using rng: inout SeededGenerator
    ) throws -> Definition

    /// Çözüm izini varyantın zorluk ölçeğine çevirir.
    ///
    /// `nil` dönmek "bu bulmaca kullanıcıya verilmez" demek ve hat adayı eler. Varyantların
    /// buna ihtiyacı var: tek çözümü olan bir bulmaca mantıkla çözülemeyebilir ve o bulmaca
    /// hiçbir zorluk seviyesine ait değil, atılması gerekiyor.
    func rate(_ trace: SolveTrace, of definition: Definition) -> Difficulty?
}

extension PuzzleGenerator {
    /// Varsayılan: teknik seviyesi doğrudan zorluğa eşlenir (ADR 0005).
    public func rate(_ trace: SolveTrace, of definition: Definition) -> Difficulty? {
        trace.difficulty
    }
}
