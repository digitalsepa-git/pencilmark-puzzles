/// Paywall'ın ne zaman gösterilebileceği (brief b.8).
///
/// Kural tek cümle ve bağlayıcı: "Paywall, kullanıcı en az 3 bulmaca bitirmeden
/// gösterilmez. Erken paywall bu kategoride silinme sebebi." Bu yüzden kural bir
/// arayüz ayrıntısı değil, saf ve sınanabilir bir değer olarak burada duruyor —
/// ekranın koşullarına gömülseydi ikinci bir giriş yolu eklendiğinde sessizce
/// delinirdi.
///
/// Sayılan şey **bitmiş** bulmaca: başlatılan değil, çözülen. Kota "başlatma" üzerinden
/// sayılıyor (ADR 0007) ama buradaki eşiğin amacı farklı — oyuncunun uygulamayı
/// gerçekten kullanıp kullanmadığını ölçüyor.
public enum PaywallPolicy {
    /// Eşik. Brief b.8'den; değiştirilecekse orası da değişmeli.
    public static let minimumSolvedPuzzles = 3

    public static func canShow(solvedPuzzles: Int) -> Bool {
        solvedPuzzles >= minimumSolvedPuzzles
    }

    /// Eşiğe kalan bulmaca sayısı; sıfırsa paywall gösterilebilir.
    public static func remainingBeforeShowing(solvedPuzzles: Int) -> Int {
        max(minimumSolvedPuzzles - solvedPuzzles, 0)
    }
}
