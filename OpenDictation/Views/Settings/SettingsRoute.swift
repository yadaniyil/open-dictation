import Foundation

/// The screens Settings can push. Values, so a screen can also be opened from outside,
/// such as the main screen's "add your key" hint.
enum SettingsRoute: Hashable {
    case provider(SpeechModel)
    case style
    case vocabulary
    case setupGuide
    case stats
    case advanced
    case about
    case acknowledgements
}
