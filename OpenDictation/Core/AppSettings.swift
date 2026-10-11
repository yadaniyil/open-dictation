import Foundation

/// User choices, kept in UserDefaults. The API keys are not here: they live in the Keychain.
enum AppSettings {
    /// OpenAI's recommended model for recorded speech.
    static let defaultModel = "gpt-transcribe"
    /// Shown in Settings. Any other model id can be typed in by hand.
    static let suggestedModels = ["gpt-transcribe", "gpt-4o-mini-transcribe", "gpt-4o-transcribe"]

    static let defaultMaxMinutes = 10

    /// The small text model that writes the transcript in the chosen style and follows spoken instructions.
    static let defaultRewriteModel = "gpt-6-luna"

    private enum Key {
        static let model = "model"
        static let languageCode = "languageCode"
        static let vocabulary = "vocabulary"
        static let maxMinutes = "maxMinutes"
        static let style = "style"
        static let customInstructions = "customInstructions"
        static let rewriteModel = "rewriteModel"
        static let followsSpokenInstructions = "followsSpokenInstructions"
        static let keepsRecordings = "keepsRecordings"
        static let speechModel = "speechModel"
    }

    private static var defaults: UserDefaults { .standard }

    /// Which cloud or on-device model listens. `SpeechModelStore` is what reads and changes it.
    static var speechModel: SpeechModel {
        get { defaults.string(forKey: Key.speechModel).flatMap(SpeechModel.init) ?? .openAI }
        set { defaults.set(newValue.rawValue, forKey: Key.speechModel) }
    }

    /// The OpenAI model id, used while `speechModel` is `.openAI`.
    static var model: String {
        get { nonEmpty(defaults.string(forKey: Key.model)) ?? defaultModel }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    /// ISO-639-1 code such as "en" or "uk". Empty means OpenAI detects the language.
    static var languageCode: String {
        get { defaults.string(forKey: Key.languageCode) ?? "" }
        set { defaults.set(newValue, forKey: Key.languageCode) }
    }

    /// Names and jargon the model should spell right, one per line.
    static var vocabulary: String {
        get { defaults.string(forKey: Key.vocabulary) ?? "" }
        set { defaults.set(newValue, forKey: Key.vocabulary) }
    }

    /// A forgotten recording stops by itself after this long.
    static var maxMinutes: Int {
        get {
            let value = defaults.integer(forKey: Key.maxMinutes)
            return value > 0 ? value : defaultMaxMinutes
        }
        set { defaults.set(newValue, forKey: Key.maxMinutes) }
    }

    static var style: WritingStyle {
        get { defaults.string(forKey: Key.style).flatMap(WritingStyle.init) ?? .asSpoken }
        set { defaults.set(newValue.rawValue, forKey: Key.style) }
    }

    /// The user's own wording for the Custom style.
    static var customInstructions: String {
        get { defaults.string(forKey: Key.customInstructions) ?? "" }
        set { defaults.set(newValue, forKey: Key.customInstructions) }
    }

    /// When on, "give me this in Polish" at the start or end of a dictation is carried out.
    /// It means the text step also runs for "As spoken", which costs about two seconds.
    static var followsSpokenInstructions: Bool {
        get { defaults.object(forKey: Key.followsSpokenInstructions) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.followsSpokenInstructions) }
    }

    /// A testing aid, off by default: see `RecordingArchive`.
    static var keepsRecordings: Bool {
        get { defaults.bool(forKey: Key.keepsRecordings) }
        set { defaults.set(newValue, forKey: Key.keepsRecordings) }
    }

    static var rewriteModel: String {
        get { nonEmpty(defaults.string(forKey: Key.rewriteModel)) ?? defaultRewriteModel }
        set { defaults.set(newValue, forKey: Key.rewriteModel) }
    }

    static var apiKey: String? {
        #if DEBUG
        if let override = debugOverride("OD_TEST_API_KEY") { return override }
        #endif
        return nonEmpty(KeychainStore.read(KeychainStore.apiKeyAccount))
    }

    static var apiBaseURL: URL {
        #if DEBUG
        // Lets a local mock server stand in for OpenAI while testing in the Simulator.
        if let override = debugOverride("OD_API_BASE_URL"), let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://api.openai.com/v1")!
    }

    static var elevenLabsKey: String? {
        #if DEBUG
        if let override = debugOverride("OD_TEST_ELEVENLABS_KEY") { return override }
        #endif
        return nonEmpty(KeychainStore.read(KeychainStore.elevenLabsKeyAccount))
    }

    static var elevenLabsBaseURL: URL {
        #if DEBUG
        if let override = debugOverride("OD_ELEVENLABS_BASE_URL"), let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://api.elevenlabs.io/v1")!
    }

    #if DEBUG
    /// Test values from the launch environment are remembered, because iOS starts the app
    /// without that environment when an intent wakes it. Launching with an empty value forgets it.
    /// All are saved together, once, so a forgotten key never leaves the mock address behind.
    private static let rememberDebugOverrides: Void = {
        for name in ["OD_API_BASE_URL", "OD_TEST_API_KEY", "OD_ELEVENLABS_BASE_URL", "OD_TEST_ELEVENLABS_KEY"] {
            guard let value = ProcessInfo.processInfo.environment[name] else { continue }
            UserDefaults.standard.set(nonEmpty(value), forKey: "debug.\(name)")
        }
    }()

    private static func debugOverride(_ name: String) -> String? {
        _ = rememberDebugOverrides
        return nonEmpty(defaults.string(forKey: "debug.\(name)"))
    }
    #endif

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
