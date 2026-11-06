import Observation
import os
import UIKit

/// Knows which speech models are set up (key saved, or model on the phone) and which one
/// dictations use. Downloads and deletes the on-device ones, and prepares the one in use again
/// after an update.
@MainActor
@Observable
final class SpeechModelStore {
    /// The app's own store. A DEBUG launch with `-samplePreparing` shows a made-up model being
    /// prepared instead, for screenshots.
    static let shared: SpeechModelStore = {
        #if DEBUG
        if SamplePreparation.isRequested { return SamplePreparation.makeStore() }
        #endif
        return SpeechModelStore()
    }()

    enum Status: Equatable {
        /// No key saved yet, or the model is not on the phone.
        case notSetUp
        case downloading(progress: Double)
        case ready
        /// On the phone and usable, but being loaded for the first time since an update, so a
        /// dictation has to wait for that right now.
        case preparing
        case failed(String)

        /// True when dictations can use the model: its key is saved, or its files are on the phone.
        var isUsable: Bool {
            self == .ready || self == .preparing
        }
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
    private let prepared: PreparedModels
    private let isInFront: () -> Bool
    private let freeBytes: () -> Int64
    private var downloads: [SpeechModel: Task<Void, Never>] = [:]
    /// The one preparation that is under way, if any.
    private var preparation: Task<Void, Never>?

    private static let log = Logger(subsystem: "dev.yako.open-dictation", category: "prepare")

    /// - Parameters:
    ///   - engines: one per on-device model. Tests pass fakes.
    ///   - hasKey: whether a cloud model's key is saved.
    ///   - save: remembers the choice for the next launch.
    ///   - prepared: which models were loaded since the app or iOS last changed.
    ///   - isInFront: whether the app is on the screen.
    ///   - freeBytes: how much room the phone has.
    init(
        engines: [SpeechModel: any LocalSpeechEngine] = SpeechModel.allCases.reduce(into: [:]) { $0[$1] = $1.makeEngine() },
        selected: SpeechModel = AppSettings.speechModel,
        hasKey: @escaping (SpeechModel) -> Bool = { $0.savedKey != nil },
        save: @escaping (SpeechModel) -> Void = { AppSettings.speechModel = $0 },
        prepared: PreparedModels = .standard,
        // Not `== .active`: at the moment the app comes to the front iOS still calls it inactive.
        isInFront: @escaping () -> Bool = { UIApplication.shared.applicationState != .background },
        freeBytes: @escaping () -> Int64 = { FirstModelDownload.freeBytes() }
    ) {
        self.engines = engines
        self.hasKey = hasKey
        self.save = save
        self.prepared = prepared
        self.isInFront = isInFront
        self.freeBytes = freeBytes
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

    /// False when the model in use still needs its key. True while it is being prepared: it can
    /// be used, it is only slow right now.
    var canListen: Bool {
        status(of: selected).isUsable
    }

    /// True while the model in use is being prepared. The main screen says so.
    var isPreparing: Bool {
        status(of: selected) == .preparing
    }

    /// The engine to dictate with, or nil when a cloud model does the listening.
    var engine: (any LocalSpeechEngine)? {
        canListen ? engines[selected] : nil
    }

    func select(_ model: SpeechModel) {
        guard status(of: model).isUsable else { return }
        selected = model
        fellBackFrom = nil
        save(model)
        // It may have been downloaded before the last update and not used since.
        prepareIfNeeded()
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
        guard let engine = engines[model], downloads[model] == nil, !status(of: model).isUsable else { return nil }
        statuses[model] = .downloading(progress: 0)
        SpeechModel.keepModelsOutOfBackup()
        let task = Task {
            do {
                try await engine.download { fraction in
                    Task { @MainActor in self.report(fraction, for: model) }
                }
                statuses[model] = .ready
                // The download has loaded the model once, so there is nothing left to prepare.
                prepared.markPrepared(model)
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
            // The model in use may have waited for this download to end.
            prepareIfNeeded()
        }
        downloads[model] = task
        keepScreenOn()
        return task
    }

    func cancelDownload(_ model: SpeechModel) {
        downloads[model]?.cancel()
    }

    func delete(_ model: SpeechModel) {
        // Not while it is being prepared: iOS is reading the files.
        guard let engine = engines[model], downloads[model] == nil, status(of: model) != .preparing else { return }
        try? engine.delete()
        statuses[model] = engine.isDownloaded ? .ready : .notSetUp
        if !engine.isDownloaded { prepared.forget(model) }
        fallBackIfNeeded()
    }

    // MARK: - Preparing after an update

    /// Loads the model in use once, when it runs on the phone and has not been loaded since the
    /// app or iOS last changed. That first load is the slow one, and an intent from the Action
    /// Button only gets about 30 seconds. `PreparationRule` says when it runs: when the app comes
    /// to the front, in a background window while the phone charges, and when a dictation starts.
    /// When iOS stops the app halfway, nothing is written down and the next moment starts again.
    /// Returns the task that is under way, so the caller (or a test) can wait for the end.
    @discardableResult
    func prepareIfNeeded(_ moment: PreparationRule.Moment = .appInFront) -> Task<Void, Never>? {
        let model = selected
        // One model at a time, and not next to a download, which ends by loading a model too.
        let decision = PreparationRule.decide(
            moment,
            status: engines[model] == nil ? nil : status(of: model),
            needsPreparing: prepared.needsPreparing(model),
            isBusy: preparation != nil || !downloads.isEmpty,
            isInFront: isInFront(),
            freeBytes: freeBytes)
        guard decision == .prepare, let engine = engines[model] else {
            if case .skip(let reason) = decision {
                // Low space is worth seeing in Console; the rest happens at every launch.
                let level: OSLogType = reason == .lowStorage ? .info : .debug
                Self.log.log(level: level, "Not preparing \(model.rawValue, privacy: .public) (\(moment.rawValue, privacy: .public)): \(reason.rawValue, privacy: .public)")
            }
            return preparation
        }
        statuses[model] = .preparing
        Self.log.info("Preparing \(model.rawValue, privacy: .public) (\(moment.rawValue, privacy: .public))")
        let task = Task {
            let start = ContinuousClock.now
            do {
                try await engine.prepare()
                prepared.markPrepared(model)
                Self.log.info("Prepared \(model.rawValue, privacy: .public) in \(Self.seconds(since: start), format: .fixed(precision: 1), privacy: .public) s")
            } catch {
                // The model is as usable as before, and the next moment tries again.
                Self.log.error("Could not prepare \(model.rawValue, privacy: .public) after \(Self.seconds(since: start), format: .fixed(precision: 1), privacy: .public) s: \(error.localizedDescription, privacy: .public)")
            }
            statuses[model] = .ready
            preparation = nil
            keepScreenOn()
            // Another model may have been put in use meanwhile. That happens on the screen, so
            // only a charging window carries on as one.
            if selected != model { prepareIfNeeded(moment == .chargingWindow ? .chargingWindow : .appInFront) }
        }
        preparation = task
        keepScreenOn()
        return task
    }

    private static func seconds(since start: ContinuousClock.Instant) -> Double {
        let took = ContinuousClock.now - start
        return Double(took.components.seconds) + Double(took.components.attoseconds) / 1e18
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

    /// A locked phone suspends the app within seconds. A download dies with it, and a model that
    /// is being prepared stops halfway.
    private func keepScreenOn() {
        UIApplication.shared.isIdleTimerDisabled = !downloads.isEmpty || preparation != nil
    }
}
