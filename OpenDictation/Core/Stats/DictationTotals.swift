import Foundation

/// Dictations added up: one provider's, one month's, or all of them.
struct DictationTotals: Encodable, Equatable, Sendable {
    var dictations = 0
    var words = 0
    var audioSeconds = 0.0
    var speechSeconds = 0.0
    /// How many of the dictations went through the text step, and how long that took in all.
    var textSteps = 0
    var textSeconds = 0.0
    var inputTokens = 0
    var outputTokens = 0
    /// The speech cost the providers themselves reported, in US dollars, and how much speech
    /// that covers. The rest of `audioSeconds` is priced by its length.
    var speechDollars = 0.0
    var costedAudioSeconds = 0.0

    /// What an average person types on a phone: 36 words a minute, measured on 37,000 people
    /// (Palin and others, "How do People Type on Mobile Devices?", MobileHCI 2019).
    static let typingWordsPerMinute = 36.0

    /// How much longer typing the same words would have taken than saying them and waiting
    /// for the text. Never less than nothing.
    var secondsSaved: Double {
        let typing = Double(words) / Self.typingWordsPerMinute * 60
        return max(0, typing - audioSeconds - speechSeconds - textSeconds)
    }

    mutating func add(_ record: DictationRecord) {
        dictations += 1
        words += record.words
        audioSeconds += record.audioSeconds
        speechSeconds += record.speechSeconds
        if let seconds = record.textSeconds {
            textSteps += 1
            textSeconds += seconds
        }
        inputTokens += record.inputTokens ?? 0
        outputTokens += record.outputTokens ?? 0
        if let dollars = record.speechDollars {
            speechDollars += dollars
            costedAudioSeconds += record.audioSeconds
        }
    }

    static func += (sum: inout DictationTotals, more: DictationTotals) {
        sum.dictations += more.dictations
        sum.words += more.words
        sum.audioSeconds += more.audioSeconds
        sum.speechSeconds += more.speechSeconds
        sum.textSteps += more.textSteps
        sum.textSeconds += more.textSeconds
        sum.inputTokens += more.inputTokens
        sum.outputTokens += more.outputTokens
        sum.speechDollars += more.speechDollars
        sum.costedAudioSeconds += more.costedAudioSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case dictations, words, audioSeconds, speechSeconds, textSteps, textSeconds
        case inputTokens, outputTokens, speechDollars, costedAudioSeconds
    }
}

extension DictationTotals: Decodable {
    /// The two cost sums came later. A log written before them still has to open.
    init(from decoder: any Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            dictations: try fields.decode(Int.self, forKey: .dictations),
            words: try fields.decode(Int.self, forKey: .words),
            audioSeconds: try fields.decode(Double.self, forKey: .audioSeconds),
            speechSeconds: try fields.decode(Double.self, forKey: .speechSeconds),
            textSteps: try fields.decode(Int.self, forKey: .textSteps),
            textSeconds: try fields.decode(Double.self, forKey: .textSeconds),
            inputTokens: try fields.decode(Int.self, forKey: .inputTokens),
            outputTokens: try fields.decode(Int.self, forKey: .outputTokens),
            speechDollars: try fields.decodeIfPresent(Double.self, forKey: .speechDollars) ?? 0,
            costedAudioSeconds: try fields.decodeIfPresent(Double.self, forKey: .costedAudioSeconds) ?? 0)
    }
}
