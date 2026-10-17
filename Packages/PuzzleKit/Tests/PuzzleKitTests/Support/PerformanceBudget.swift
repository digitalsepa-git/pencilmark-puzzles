import Testing

// Performans ölçümü için paylaşılan yardımcı.
//
// Brief b.11'in gerçek bütçesi "Expert seviyede iPhone 12'de 2 saniyenin altında" ve bu
// yalnızca cihazda ölçülebilir. CI runner'ı ne o cihazdır ne de kararlı bir ölçüm verir,
// bu yüzden CI'daki eşik gevşek tutuluyor: amacı bütçeyi doğrulamak değil, katastrofik
// regresyonu yakalamak (ADR 0003). Ölçülen sayılar her koşuda log'a yazılıyor; cihaz
// ölçümü PR şablonundaki "cihazda denendi" satırıyla raporlanıyor.
struct PerformanceBudget {
    let name: String
    let iterations: Int
    /// CI'da tek bir işlemin aşmaması gereken süre.
    let ceiling: Duration

    func measure(_ body: () throws -> Void) throws {
        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        let clock = ContinuousClock()

        for _ in 0..<iterations {
            let elapsed = try clock.measure { try body() }
            durations.append(elapsed)
        }

        durations.sort()
        let median = durations[durations.count / 2]
        let worst = durations[durations.count - 1]
        let total = durations.reduce(Duration.zero, +)

        print("""
        [perf] \(name): \(iterations) işlem · \
        ortanca \(median.milliseconds) ms · en kötü \(worst.milliseconds) ms · \
        toplam \(total.milliseconds) ms · CI eşiği \(ceiling.milliseconds) ms
        """)

        #expect(
            worst <= ceiling,
            "\(name) en kötü durumda \(worst.milliseconds) ms, CI eşiği \(ceiling.milliseconds) ms"
        )
    }
}

extension Duration {
    /// Milisaniye, iki ondalık hane. Foundation'a bağımlı kalmamak için elle biçimlendiriliyor.
    var milliseconds: String {
        let hundredths = components.seconds * 100_000
            + components.attoseconds / 10_000_000_000_000
        return "\(hundredths / 100).\(String(format2: hundredths % 100))"
    }
}

private extension String {
    init(format2 value: Int64) {
        let absolute = value < 0 ? -value : value
        self = absolute < 10 ? "0\(absolute)" : "\(absolute)"
    }
}
