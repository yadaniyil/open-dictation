import AVFoundation

/// Times one dictation while it is turned into text, and writes its line for the log.
struct DictationStopwatch {
    let provider: SpeechModel
    /// What OpenAI counted for the text step, when it said.
    var usage: TokenUsage?
    /// What the speech step cost, going by what the provider itself reported. Nil when it
    /// reported nothing, and for a model on the phone.
    var speechDollars: Double?

    private let clock = ContinuousClock()
    private var lapStart: ContinuousClock.Instant
    private var speechSeconds = 0.0
    private var textSeconds: Double?

    /// Starts the clock on the speech step.
    init(provider: SpeechModel) {
        self.provider = provider
        lapStart = clock.now
    }

    /// The speech step is over. Whatever comes next is the text step.
    mutating func speechEnded() {
        speechSeconds = lap()
    }

    /// The text step is over, whether it worked or not: the user waited for it either way.
    mutating func textEnded() {
        textSeconds = lap()
    }

    /// The dictation's line for the log. Call it while the recording is still in its place.
    /// Nil when the recording's length cannot be read, because every other number leans on it.
    func record(text: String, recording: URL, date: Date = Date()) -> DictationRecord? {
        guard let audioSeconds = Self.seconds(ofAudioAt: recording) else { return nil }
        return DictationRecord(
            date: date, provider: provider,
            audioSeconds: Self.rounded(audioSeconds), speechSeconds: Self.rounded(speechSeconds),
            textSeconds: textSeconds.map(Self.rounded), words: DictationRecord.words(in: text),
            inputTokens: usage?.input, outputTokens: usage?.output, speechDollars: speechDollars)
    }

    /// How long a sound file plays, or nil when it cannot be opened.
    static func seconds(ofAudioAt url: URL) -> Double? {
        guard let file = try? AVAudioFile(forReading: url), file.fileFormat.sampleRate > 0 else { return nil }
        return Double(file.length) / file.fileFormat.sampleRate
    }

    private mutating func lap() -> Double {
        let now = clock.now
        defer { lapStart = now }
        return (now - lapStart) / .seconds(1)
    }

    /// Hundredths of a second are plenty, and keep the file short.
    private static func rounded(_ seconds: Double) -> Double {
        (seconds * 100).rounded() / 100
    }
}
