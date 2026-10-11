import Foundation

/// Dictations added up: one provider's, one month's, or all of them.
struct DictationTotals: Codable, Equatable, Sendable {
    var dictations = 0
    var words = 0
    var audioSeconds = 0.0
    var speechSeconds = 0.0
    /// How many of the dictations went through the text step, and how long that took in all.
    var textSteps = 0
    var textSeconds = 0.0
    var inputTokens = 0
    var outputTokens = 0

    /// What an average person types on a phone: 36 words a minute, measured on 37,000 people
    /// (Palin and others, "How do People Type on Mobile Devices?", MobileHCI 2019).
    static let typingWordsPerMinute = 36.0

    /// How much longer typing the same words would have taken than saying them and waiting
    /// for the text. Never less than nothing.
    var secondsSaved: Double {
        let typing = Double(words) / Self.typingWordsPerMinute * 60
        return max(0, typing - audioSeconds - speechSeconds - textSeconds)
    }

    /// How long the text step takes on average, or nil when it never ran.
    var secondsPerTextStep: Double? {
        textSteps > 0 ? textSeconds / Double(textSteps) : nil
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
    }
}
