import Foundation

/// How the spoken words are tidied before they are copied.
enum WritingStyle: String, CaseIterable, Identifiable, Sendable {
    case asSpoken
    case clean
    case casual
    case formal
    case custom

    var id: String { rawValue }

    var name: String {
        switch self {
        case .asSpoken: "As spoken"
        case .clean: "Clean"
        case .casual: "Casual"
        case .formal: "Formal"
        case .custom: "Custom"
        }
    }

    var summary: String {
        switch self {
        case .asSpoken: "Exactly what you said."
        case .clean: "Your words, without the ums and repeats."
        case .casual: "Relaxed, like a message to a friend."
        case .formal: "Polished and professional."
        case .custom: "Follows your own instructions from Settings."
        }
    }

    /// How the text step is told to write, or nil to keep the speaker's exact words.
    func instructions(custom: String) -> String? {
        switch self {
        case .asSpoken:
            nil
        case .clean:
            "Remove filler words (um, uh, like, you know), repeated words and false starts. "
                + "Fix punctuation and capitalization. Keep the speaker's own words and tone."
        case .casual:
            "Remove filler words and false starts. Make it relaxed and friendly, like a message to a friend. "
                + "Use contractions and keep it short. Do not add emoji."
        case .formal:
            "Remove filler words and false starts. Make it polished and professional, in complete sentences "
                + "with correct grammar. Keep it polite and concise."
        case .custom:
            custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : custom
        }
    }
}
