import Foundation

/// One set-up guide, as data. `TutorialView` draws every guide the same way.
///
/// iOS only lets text reach the clipboard from a shortcut while another app is in front, so
/// setting up is two things: get the "Open Dictation" shortcut, then choose where to run it from.
/// The wording follows iOS 27. Check it against the iPhone's own screens before changing it.
struct Tutorial: Identifiable, Sendable {
    /// A short name, used to tell the guides apart in code and in UI tests.
    let id: String
    let title: LocalizedStringResource
    /// The small picture beside its name in Settings. Only the places to run it from have one.
    var glyph: TutorialGlyph?
    let steps: [TutorialStep]
    /// How a dictation goes once this is set up, in a few words.
    var result: LocalizedStringResource?

    /// The shortcut's name, as the Shortcuts app shows it. The ready-made one carries it and the
    /// by-hand guide ends by giving it, so every guide can ask for it by name.
    static let shortcutName = "Open Dictation"

    /// The places a dictation can be started from, best first. An iPhone without an
    /// Action Button is not offered one, so there Control Center leads.
    static func triggers(hasActionButton: Bool) -> [Tutorial] {
        (hasActionButton ? [actionButton] : []) + [controlCenter, lockScreen, backTap]
    }

    /// The one way the main screen walks through: the Action Button where there is one,
    /// Control Center everywhere else.
    static func best(hasActionButton: Bool) -> Tutorial {
        hasActionButton ? actionButton : controlCenter
    }

    static let actionButton = Tutorial(
        id: "actionButton",
        title: "Action Button",
        glyph: .actionButton,
        steps: [
            .getShortcut,
            TutorialStep(
                picture: .list(highlighted: 1),
                pictureDescription: "The Settings list. The Action Button row has a frame around it.",
                text: "Open the Settings app. Tap Action Button.",
                screenshot: .settingsActionButtonRow),
            TutorialStep(
                picture: .actionPicker,
                pictureDescription: "The Action Button screen showing Shortcut. The Choose a Shortcut button has a frame around it.",
                text: "Swipe to Shortcut. Tap Choose a Shortcut, then Open Dictation.",
                screenshot: .actionButtonShortcutChoice),
        ],
        result: "Hold. Talk. Hold again. Paste.")

    static let controlCenter = Tutorial(
        id: "controlCenter",
        title: "Control Center",
        glyph: .controlCenter,
        steps: [
            .getShortcut,
            TutorialStep(
                picture: .controlCenterAdd,
                pictureDescription: "Control Center with the plus button at its top left highlighted",
                text: "Open Control Center. Tap\u{00A0}+."),
            TutorialStep(
                picture: .shortcutControl,
                pictureDescription: "The list of controls with Run Shortcut highlighted",
                text: "Tap Add a Control, then Run Shortcut."),
            .chooseShortcut,
        ],
        result: "Tap. Talk. Tap again. Paste.")

    static let lockScreen = Tutorial(
        id: "lockScreen",
        title: "Lock Screen",
        glyph: .lockScreen,
        steps: [
            .getShortcut,
            TutorialStep(
                picture: .lockScreenCustomize,
                pictureDescription: "The Lock Screen with the Customize button under it",
                text: "Hold the Lock Screen. Tap Customize."),
            TutorialStep(
                picture: .lockScreenSwap,
                pictureDescription: "The two buttons at the bottom of the Lock Screen: one with a minus, one with a plus",
                text: "Tap\u{00A0}− on a bottom button, then\u{00A0}+."),
            TutorialStep(
                picture: .myShortcuts,
                pictureDescription: "My Shortcuts with the Open Dictation shortcut highlighted",
                text: "Tap Run Shortcut. Choose Open Dictation, under My Shortcuts."),
        ],
        result: "Hold it. Talk. Hold it again. Paste.")

    static let backTap = Tutorial(
        id: "backTap",
        title: "Back Tap",
        glyph: .backTap,
        steps: [
            .getShortcut,
            TutorialStep(
                picture: .list(highlighted: 1),
                pictureDescription: "The Settings list with one row highlighted",
                text: "Settings, Accessibility, then Touch."),
            TutorialStep(
                picture: .backTap,
                pictureDescription: "The back of an iPhone being tapped twice",
                text: "Back Tap, then Double Tap."),
            TutorialStep(
                picture: .list(highlighted: 2),
                pictureDescription: "A list with its last row highlighted",
                text: "Scroll down to Shortcuts. Pick Open Dictation."),
        ],
        result: "Double tap. Talk. Double tap. Paste.")

    /// The fallback for when the ready-made shortcut cannot be opened. It ends with the same
    /// name, so the other guides read the same whichever way the shortcut was made.
    static let makeShortcut = Tutorial(
        id: "makeShortcut",
        title: "Make the shortcut",
        steps: [
            TutorialStep(
                picture: .newShortcut,
                pictureDescription: "A shortcut with a plus on its corner",
                text: "Open Shortcuts. Tap\u{00A0}+. If it asks you to describe a shortcut, tap Edit."),
            TutorialStep(
                picture: .toggleAction,
                pictureDescription: "The Toggle Dictation action",
                text: "Search for Toggle Dictation. Tap it."),
            TutorialStep(
                picture: .ifAction,
                pictureDescription: "The If action under Toggle Dictation",
                text: "Search for If. Tap it. Then tap “is” and choose “has any value”."),
            TutorialStep(
                picture: .copyInsideIf,
                pictureDescription: "The Copy to Clipboard action moved up into the If",
                text: "Search for Copy to Clipboard. Tap it, then drag it up, to just under If."),
            TutorialStep(
                picture: .rename,
                pictureDescription: "The shortcut's name being changed",
                text: "Tap the name at the top, then Rename. Type Open Dictation."),
        ])
}

/// Two guides are the same guide when their names match: that is all a link needs to know.
extension Tutorial: Hashable {
    static func == (lhs: Tutorial, rhs: Tutorial) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// One step of a guide: a picture and a few words, or the button that gets the shortcut.
struct TutorialStep: Sendable {
    let picture: TutorialPicture
    /// What VoiceOver says for the picture.
    let pictureDescription: LocalizedStringResource
    /// What to do.
    var text: LocalizedStringResource?
    /// A real iOS screen to show instead of the drawing, where there is one.
    var screenshot: TutorialScreenshot?
    /// The small button beside the words, for a step the app can start for the user.
    var action: TutorialStepAction?

    /// The first step of every guide that needs the shortcut: a line of words and a button.
    static let getShortcut = TutorialStep(
        picture: .shortcut,
        pictureDescription: "A shortcut",
        text: "Get the shortcut",
        action: .getShortcut)

    /// The picker lists the user's own shortcuts first and apps under them. The app's own row
    /// there starts a dictation that cannot be pasted, so the words point at "My Shortcuts".
    static let chooseShortcut = TutorialStep(
        picture: .myShortcuts,
        pictureDescription: "My Shortcuts with the Open Dictation shortcut highlighted",
        text: "Choose Open Dictation, under My Shortcuts.")
}

/// A real iOS screen, cropped to the part a step is about. The pictures were taken on iOS 27
/// in light and dark mode: take them again when iOS changes these screens.
struct TutorialScreenshot: Sendable {
    /// The image's name in the asset catalogue.
    let asset: String
    /// Width divided by height.
    let aspect: CGFloat
    /// What to tap, in fractions of the picture's width and height.
    let target: CGRect
    /// How round the frame's corners are, as a fraction of its height.
    var targetRoundness: CGFloat = 0.3

    /// Two rows of the Settings list: Accessibility, Action Button.
    static let settingsActionButtonRow = TutorialScreenshot(
        asset: "SettingsActionButtonRow",
        aspect: 1158.0 / 308.0,
        target: CGRect(x: 0.03, y: 0.52, width: 0.94, height: 0.455))

    /// Settings > Action Button on "Shortcut": its name, and the button under it.
    static let actionButtonShortcutChoice = TutorialScreenshot(
        asset: "ActionButtonShortcutChoice",
        aspect: 1206.0 / 430.0,
        target: CGRect(x: 0.225, y: 0.585, width: 0.55, height: 0.36),
        targetRoundness: 0.5)
}

/// What the small button of a step does.
enum TutorialStepAction: Sendable {
    /// Opens the ready-made shortcut in the Shortcuts app.
    case getShortcut
    // There is no "open Settings" here on purpose. iOS only lets an app open its own page in
    // Settings, two levels away from the main list, which sent users to the wrong place.
}

/// The small pictures of the places a dictation can be started from. `TutorialGlyphView` draws them.
enum TutorialGlyph: Sendable {
    case actionButton
    case controlCenter
    case lockScreen
    case backTap
}

/// The drawings a step can show. `TutorialPictureView` draws them.
enum TutorialPicture: Sendable {
    /// A shortcut's tile.
    case shortcut
    /// A plain list of three rows, one of them highlighted (0 is the top one).
    case list(highlighted: Int)
    /// The Action Button screen in Settings: one choice in the middle, dots under it.
    case actionPicker
    /// The shortcut picker: two tiles under "My Shortcuts", the first one highlighted.
    case myShortcuts
    /// Control Center with the + at its top left.
    case controlCenterAdd
    /// A few controls, with Run Shortcut highlighted.
    case shortcutControl
    /// The Lock Screen with "Customize" under it.
    case lockScreenCustomize
    /// The two round buttons at the bottom of the Lock Screen, one being swapped.
    case lockScreenSwap
    /// The back of an iPhone with a double tap on it.
    case backTap
    // The five pictures of making the shortcut by hand.
    case newShortcut
    case toggleAction
    case ifAction
    case copyInsideIf
    case rename
}
