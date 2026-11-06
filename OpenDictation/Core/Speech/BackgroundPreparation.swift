import BackgroundTasks
import Foundation
import os

/// Asks iOS for a background window while the phone charges, and prepares the model in use there
/// when an app or iOS update has made its next load the slow one and the app did not get to do it
/// yet, for one because the user only dictates from the Action Button.
///
/// - Only while the phone charges (`requiresExternalPower`), so it costs no battery, and no network.
/// - Only asked for when there is work (`SpeechModelStore.needsChargingWindow`): never for a cloud
///   model, a model not downloaded, or one already prepared on this version. With no work, a
///   request that is still waiting is taken back.
/// - No sooner than `pause` after the last window, whoever asks.
/// - iOS picks the moment and may not give one at all (after the app was swiped away, for one).
///   The app then still prepares when it comes to the front, and when a dictation starts.
enum BackgroundPreparation {
    /// Also in `BGTaskSchedulerPermittedIdentifiers` (project.yml): iOS refuses any other name.
    static let identifier = "dev.yako.open-dictation.prepare-model"

    /// After a window, the next one is asked for no sooner than this, so a phone on the charger
    /// does not wake the app again and again.
    static let pause: TimeInterval = 60 * 60

    /// When the last window began, in `UserDefaults`, so the pause holds across launches.
    static let lastWindowKey = "backgroundPreparation.lastWindow"

    private static let log = Logger(subsystem: "dev.yako.open-dictation", category: "prepare")

    /// Talks to iOS off the main thread, so a dictation start does not wait for it, and in order,
    /// so a request taken back is not asked for again by an older call.
    private static let queue = DispatchQueue(label: "dev.yako.open-dictation.background-preparation", qos: .utility)

    /// Call while the app launches: iOS only takes the handler then.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            let window = ChargingWindow(task: task)
            MainActor.assumeIsolated { run(window) }
        }
    }

    /// Asks for the next window when the model in use has work waiting, and takes a waiting
    /// request back when it has none. A request that is already waiting is replaced, with the
    /// same pause after the last window.
    @MainActor
    static func askIfNeeded(store: SpeechModelStore = .shared, defaults: UserDefaults = .standard) {
        let isWanted = store.needsChargingWindow
        let earliest = notBefore(lastWindow: defaults.object(forKey: lastWindowKey) as? Date, now: .now)
        queue.async {
            guard isWanted else {
                BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
                return
            }
            do {
                try BGTaskScheduler.shared.submit(request(notBefore: earliest))
            } catch {
                // The Simulator always says no.
                log.debug("No background window: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// The earliest moment for the next window: `pause` after the last one, or any time.
    static func notBefore(lastWindow: Date?, now: Date) -> Date? {
        guard let lastWindow else { return nil }
        let next = lastWindow.addingTimeInterval(pause)
        return next > now ? next : nil
    }

    static func request(notBefore: Date?) -> BGProcessingTaskRequest {
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresExternalPower = true
        request.requiresNetworkConnectivity = false
        request.earliestBeginDate = notBefore
        return request
    }

    /// Prepares the model in use if it needs it, and says whether it is ready for its next
    /// dictation now. False when the load failed, or was not tried because the phone is low on
    /// space: the window then did not do its job.
    @MainActor
    static func prepare(_ store: SpeechModelStore) async -> Bool {
        await store.prepareIfNeeded(.chargingWindow)?.value
        return !store.needsChargingWindow
    }

    @MainActor
    private static func run(_ window: ChargingWindow) {
        log.info("Background window")
        let store = SpeechModelStore.shared
        UserDefaults.standard.set(Date.now, forKey: lastWindowKey)
        window.task.expirationHandler = {
            // Core ML cannot be stopped halfway. Nothing is written down, so the next moment
            // starts again.
            log.info("The background window ended before the model was prepared")
            window.complete(success: false)
        }
        // Asked for first, so a window that iOS cuts short still leaves the next one behind.
        askIfNeeded(store: store)
        Task {
            let isReady = await prepare(store)
            if isReady {
                // Nothing left to do: the request asked for above is taken back.
                askIfNeeded(store: store)
            } else {
                log.info("The background window could not prepare the model; the next one tries again")
            }
            window.complete(success: isReady)
        }
    }
}

/// `BGTask` can be used from any thread but is not marked `Sendable`. This box carries it, and
/// makes sure iOS is told only once that the window is over.
private final class ChargingWindow: @unchecked Sendable {
    let task: BGTask
    private let lock = NSLock()
    private var isOver = false

    init(task: BGTask) {
        self.task = task
    }

    func complete(success: Bool) {
        let isFirst = lock.withLock {
            defer { isOver = true }
            return !isOver
        }
        if isFirst { task.setTaskCompleted(success: success) }
    }
}
