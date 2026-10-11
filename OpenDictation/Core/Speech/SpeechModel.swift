import Foundation

/// The ways to turn speech into text: two in the cloud, two on the phone.
/// A short fixed list on purpose, not a model catalogue.
enum SpeechModel: String, CaseIterable, Identifiable, Sendable {
    case openAI
    case elevenLabs
    case parakeetV3
    case whisperLargeTurbo

    var id: String { rawValue }

    var name: String {
        switch self {
        case .openAI: "OpenAI"
        case .elevenLabs: "ElevenLabs"
        case .parakeetV3: "Parakeet V3"
        case .whisperLargeTurbo: "Whisper Large Turbo"
        }
    }

    var isOnDevice: Bool {
        switch self {
        case .openAI, .elevenLabs: false
        case .parakeetV3, .whisperLargeTurbo: true
        }
    }

    /// How much there is to download, or nil for a cloud model.
    var sizeLabel: String? {
        switch self {
        case .openAI, .elevenLabs: nil
        case .parakeetV3: "494 MB"
        case .whisperLargeTurbo: "632 MB"
        }
    }

    /// Where a cloud model's key is kept in the Keychain. An on-device model needs none.
    var keychainAccount: String? {
        switch self {
        case .openAI: KeychainStore.apiKeyAccount
        case .elevenLabs: KeychainStore.elevenLabsKeyAccount
        case .parakeetV3, .whisperLargeTurbo: nil
        }
    }

    /// The key a cloud model listens with, when one is saved.
    var savedKey: String? {
        switch self {
        case .openAI: AppSettings.apiKey
        case .elevenLabs: AppSettings.elevenLabsKey
        case .parakeetV3, .whisperLargeTurbo: nil
        }
    }

    /// The engine that runs this model on the phone. A cloud model has none. Every engine made
    /// here waits its turn, so preparing a model and dictating never load two at once.
    func makeEngine() -> (any LocalSpeechEngine)? {
        switch self {
        case .openAI, .elevenLabs: nil
        case .parakeetV3: OneAtATime(ParakeetEngine(folder: folder))
        case .whisperLargeTurbo: OneAtATime(WhisperEngine(folder: folder))
        }
    }

    private var folder: URL {
        Self.modelsFolder.appendingPathComponent(rawValue)
    }

    private static var modelsFolder: URL {
        URL.applicationSupportDirectory.appendingPathComponent("Models")
    }

    /// Application Support goes into the iCloud backup, and a model is big and can be downloaded
    /// again. Marking the folder that holds them all covers every engine.
    static func keepModelsOutOfBackup() {
        var folder = modelsFolder
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? folder.setResourceValues(values)
    }
}
