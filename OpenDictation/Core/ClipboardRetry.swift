import Foundation

/// A text put on the clipboard while the app was not in front, which iOS may have ignored.
/// It is copied once more when the app comes to the front, but only while it is fresh and
/// nothing was copied since: an old result must not replace something the user copied after it.
struct ClipboardRetry: Equatable, Sendable {
    let text: String
    let date: Date
    /// The clipboard's change count just after the text was written. Any copy since, by the
    /// user or by the shortcut, moves it on.
    let changeCount: Int

    /// How long a result stays fresh enough to copy again.
    static let freshFor: TimeInterval = 120

    func shouldCopyAgain(now: Date, changeCount current: Int) -> Bool {
        current == changeCount && now.timeIntervalSince(date) < Self.freshFor
    }
}
