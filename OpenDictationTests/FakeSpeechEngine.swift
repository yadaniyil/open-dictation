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

    func transcribe(fileURL: URL, languageCode: String) async throws -> String {
        "fake"
    }
}
