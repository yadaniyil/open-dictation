import Foundation

/// The languages offered in Settings. An empty code means the speech model works it out.
enum DictationLanguage {
    static let all: [(code: String, name: String)] = [
        ("", "Detect automatically"),
        ("en", "English"),
        ("uk", "Ukrainian"),
        ("pl", "Polish"),
        ("de", "German"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("nl", "Dutch"),
        ("tr", "Turkish"),
        ("ru", "Russian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("zh", "Chinese"),
        ("hi", "Hindi"),
        ("ar", "Arabic"),
    ]
}
