import Foundation
import Testing
@testable import OpenDictation

struct RecordingArchiveTests {
    private func makeArchive(limit: Int) -> RecordingArchive {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("archive-\(UUID().uuidString)")
        return RecordingArchive(folder: folder, limit: limit)
    }

    private func makeRecording() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("clip-\(UUID().uuidString).m4a")
        try Data("audio".utf8).write(to: url)
        return url
    }

    private func names(in archive: RecordingArchive) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: archive.folder.path)) ?? []).sorted()
    }

    @Test func keepsTheNewestAndTheirNotes() throws {
        let archive = makeArchive(limit: 2)
        let note = RecordingArchive.Note(spoken: "um hi", final: "Hi.", style: "clean", model: "gpt-transcribe")
        for second in 1...3 {
            archive.keep(try makeRecording(), note: note, date: Date(timeIntervalSince1970: TimeInterval(second)))
        }

        #expect(names(in: archive) == ["2000.json", "2000.m4a", "3000.json", "3000.m4a"])
        let saved = try JSONDecoder().decode(
            RecordingArchive.Note.self, from: Data(contentsOf: archive.folder.appendingPathComponent("3000.json")))
        #expect(saved == note)
    }

    @Test func movesTheRecordingOutOfItsOldPlace() throws {
        let archive = makeArchive(limit: 5)
        let recording = try makeRecording()
        archive.keep(recording, note: .init(spoken: "a", final: "a", style: "asSpoken", model: "m"))
        #expect(!FileManager.default.fileExists(atPath: recording.path))
    }

    @Test func clearRemovesEverything() throws {
        let archive = makeArchive(limit: 5)
        archive.keep(try makeRecording(), note: .init(spoken: "a", final: "a", style: "asSpoken", model: "m"))
        archive.clear()
        #expect(names(in: archive).isEmpty)
    }
}
