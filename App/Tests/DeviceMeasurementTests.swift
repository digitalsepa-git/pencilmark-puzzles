import Foundation
import Testing
import GameCore
import PuzzleKit
@testable import Pencilmark

/// Cihazda ölçüm (#66, brief b.11, ADR 0003).
///
/// **Yalnız gerçek cihazda koşuyor.** Simülatör Mac'in işlemcisiyle çalışıyor ve oradan
/// çıkan sayı telefonun ne yapacağını söylemiyor — ADR 0003 hedefi zaten "cihazda 1
/// saniyenin altında" diye koymuştu. CI simülatörde koştuğu için bu takım orada atlanıyor;
/// böylece CI süresi de üretimle şişmiyor.
///
/// Koşturmak için:
/// ```
/// xcodebuild test -project App/Pencilmark.xcodeproj -scheme Pencilmark \
///   -destination "platform=iOS,id=<cihaz-udid>" -allowProvisioningUpdates \
///   -only-testing:PencilmarkTests/DeviceMeasurementTests
/// ```
@Suite("Cihazda ölçüm", .serialized, .enabled(if: !DeviceMeasurement.isSimulator))
struct DeviceMeasurementTests {
    /// Zorluk başına kaç bulmaca üretilsin. Expert'te üretim saniyeler sürebiliyor;
    /// üç ölçüm ortancayı anlamlı kılacak kadar, koşuyu dakikalara taşımayacak kadar.
    private let iterations = 3

    @Test("Kakuro üretim süresi", arguments: Difficulty.allCases)
    func kakuroGeneration(difficulty: Difficulty) throws {
        try DeviceMeasurement.report(
            KakuroRuntime.self, difficulty: difficulty, iterations: iterations
        )
    }

    @Test("Calcudoku üretim süresi", arguments: Difficulty.allCases)
    func calcudokuGeneration(difficulty: Difficulty) throws {
        try DeviceMeasurement.report(
            CalcudokuRuntime.self, difficulty: difficulty, iterations: iterations
        )
    }

    @Test("Slitherlink üretim süresi", arguments: Difficulty.allCases)
    func slitherlinkGeneration(difficulty: Difficulty) throws {
        try DeviceMeasurement.report(
            SlitherlinkRuntime.self, difficulty: difficulty, iterations: iterations
        )
    }

    @Test("Hashi üretim süresi", arguments: Difficulty.allCases)
    func hashiGeneration(difficulty: Difficulty) throws {
        try DeviceMeasurement.report(
            HashiRuntime.self, difficulty: difficulty, iterations: iterations
        )
    }

    @Test("Hitori üretim süresi", arguments: Difficulty.allCases)
    func hitoriGeneration(difficulty: Difficulty) throws {
        try DeviceMeasurement.report(
            HitoriRuntime.self, difficulty: difficulty, iterations: iterations
        )
    }
}

enum DeviceMeasurement {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    /// Brief b.11'in cihaz hedefi 2 saniye; ADR 0003 bunu 1 saniyeye çekti (iPhone 12'ye
    /// pay bırakmak için). Test o hedefi **kırmıyor**: ölçüm bir kapı değil, kayıt.
    /// Kırılan tek şey katastrofik durum — üretim hiç dönmüyorsa.
    static let catastrophicCeiling = Duration.seconds(20)

    /// Hedef aşıldığında çıktıya işaret konuyor; sayı yine de yazılıyor.
    static let target = Duration.seconds(1)

    static func report<Runtime: PuzzleRuntime>(
        _ type: Runtime.Type,
        difficulty: Difficulty,
        iterations: Int
    ) throws {
        var durations: [Duration] = []
        let clock = ContinuousClock()

        for index in 0..<iterations {
            // Her ölçüm farklı tohum: aynı tohumu tekrar üretmek önbelleği değil ama
            // tek bir bulmacanın şansını ölçerdi.
            let seed = Seed.free(
                variant: Runtime.variant,
                difficulty: difficulty,
                counter: UInt64(index + 1)
            )
            let elapsed = try clock.measure {
                _ = try Runtime.generate(difficulty: difficulty, seed: seed)
            }
            durations.append(elapsed)
        }

        durations.sort()
        let median = durations[durations.count / 2]
        let worst = durations[durations.count - 1]
        let flag = worst > target ? " ⚠︎ hedefin üstünde" : ""

        print(
            """
            [cihaz] \(Runtime.variant.rawValue) · \(difficulty.rawValue): \
            ortanca \(median.milliseconds) ms · en kötü \(worst.milliseconds) ms\(flag)
            """
        )

        #expect(
            worst <= catastrophicCeiling,
            "\(Runtime.variant.rawValue) \(difficulty.rawValue) üretimi \(worst.milliseconds) ms"
        )
    }
}

private extension Duration {
    var milliseconds: String {
        String(format: "%.0f", Double(components.attoseconds) / 1e15
            + Double(components.seconds) * 1000)
    }
}
