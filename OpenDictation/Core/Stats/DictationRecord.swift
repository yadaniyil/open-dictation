import Foundation

/// One finished dictation, as numbers only: none of its words and none of its sound.
/// It feeds the "Your stats" screen and never leaves the phone.
struct DictationRecord: Codable, Equatable, Sendable {
    var date: Date
    /// What did the listening.
    var provider: SpeechModel
    /// How long the recording was.
    var audioSeconds: Double
    /// How long the speech step took: the upload and the answer, or the model on the phone.
    var speechSeconds: Double
    /// How long the text step (styles and spoken instructions) took. Nil when it did not run.
    var textSeconds: Double?
    /// Words in the text that was copied.
    var words: Int
    /// What OpenAI counted for the text step, when it said.
    var inputTokens: Int?
    var outputTokens: Int?

    /// Counts words the way the system's text tools do, so "don't" is one word and a language
    /// written without spaces still gets a fair count.
    static func words(in text: String) -> Int {
        var count = 0
        text.enumerateSubstrings(in: text.startIndex..., options: [.byWords, .substringNotRequired]) { _, _, _, _ in
            count += 1
        }
        return count
    }
}

/// The log writes a provider as its raw value, as a plain word in the file. Renaming a case
/// would make an older log unreadable.
extension SpeechModel: Codable, CodingKeyRepresentable {}
