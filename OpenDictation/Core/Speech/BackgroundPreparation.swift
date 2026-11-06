import BackgroundTasks
import Foundation
import os

/// Asks iOS for a background window while the phone charges, and prepares the model in use there
/// when an app or iOS update has made its next load the slow one. That covers someone who only
/// dictates from the Action Button and does not open the app after an update.
///
/// - Only while the phone charges (`requiresExternalPower`), so it costs no battery, and no network.
/// - iOS picks the moment and may not give one at all (after the app was swiped away, for one).
///   The app then still prepares when it comes to the front, and when a dictation starts.
/// - A window with nothing to prepare ends at once.
enum BackgroundPreparation {
    /// Also in `BGTaskSchedulerPermittedIdentifiers` (project.yml): iOS refuses any other name.
    static let identifier = "dev.yako.open-dictation.prepare-model"

    /// After a window, the next one is asked for no sooner than this, so a phone on the charger
    /// does not wake the app again and again for nothing.
    static let pause: TimeInterval = 60 * 60

    private static let log = Logger(subsystem: "dev.yako.open-dictation", category: "prepare")

    /// Call while the app launches: iOS only takes the handler then.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            let window = ChargingWindow(task: task)
            MainActor.assumeIsolated { run(window) }
        }
    }

    /// Asks for the next window. A request that is already waiting is replaced.
    static func ask(notBefore: Date? = nil) {
        do {
            try BGTaskScheduler.shared.submit(request(notBefore: notBefore))
        } catch {
            // The Simulator always says no.
            log.debug("No background window: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// The same, off the main thread, for a moment when the app is busy, such as a dictation starting.
    static func askSoon() {
        Task.detached(priority: .utility) { ask() }
    }

    static func request(notBefore: Date?) -> BGProcessingTaskRequest {
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresExternalPower = true
        request.requiresNetworkConnectivity = false
        request.earliestBeginDate = notBefore
        return request
    }

    @MainActor
    private static func run(_ window: ChargingWindow) {
        log.info("Background window")
        // Asked for first, so a window that iOS cuts short still leaves the next one behind.
        ask(notBefore: Date(timeIntervalSinceNow: pause))
        let work = SpeechModelStore.shared.prepareIfNeeded(.chargingWindow)
        window.task.expirationHandler = {
            // Core ML cannot be stopped halfway. Nothing is written down, so the next moment
            // starts again.
            log.info("The background window ended before the model was prepared")
            window.complete(success: false)
        }
        Task {
            await work?.value
            window.complete(success: true)
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
