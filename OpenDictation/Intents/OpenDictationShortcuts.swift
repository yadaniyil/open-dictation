import AppIntents

/// Makes "Toggle Dictation" show up for the Action Button, Shortcuts, Spotlight and Siri
/// without the user having to build a shortcut first.
struct OpenDictationShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleDictationIntent(),
            phrases: [
                "Toggle \(.applicationName)",
                "Start \(.applicationName)",
                "Stop \(.applicationName)",
            ],
            shortTitle: "Toggle Dictation",
            systemImageName: "mic.fill")
    }
}
