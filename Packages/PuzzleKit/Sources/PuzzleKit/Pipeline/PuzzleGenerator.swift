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
}
