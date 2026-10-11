import Foundation

/// A speech-to-text model that runs on the phone.
protocol LocalSpeechEngine: Sendable {
    /// `folder` is where this engine keeps its model files. The engine creates it when needed.
    init(folder: URL)
    /// True when every model file is on disk and ready to load.
    var isDownloaded: Bool { get }
    /// Downloads the model files and loads the model once, so a fresh download is also prepared.
    /// `progress` receives 0...1. Safe to call again after a failure.
    func download(progress: @escaping @Sendable (Double) -> Void) async throws
    /// Removes the model files from disk.
    func delete() throws
    /// Loads the model once and lets it go. The first load after the app or iOS was updated is the
    /// slow one, half a minute to a few minutes, because iOS builds the model's Neural Engine
    /// version again. Doing it here takes that wait off the next dictation.
    func prepare() async throws
    /// Loads the model, transcribes the file, then lets the model go again so the app does not
    /// sit on its memory while idle. `languageCode` is an ISO-639-1 hint, or "" to detect.
    func transcribe(fileURL: URL, languageCode: String) async throws -> String
}

enum LocalSpeechError: LocalizedError, Equatable {
    case notDownloaded
    case noSpeech
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notDownloaded: "Download the speech model in Settings first."
        case .noSpeech: "No speech was heard."
        case .failed(let message): message
        }
    }
}
