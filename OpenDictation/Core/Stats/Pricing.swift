import Foundation

/// What dictations cost, for the "Your stats" screen. The app bills nothing: the user pays each
/// provider directly. Where a provider says what a dictation cost, that is what counts:
/// ElevenLabs names the sum, OpenAI names the seconds it billed. Everything else goes by the
/// list prices below, in US dollars.
///
/// All checked on 2026-10-11. Check them again when a default model changes, and move
/// `checked` along. A model id the user typed in by hand is priced like the default one.
enum Pricing {
    /// When the prices below were read, as the screen says it.
    static let checked = "October 2026"

    /// OpenAI `gpt-transcribe`: $0.0045 per minute of audio.
    /// https://developers.openai.com/api/docs/pricing
    static let openAISpeechPerMinute = 0.0045

    /// ElevenLabs Scribe v2: $0.22 per hour of audio, the same on every plan.
    /// https://elevenlabs.io/pricing/api
    static let elevenLabsSpeechPerHour = 0.22

    /// OpenAI `gpt-6-luna`, which does the text step: $0.10 per million input tokens and $0.50
    /// per million output tokens on the standard tier. Cached input costs less, so counting it
    /// all at the full price can only come out a little high.
    /// https://developers.openai.com/api/docs/pricing
    static let openAITextPerMillionInputTokens = 0.10
    static let openAITextPerMillionOutputTokens = 0.50

    /// An estimate in US dollars, split by who sends the bill.
    struct Cost: Equatable, Sendable {
        /// The speech step when OpenAI listened, and the text step whoever listened.
        var openAI = 0.0
        var elevenLabs = 0.0

        var total: Double { openAI + elevenLabs }
        /// True when both send a bill, so that the split is worth showing.
        var isSplit: Bool { openAI > 0 && elevenLabs > 0 }
    }

    /// What this much speech costs at a provider's list price. The on-device models cost nothing.
    static func speechCost(of provider: SpeechModel, seconds: Double) -> Double {
        switch provider {
        case .openAI: seconds / 60 * openAISpeechPerMinute
        case .elevenLabs: seconds / 3600 * elevenLabsSpeechPerHour
        case .parakeetV3, .whisperLargeTurbo: 0
        }
    }

    /// What these dictations cost: what the providers reported, and the list price for the rest.
    static func cost(of totals: [SpeechModel: DictationTotals]) -> Cost {
        var cost = Cost()
        for (provider, sum) in totals {
            let unreported = max(0, sum.audioSeconds - sum.costedAudioSeconds)
            let speech = sum.speechDollars + speechCost(of: provider, seconds: unreported)
            switch provider {
            case .openAI: cost.openAI += speech
            case .elevenLabs: cost.elevenLabs += speech
            case .parakeetV3, .whisperLargeTurbo: break
            }
            // The text step is OpenAI's whichever provider did the listening.
            cost.openAI += Double(sum.inputTokens) / 1_000_000 * openAITextPerMillionInputTokens
                + Double(sum.outputTokens) / 1_000_000 * openAITextPerMillionOutputTokens
        }
        return cost
    }
}
