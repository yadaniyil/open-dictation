import Foundation
import Network
import os

/// Gets the on-device model without being asked, so a new user can dictate with no key and no
/// choice to make. It only starts by itself where that is safe: after the welcome pages (which
/// name the size), with room on the phone, and not on mobile data. Everywhere else the main
/// screen offers a button instead.
@MainActor
enum FirstModelDownload {
    /// Of the two models that run on the phone, the smaller and much faster one.
    static let model = SpeechModel.parakeetV3
    /// Free space to ask for: the files, the copy iOS prepares from them, and room to spare.
    static let neededBytes: Int64 = 2_500_000_000

    static let startedKey = "firstModel.startedByItself"

    private static let log = Logger(subsystem: "dev.yako.open-dictation", category: "first-model")

    /// Starts the download when that is safe. Called after the welcome pages and whenever the
    /// app comes to the front, so a phone that was on mobile data gets it later, on Wi-Fi.
    /// - Parameters:
    ///   - hasAgreed: whether the welcome pages were agreed to. Tests pass their own answer.
    ///   - freeBytes: how much room the phone has.
    ///   - isOnCheapNetwork: whether the phone is on Wi-Fi or the like.
    static func startIfSensible(
        store: SpeechModelStore = .shared,
        defaults: UserDefaults = .standard,
        hasAgreed: () -> Bool = { OnboardingState.hasAgreedToCloudProcessing },
        freeBytes: () -> Int64 = { FirstModelDownload.freeBytes() },
        isOnCheapNetwork: () async -> Bool = { await FirstModelDownload.isOnCheapNetwork() }
    ) async {
        func isWanted() -> Bool {
            // Only a phone that has nothing to listen with, and only once: a download the user
            // cancelled does not start again by itself.
            hasAgreed() && !store.canListen && store.status(of: model) == .notSetUp
                && !defaults.bool(forKey: startedKey)
        }
        guard isWanted() else { return }
        let cheap = await isOnCheapNetwork()
        let free = freeBytes()
        log.info("Wi-Fi or the like: \(cheap, privacy: .public), free bytes: \(free, privacy: .public)")
        // The answer took a moment: look again before starting.
        guard isWanted(), shouldStart(freeBytes: free, isOnCheapNetwork: cheap) else { return }
        defaults.set(true, forKey: startedKey)
        store.download(model)
    }

    /// iOS stops a download soon after the app leaves the screen, and setting up the shortcut
    /// means leaving. A stopped download keeps its files, so this carries on from there.
    static func resumeIfInterrupted(store: SpeechModelStore = .shared) {
        guard !store.canListen, case .failed = store.status(of: model) else { return }
        store.download(model)
    }

    static func shouldStart(freeBytes: Int64, isOnCheapNetwork: Bool) -> Bool {
        isOnCheapNetwork && freeBytes >= neededBytes
    }

    nonisolated private static func freeBytes() -> Int64 {
        // Asked of the app's home folder, which always exists. Application Support may not yet.
        let values = try? URL.homeDirectory.resourceValues(
            forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
        // The first is the better answer (it counts what iOS can clear), but it can come back
        // as zero, on a Simulator for one. The plain count is the fallback.
        return max(values?.volumeAvailableCapacityForImportantUsage ?? 0, Int64(values?.volumeAvailableCapacity ?? 0))
    }

    /// Wi-Fi and the like: not mobile data, not a personal hotspot, not Low Data Mode.
    /// No answer within a few seconds counts as a no, and the button stays.
    nonisolated private static func isOnCheapNetwork() async -> Bool {
        #if DEBUG
        // A Simulator may have no network service to ask. `OD_ASSUME_WIFI=1` in the launch
        // environment answers for it.
        if ProcessInfo.processInfo.environment["OD_ASSUME_WIFI"] == "1" { return true }
        #endif
        let monitor = NWPathMonitor()
        defer { monitor.cancel() }
        let answer = OneAnswer()
        return await withCheckedContinuation { continuation in
            answer.wait(with: continuation)
            monitor.pathUpdateHandler = { path in
                answer.give(path.status == .satisfied && !path.isExpensive && !path.isConstrained)
            }
            monitor.start(queue: .global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) { answer.give(false) }
        }
    }
}

/// Lets the first of several callers answer a waiting task, and ignores the rest.
private final class OneAnswer: @unchecked Sendable {
    private let lock = NSLock()
    private var waiting: CheckedContinuation<Bool, Never>?

    func wait(with continuation: CheckedContinuation<Bool, Never>) {
        lock.withLock { waiting = continuation }
    }

    func give(_ value: Bool) {
        let continuation = lock.withLock {
            defer { waiting = nil }
            return waiting
        }
        continuation?.resume(returning: value)
    }
}
