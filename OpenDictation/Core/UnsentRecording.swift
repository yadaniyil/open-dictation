import Foundation

/// Keeps a recording safe until its text is out.
///
/// While a recording is turned into text it waits in Application Support, not in the temporary
/// folder. So it outlives an app that iOS ends halfway, as iOS can when a long recording is
/// turned into text in the background. A recording that could not be turned into text, or that
/// was still being worked on when the app ended, waits for another try.
///
/// There is one place for each. A newer recording that needs another try takes the older one's place.
struct UnsentRecording: Sendable {
    static let standard = UnsentRecording(folder: URL.applicationSupportDirectory)

    let folder: URL

    /// The recording that is being turned into text right now.
    var inWorkURL: URL { folder.appendingPathComponent("in-work.m4a") }

    /// The recording that waits for another try.
    var url: URL { folder.appendingPathComponent("unsent.m4a") }

    var exists: Bool { FileManager.default.fileExists(atPath: url.path) }

    /// Moves a new recording to where it waits while it is turned into text, and returns where
    /// it is now. If it cannot be moved, it stays where it was and the dictation goes on with it.
    func takeIn(_ recording: URL) -> URL {
        let manager = FileManager.default
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        try? manager.removeItem(at: inWorkURL)
        do {
            try manager.moveItem(at: recording, to: inWorkURL)
            return inWorkURL
        } catch {
            return recording
        }
    }

    /// Keeps a recording that could not be turned into text, in place of the one kept before.
    /// Returns whether a recording waits for another try now.
    @discardableResult
    func keepForRetry(_ fileURL: URL) -> Bool {
        guard fileURL != url else { return exists }
        let manager = FileManager.default
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        try? manager.removeItem(at: url)
        try? manager.moveItem(at: fileURL, to: url)
        return exists
    }

    /// Call once at launch, before any dictation. A recording still in the works then belongs to
    /// an app that ended before its text was out, so it waits for another try.
    /// Returns whether a recording waits for another try.
    func recoverAfterLaunch() -> Bool {
        guard FileManager.default.fileExists(atPath: inWorkURL.path) else { return exists }
        return keepForRetry(inWorkURL)
    }

    func discard() {
        try? FileManager.default.removeItem(at: url)
    }
}
