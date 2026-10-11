import Foundation

/// The web pages the app points to. All of them open without a GitHub sign-in.
enum AppLinks {
    /// The public source code.
    static let repository = URL(string: "https://github.com/yadaniyil/open-dictation")!
    /// Where people report a problem.
    static let issues = URL(string: "https://github.com/yadaniyil/open-dictation/issues")!
    /// The privacy policy, kept next to the source.
    static let privacyPolicy = URL(string: "https://github.com/yadaniyil/open-dictation/blob/main/PRIVACY.md")!
    /// The ready-made "Open Dictation" shortcut: Toggle Dictation, then Copy to Clipboard when there
    /// is text. The Shortcuts app opens the link and offers to add it. While this is nil, or when
    /// the link cannot be opened, the app shows how to make the shortcut by hand.
    static let dictateShortcut: URL? = URL(string: "https://www.icloud.com/shortcuts/9a8c5f365de04ccea4acb38ad90d3e20")
}
