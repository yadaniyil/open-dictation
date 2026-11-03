import Foundation
import Testing
@testable import OpenDictation

/// A recording must outlive an app that iOS ends while its text is being made.
struct UnsentRecordingTests {
    /// A folder of its own that does not exist yet, as on a new phone.
    private let unsent = UnsentRecording(
        folder: FileManager.default.temporaryDirectory.appendingPathComponent("unsent-\(UUID().uuidString)"))

    /// A recording as the microphone leaves it: in the temporary folder.
    private func makeRecording(_ words: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dictation-\(UUID().uuidString).m4a")
        try Data(words.utf8).write(to: url)
        return url
    }

    private func contents(of url: URL) -> String? {
        (try? Data(contentsOf: url)).map { String(decoding: $0, as: UTF8.self) }
    }

    private func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    @Test func aNewRecordingLeavesTheTemporaryFolderBeforeItsTextIsMade() throws {
        let recording = try makeRecording("new")

        let inWork = unsent.takeIn(recording)

        #expect(inWork == unsent.inWorkURL)
        #expect(!exists(recording))
        #expect(contents(of: inWork) == "new")
        // Being worked on is not the same as waiting for another try.
        #expect(!unsent.exists)
    }

    /// iOS ended the app while the text was being made. The next launch finds the recording.
    @Test func aRecordingStillInTheWorksAtLaunchWaitsForAnotherTry() throws {
        _ = unsent.takeIn(try makeRecording("cut short"))

        let nextLaunch = UnsentRecording(folder: unsent.folder)

        #expect(nextLaunch.recoverAfterLaunch())
        #expect(nextLaunch.exists)
        #expect(contents(of: nextLaunch.url) == "cut short")
        #expect(!exists(nextLaunch.inWorkURL))
    }

    @Test func aLaunchWithNothingLeftOverFindsNothing() {
        #expect(!unsent.recoverAfterLaunch())
        #expect(!unsent.exists)
    }

    @Test func aRecordingThatWaitedBeforeStillWaitsAfterALaunch() throws {
        unsent.keepForRetry(unsent.takeIn(try makeRecording("old")))

        #expect(UnsentRecording(folder: unsent.folder).recoverAfterLaunch())
        #expect(contents(of: unsent.url) == "old")
    }

    @Test func aFailedRecordingWaitsInPlaceOfTheOlderOne() throws {
        unsent.keepForRetry(unsent.takeIn(try makeRecording("old")))
        let failed = unsent.takeIn(try makeRecording("new"))

        #expect(unsent.keepForRetry(failed))
        #expect(contents(of: unsent.url) == "new")
        #expect(!exists(failed))
    }

    @Test func aRetryThatFailsAgainKeepsTheRecording() throws {
        unsent.keepForRetry(unsent.takeIn(try makeRecording("again")))

        #expect(unsent.keepForRetry(unsent.url))
        #expect(contents(of: unsent.url) == "again")
    }

    @Test func aRecordingThatCannotBeMovedIsUsedWhereItIs() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).m4a")
        #expect(unsent.takeIn(missing) == missing)
    }

    @Test func throwingItAwayRemovesIt() throws {
        unsent.keepForRetry(try makeRecording("gone"))

        unsent.discard()

        #expect(!unsent.exists)
        #expect(!unsent.recoverAfterLaunch())
    }

    /// A phone updated from an older build keeps its waiting recording there.
    @Test func theWaitingRecordingKeepsItsOldPlace() {
        #expect(UnsentRecording.standard.url == URL.applicationSupportDirectory.appendingPathComponent("unsent.m4a"))
    }
}
