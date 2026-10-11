import AppIntents

/// The one action behind the Action Button, the Shortcuts app and the Live Activity's Done button.
/// The first run starts listening and hands back nothing; the next run stops and hands back the text,
/// which a Shortcut can pass to "Copy to Clipboard".
///
/// `AudioRecordingIntent` lets the microphone start while another app is in front, and
/// `LiveActivityIntent` lets the Live Activity start from there too. iOS needs both.
///
/// The type lives in `Shared` because the Live Activity's button needs it, but it always runs
/// inside the app, never inside the widget extension.
struct ToggleDictationIntent: AudioRecordingIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "Toggle Dictation"
    static let description = IntentDescription(
        "Starts listening. Run it again to stop and get the text of what you said.")

    /// Runs without opening the app, but may bring the app forward when it has to
    /// (first-time microphone permission, missing key, or iOS refusing the microphone in the background).
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { .main }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String?> {
        #if APP_TARGET
        let controller = DictationController.shared
        // Only a failed start is worth coming to the front for. A failed stop (no network, or an
        // on-device model that gave up) must not end in a fresh recording.
        let wasStarting = controller.phase == .idle
        do {
            switch try await controller.toggleFromIntent() {
            case .started: return .result(value: nil)
            case .finished(let text): return .result(value: text)
            }
        } catch {
            guard wasStarting, controller.phase == .idle, Self.foregroundCanHelp(error),
                  systemContext.currentMode.canContinueInForeground
            else { throw error }

            try await continueInForeground(alwaysConfirm: false)
            // With a missing key the app's own screen now shows what to do.
            switch error {
            case OpenAIError.missingKey, ElevenLabsError.missingKey: return .result(value: nil)
            default: break
            }
            try await controller.startAfterComingToFront()
            return .result(value: nil)
        }
        #else
        return .result(value: nil)
        #endif
    }

    #if APP_TARGET
    /// Only problems from before the microphone started that having the app in front can sort out.
    private static func foregroundCanHelp(_ error: any Error) -> Bool {
        switch error {
        case DictationController.DictationError.needsMicrophonePermission: true
        case is DictationController.DictationError: false
        case OpenAIError.missingKey, ElevenLabsError.missingKey: true
        case is OpenAIError, is ElevenLabsError: false
        // Anything else is the audio system refusing to start in the background.
        default: true
        }
    }
    #endif
}
