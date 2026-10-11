import Foundation

/// How the stats read on the screen: counts, lengths of time, money and speed, in plain words.
enum StatsFormat {
    /// "12,480"
    static func count(_ number: Int) -> String {
        number.formatted(.number)
    }

    /// "1 word", "12,480 words"
    static func words(_ count: Int) -> String {
        count == 1 ? "1 word" : "\(self.count(count)) words"
    }

    /// "42 sec", "12 min", "3 hr 5 min": never more exact than a reader cares about.
    static func duration(_ seconds: Double) -> String {
        if seconds < 59.5 { return "\(Int(seconds.rounded())) sec" }
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 { return "\(minutes) min" }
        return minutes % 60 == 0 ? "\(minutes / 60) hr" : "\(minutes / 60) hr \(minutes % 60) min"
    }

    // MARK: - Money

    /// "$0.42", or "$0.0045" for a price that is smaller than a cent. US dollars, written the
    /// American way, because that is how the providers bill.
    static func dollars(_ amount: Double) -> String {
        amount.formatted(
            .currency(code: "USD").precision(.fractionLength(2...4)).locale(Locale(identifier: "en_US")))
    }

    /// "About $0.42": every sum on the screen is an estimate, and says so.
    static func estimate(_ amount: Double) -> String {
        if amount <= 0 { return dollars(0) }
        if amount < 0.01 { return "Less than \(dollars(0.01))" }
        return "About \(cents(amount))"
    }

    /// "OpenAI $0.30 · ElevenLabs $0.12", or nil when only one of them sends a bill.
    static func split(_ cost: Pricing.Cost) -> String? {
        guard cost.isSplit else { return nil }
        let parts = [(SpeechModel.openAI, cost.openAI), (.elevenLabs, cost.elevenLabs)].map { provider, amount in
            "\(provider.name) \(amount < 0.01 ? "under \(dollars(0.01))" : cents(amount))"
        }
        return parts.joined(separator: " · ")
    }

    /// A sum to the cent: "$3.10".
    private static func cents(_ amount: Double) -> String {
        dollars((amount * 100).rounded() / 100)
    }

    // MARK: - Speed

    /// "9 seconds", "1 second", "2 minutes", and "under a second" for anything quicker.
    static func wait(_ seconds: Double) -> String {
        if seconds < 1 { return "under a second" }
        if seconds < 1.5 { return "1 second" }
        if seconds < 90 { return "\(Int(seconds.rounded())) seconds" }
        return "\(Int((seconds / 60).rounded())) minutes"
    }

    /// The same inside a sentence: "about 9 seconds", but plain "under a second".
    static func aboutWait(_ seconds: Double) -> String {
        seconds < 1 ? wait(seconds) : "about \(wait(seconds))"
    }

    /// A provider's speed as the value of a row: "9 seconds", or that there is none to show yet.
    static func speed(secondsPerMinute: Double?) -> String {
        guard let secondsPerMinute else { return notMeasured }
        return secondsPerMinute < 1 ? "Under a second" : wait(secondsPerMinute)
    }

    /// A provider's speed as one line on its own screen.
    static func speedSentence(secondsPerMinute: Double?) -> String {
        guard let secondsPerMinute else { return notMeasured }
        return "A minute of speech takes \(aboutWait(secondsPerMinute))"
    }

    static let notMeasured = "Not measured yet"
}
