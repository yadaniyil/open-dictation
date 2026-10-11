import Foundation
@testable import OpenDictation

/// Stands in for a model on the phone. A class, so a test can steer a download that is under way.
final class FakeSpeechEngine: LocalSpeechEngine, @unchecked Sendable {
    private let lock = NSLock()
    private var downloaded: Bool
    private var steps: [Double] = []
    private var failure: LocalSpeechError?
    private var waitsForRelease = false
    private var released = false
    private var gate: CheckedContinuation<Void, Never>?
    private var prepareFailure: LocalSpeechError?
    private var prepareHold: Latch?
    private var transcribeHold: Latch?
    private var happened: [String] = []

    init(folder: URL) {
        downloaded = false
    }

    init(downloaded: Bool = false) {
        self.downloaded = downloaded
    }

    var isDownloaded: Bool {
        lock.withLock { downloaded }
    }

    /// What the next download does: report `steps`, wait for `release()` if asked, then fail or finish.
    func plan(steps: [Double], failure: LocalSpeechError? = nil, waitsForRelease: Bool = false) {
        lock.withLock {
            self.steps = steps
            self.failure = failure
            self.waitsForRelease = waitsForRelease
            released = false
        }
    }

    func release() {
        lock.withLock {
            released = true
            gate?.resume()
            gate = nil
        }
    }

    func download(progress: @escaping @Sendable (Double) -> Void) async throws {
        let (steps, failure, waits) = lock.withLock { (self.steps, self.failure, waitsForRelease) }
        steps.forEach(progress)
        if waits {
            await withCheckedContinuation { continuation in
                lock.withLock {
                    if released { continuation.resume() } else { gate = continuation }
                }
            }
        }
        try Task.checkCancellation()
        if let failure { throw failure }
        lock.withLock { downloaded = true }
    }

    func delete() throws {
        lock.withLock { downloaded = false }
    }

    /// What preparing and transcribing did, in the order it happened.
    var events: [String] {
        lock.withLock { happened }
    }

    /// How often the model was prepared, failed tries included.
    var preparations: Int {
        events.filter { $0 == "prepare began" }.count
    }

    /// What the next preparations do: wait for `hold` to open if given, then fail or finish.
    func planPreparing(failure: LocalSpeechError? = nil, hold: Latch? = nil) {
        lock.withLock {
            prepareFailure = failure
            prepareHold = hold
        }
    }

    /// Makes the next transcriptions wait for `hold` to open.
    func planTranscribing(hold: Latch?) {
        lock.withLock { transcribeHold = hold }
    }

    func prepare() async throws {
        let (failure, hold) = lock.withLock {
            happened.append("prepare began")
            return (prepareFailure, prepareHold)
        }
        await hold?.wait()
        lock.withLock { happened.append("prepare ended") }
        if let failure { throw failure }
    }

    func transcribe(fileURL: URL, languageCode: String) async throws -> String {
        let hold = lock.withLock {
            happened.append("transcribe began")
            return transcribeHold
        }
        await hold?.wait()
        lock.withLock { happened.append("transcribe ended") }
        return "fake"
    }
}

/// Holds whoever waits on it until a test opens it.
final class Latch: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func open() {
        let waiting = lock.withLock {
            isOpen = true
            defer { self.waiting = [] }
            return self.waiting
        }
        waiting.forEach { $0.resume() }
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            let isOpen = lock.withLock {
                if !self.isOpen { waiting.append(continuation) }
                return self.isOpen
            }
            if isOpen { continuation.resume() }
        }
    }
}

extension PreparedModels {
    /// Notes of its own for one test, so the app's real ones are left alone.
    static func scratch(stamp: String = "build 1") -> PreparedModels {
        PreparedModels(defaults: UserDefaults(suiteName: "PreparedModels.\(UUID().uuidString)")!, stamp: stamp)
    }
}
