import Observation
import UIKit

/// Knows which speech models are set up (key saved, or model on the phone) and which one
/// dictations use. Downloads and deletes the on-device ones.
@MainActor
@Observable
final class SpeechModelStore {
    static let shared = SpeechModelStore()

    enum Status: Equatable {
        /// No key saved yet, or the model is not on the phone.
        case notSetUp
        case downloading(progress: Double)
        case ready
        case failed(String)
    }

    private(set) var statuses: [SpeechModel: Status]
    /// The model dictations use. Only a ready one can be picked.
    private(set) var selected: SpeechModel
    /// The model that was in use until it stopped being ready and OpenAI took over.
    /// Kept so the screens can say what happened.
    private(set) var fellBackFrom: SpeechModel?

    private let engines: [SpeechModel: any LocalSpeechEngine]
    private let hasKey: (SpeechModel) -> Bool
    private let save: (SpeechModel) -> Void
    private var downloads: [SpeechModel: Task<Void, Never>] = [:]

    /// - Parameters:
    ///   - engines: one per on-device model. Tests pass fakes.
    ///   - hasKey: whether a cloud model's key is saved.
    ///   - save: remembers the choice for the next launch.
    init(
        engines: [SpeechModel: any LocalSpeechEngine] = SpeechModel.allCases.reduce(into: [:]) { $0[$1] = $1.makeEngine() },
        selected: SpeechModel = AppSettings.speechModel,
        hasKey: @escaping (SpeechModel) -> Bool = { $0.savedKey != nil },
        save: @escaping (SpeechModel) -> Void = { AppSettings.speechModel = $0 }
    ) {
        self.engines = engines
        self.hasKey = hasKey
        self.save = save
        self.selected = selected
        statuses = SpeechModel.allCases.reduce(into: [:]) { statuses, model in
            let isReady = engines[model]?.isDownloaded ?? hasKey(model)
            statuses[model] = isReady ? .ready : .notSetUp
        }
        // The choice comes back with an iCloud restore, but the model files do not.
        fallBackIfNeeded()
    }

    func status(of model: SpeechModel) -> Status {
        statuses[model] ?? .notSetUp
    }

    /// False when the model in use still needs its key.
    var canListen: Bool {
        status(of: selected) == .ready
    }

    /// The engine to dictate with, or nil when a cloud model does the listening.
    var engine: (any LocalSpeechEngine)? {
        canListen ? engines[selected] : nil
    }

    func select(_ model: SpeechModel) {
        guard status(of: model) == .ready else { return }
        selected = model
        fellBackFrom = nil
        save(model)
    }

    /// Call after a key was saved or removed: the Keychain does not announce changes.
    func keysChanged() {
        for model in SpeechModel.allCases where !model.isOnDevice {
            statuses[model] = hasKey(model) ? .ready : .notSetUp
        }
        fallBackIfNeeded()
    }

    /// Starts the download and returns its task, so a test can wait for the end.
    @discardableResult
    func download(_ model: SpeechModel) -> Task<Void, Never>? {
        guard let engine = engines[model], downloads[model] == nil, status(of: model) != .ready else { return nil }
        statuses[model] = .downloading(progress: 0)
        SpeechModel.keepModelsOutOfBackup()
        let task = Task {
            do {
                try await engine.download { fraction in
                    Task { @MainActor in self.report(fraction, for: model) }
                }
                statuses[model] = .ready
                // Nothing could listen yet (no key, no other model), so the new model takes over
                // and a first download needs no second tap. Otherwise the user's choice stands.
                if !canListen { select(model) }
            } catch {
                if Task.isCancelled {
                    // A cancelled download leaves nothing behind. A failed one keeps what it has,
                    // so that trying again carries on from there.
                    try? engine.delete()
                    statuses[model] = .notSetUp
                } else {
                    statuses[model] = .failed(error.localizedDescription)
                }
            }
            downloads[model] = nil
            keepScreenOn()
        }
        downloads[model] = task
        keepScreenOn()
        return task
    }

    func cancelDownload(_ model: SpeechModel) {
        downloads[model]?.cancel()
    }

    func delete(_ model: SpeechModel) {
        guard let engine = engines[model], downloads[model] == nil else { return }
        try? engine.delete()
        statuses[model] = engine.isDownloaded ? .ready : .notSetUp
        fallBackIfNeeded()
    }

    /// OpenAI is the one that stays in use without being ready: the main screen then asks for its key.
    private func fallBackIfNeeded() {
        guard selected != .openAI, !canListen else { return }
        fellBackFrom = selected
        selected = .openAI
        save(.openAI)
    }

    /// Progress arrives from other threads and can land late, after the download has ended.
    private func report(_ fraction: Double, for model: SpeechModel) {
        guard case .downloading(let shown) = status(of: model), fraction > shown else { return }
        statuses[model] = .downloading(progress: min(fraction, 1))
    }

    /// A locked phone suspends the app within seconds and the download dies with it.
    private func keepScreenOn() {
        UIApplication.shared.isIdleTimerDisabled = !downloads.isEmpty
    }
}
