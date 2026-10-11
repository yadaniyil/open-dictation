import Foundation

/// Whether the shortcut is set up. The main screen shows its steps until then.
enum SetupProgress {
    /// The UserDefaults key, shared with the main screen's `@AppStorage`.
    static let doneKey = "setup.done"

    /// Called when the shortcut starts a dictation: proof that it exists and works.
    static func markDone() {
        UserDefaults.standard.set(true, forKey: doneKey)
    }
}
