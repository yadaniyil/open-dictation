#if DEBUG
import Foundation

/// A made-up on-device model that takes a while to prepare, for looking at the "Preparing"
/// screens without a real model. The Simulator has no Neural Engine, so the real wait cannot be
/// seen there. A development tool, not in release builds: launch with `-samplePreparing 20` for
/// twenty seconds, or `-samplePreparing` alone for six.
@MainActor
enum SamplePreparation {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-samplePreparing")
    }

    /// A store whose model in use looks downloaded and has never been prepared. It remembers
    /// nothing and touches no real model, key or setting.
    static func makeStore() -> SpeechModelStore {
        // `-samplePreparing 20` on the command line is also a default named "samplePreparing".
        let asked = UserDefaults.standard.double(forKey: "samplePreparing")
        let engine = OneAtATime(SampleEngine(seconds: asked > 0 ? asked : 6))
        let suite = "samplePreparing"
        UserDefaults.standard.removePersistentDomain(forName: suite)
        return SpeechModelStore(
            engines: [.parakeetV3: engine],
            selected: .parakeetV3,
            hasKey: { _ in false },
            save: { _ in },
            prepared: PreparedModels(defaults: UserDefaults(suiteName: suite) ?? .standard, stamp: "sample"))
    }
}

/// Looks downloaded, takes `seconds` to prepare and answers every recording with the same words.
private struct SampleEngine: LocalSpeechEngine {
    let seconds: Double

    init(seconds: Double) {
        self.seconds = seconds
    }

    init(folder: URL) {
        seconds = 6
    }

    var isDownloaded: Bool { true }

    func download(progress: @escaping @Sendable (Double) -> Void) async throws {}

    func delete() throws {}

    func prepare() async throws {
        try await Task.sleep(for: .seconds(seconds))
    }

    func transcribe(fileURL: URL, languageCode: String) async throws -> String {
        "A sample dictation."
    }
}
#endif
