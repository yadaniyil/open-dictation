import Foundation
import Testing
@testable import OpenDictation

/// The Recent list: the last texts, kept on the phone so nothing is lost if a paste goes wrong.
@MainActor
struct HistoryStoreTests {
    /// A file of its own, in a folder that does not exist yet, so the app's real list is never touched.
    private let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("history-\(UUID().uuidString)")
        .appendingPathComponent("history.json")

    @Test func theNewestTextComesFirst() {
        let history = HistoryStore(fileURL: fileURL)
        history.add("first")
        history.add("second")

        #expect(history.items.map(\.text) == ["second", "first"])
    }

    @Test func onlyTheLastThirtyAreKept() {
        let history = HistoryStore(fileURL: fileURL)
        for number in 1...35 { history.add("text \(number)") }

        #expect(history.items.count == 30)
        #expect(history.items.first?.text == "text 35")
        #expect(history.items.last?.text == "text 6")
    }

    @Test func theTextsSurviveARelaunch() {
        let history = HistoryStore(fileURL: fileURL)
        history.add("Hello there.")
        history.add("Привіт усім")

        let nextLaunch = HistoryStore(fileURL: fileURL)

        #expect(nextLaunch.items == history.items)
        #expect(nextLaunch.items.count == 2)
    }

    @Test func removingOneKeepsTheRest() {
        let history = HistoryStore(fileURL: fileURL)
        for text in ["a", "b", "c"] { history.add(text) }

        history.remove(history.items[1])

        #expect(history.items.map(\.text) == ["c", "a"])
        #expect(HistoryStore(fileURL: fileURL).items.map(\.text) == ["c", "a"])
    }

    @Test func clearingEmptiesItForGood() {
        let history = HistoryStore(fileURL: fileURL)
        history.add("a")

        history.clear()

        #expect(history.items.isEmpty)
        #expect(HistoryStore(fileURL: fileURL).items.isEmpty)
    }

    @Test func aFileThatCannotBeReadStartsEmpty() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not a list".utf8).write(to: fileURL)

        #expect(HistoryStore(fileURL: fileURL).items.isEmpty)
    }
}
