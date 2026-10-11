import Foundation

/// A testing aid: keeps the last few recordings and their texts on the device, so the same audio
/// can be run through other speech services and compared. Off unless switched on in Settings.
struct RecordingArchive: Sendable {
    static let shared = RecordingArchive(
        folder: URL.applicationSupportDirectory.appendingPathComponent("Recordings"))

    /// What the app made of the recording at the time.
    struct Note: Codable, Equatable, Sendable {
        var spoken: String
        var final: String
        var style: String
        var model: String
    }

    let folder: URL
    var limit = 20

    /// Moves the recording into the archive and drops the oldest ones over the limit.
    func keep(_ fileURL: URL, note: Note, date: Date = Date()) {
        let manager = FileManager.default
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        // Milliseconds since 1970: unique enough, and sorting by name sorts by time.
        let name = String(Int(date.timeIntervalSince1970 * 1000))
        let audio = folder.appendingPathComponent(name).appendingPathExtension("m4a")
        do {
            try manager.moveItem(at: fileURL, to: audio)
        } catch {
            try? manager.removeItem(at: fileURL)
            return
        }
        if let data = try? JSONEncoder().encode(note) {
            try? data.write(to: Self.noteURL(for: audio), options: .atomic)
        }
        prune()
    }

    func clear() {
        try? FileManager.default.removeItem(at: folder)
    }

    private func prune() {
        let manager = FileManager.default
        let recordings = ((try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "m4a" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        for old in recordings.dropLast(limit) {
            try? manager.removeItem(at: old)
            try? manager.removeItem(at: Self.noteURL(for: old))
        }
    }

    private static func noteURL(for audio: URL) -> URL {
        audio.deletingPathExtension().appendingPathExtension("json")
    }
}
