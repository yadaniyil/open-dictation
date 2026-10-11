import Foundation
import Testing
@testable import OpenDictation

struct DictationLogTests {
    private let now = StatsTestSupport.date("2026-10-11T12:00:00Z")

    @Test func aNewLogIsEmpty() async {
        let stats = await StatsTestSupport.makeLog().stats(now: now)
        #expect(stats.isEmpty)
        #expect(stats.total == DictationTotals())
        #expect(stats.providers.isEmpty)
    }

    @Test func dictationsAreAddedUpByProvider() async {
        let log = StatsTestSupport.makeLog()
        await log.add(.sample("2026-10-10T09:00:00Z", .openAI, audio: 30, speech: 3, text: 2, words: 60, input: 300, output: 70))
        await log.add(.sample("2026-10-10T10:00:00Z", .openAI, audio: 10, speech: 1, words: 20))
        await log.add(.sample("2026-10-11T08:00:00Z", .parakeetV3, audio: 20, speech: 2, text: 1, words: 45, input: 280, output: 50))

        let stats = await log.stats(now: now)
        #expect(stats.allTime[.openAI] == DictationTotals(
            dictations: 2, words: 80, audioSeconds: 40, speechSeconds: 4,
            textSteps: 1, textSeconds: 2, inputTokens: 300, outputTokens: 70))
        #expect(stats.allTime[.parakeetV3]?.dictations == 1)
        #expect(stats.total == DictationTotals(
            dictations: 3, words: 125, audioSeconds: 60, speechSeconds: 6,
            textSteps: 2, textSeconds: 3, inputTokens: 580, outputTokens: 120))
        #expect(stats.providers == [.openAI, .parakeetV3])
    }

    @Test func theLogSurvivesAReload() async {
        let fileURL = StatsTestSupport.newFileURL()
        let first = StatsTestSupport.makeLog(fileURL: fileURL)
        await first.add(.sample("2026-10-10T09:00:00Z", .elevenLabs, text: 1.5, input: 310, output: 64))
        await first.add(.sample("2026-10-11T09:00:00Z", .whisperLargeTurbo))
        let before = await first.stats(now: now)

        let nextLaunch = StatsTestSupport.makeLog(fileURL: fileURL)
        #expect(await nextLaunch.stats(now: now) == before)
        #expect(before.total.dictations == 2)
    }

    @Test func aBrokenFileStartsFromZeroAndIsReplaced() async throws {
        let fileURL = StatsTestSupport.newFileURL()
        try Data("{ not the stats".utf8).write(to: fileURL)

        let log = StatsTestSupport.makeLog(fileURL: fileURL)
        #expect(await log.stats(now: now).isEmpty)

        await log.add(.sample("2026-10-11T09:00:00Z"))
        #expect(try StatsTestSupport.saved(at: fileURL).records.count == 1)
    }

    @Test func aFileThatCannotBeWrittenLosesNothingButTheFile() async {
        // No folder can be made under a file, so every save fails.
        let log = StatsTestSupport.makeLog(fileURL: URL(fileURLWithPath: "/dev/null/stats.json"))
        await log.add(.sample("2026-10-11T09:00:00Z"))
        #expect(await log.stats(now: now).total.dictations == 1)
    }

    @Test func onlyTheNewestAreKeptOneByOne() async throws {
        let fileURL = StatsTestSupport.newFileURL()
        let log = StatsTestSupport.makeLog(fileURL: fileURL, limit: 3)
        for hour in 1...5 {
            await log.add(.sample("2026-10-11T0\(hour):00:00Z", words: hour))
        }

        let saved = try StatsTestSupport.saved(at: fileURL)
        #expect(saved.records.map(\.words) == [3, 4, 5])
        #expect(saved.months["2026-10"]?[.openAI]?.dictations == 2)
        #expect(saved.months["2026-10"]?[.openAI]?.words == 3)
        // Nothing is lost by it: the totals still count all five.
        let stats = await log.stats(now: now)
        #expect(stats.total.dictations == 5)
        #expect(stats.total.words == 15)
        #expect(stats.thisMonth[.openAI]?.dictations == 5)
    }

    @Test func dictationsOverAYearOldBecomeMonthTotals() async throws {
        let fileURL = StatsTestSupport.newFileURL()
        let log = StatsTestSupport.makeLog(fileURL: fileURL)
        await log.add(.sample("2025-09-10T09:00:00Z", .elevenLabs, words: 10))
        await log.add(.sample("2025-09-20T09:00:00Z", .openAI, words: 20))
        await log.add(.sample("2025-10-12T09:00:00Z", .openAI, words: 30))
        await log.add(.sample("2026-10-11T09:00:00Z", .parakeetV3, words: 40))

        let saved = try StatsTestSupport.saved(at: fileURL)
        #expect(saved.records.map(\.words) == [30, 40])
        #expect(Set(saved.months.keys) == ["2025-09"])
        // The file is plain to read: months and providers by name, dates as text.
        let file = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(file.contains(#""months":{"2025-09":{"elevenLabs":{"#))
        #expect(file.contains(#""date":"2026-10-11T09:00:00Z""#))
        #expect(file.contains(#""provider":"parakeetV3""#))
        #expect(saved.months["2025-09"]?[.elevenLabs]?.words == 10)
        #expect(saved.months["2025-09"]?[.openAI]?.words == 20)

        let stats = await log.stats(now: now)
        #expect(stats.total.words == 100)
        #expect(stats.allTime[.openAI]?.words == 50)
        #expect(stats.thisMonth.values.map(\.words) == [40])
    }

    @Test func theFileStaysSmallAfterYearsOfUse() async throws {
        // Four dictations a day for three years, one provider after the other.
        let start = StatsTestSupport.date("2023-10-12T08:00:00Z")
        let count = 4 * 365 * 3
        var contents = DictationLog.Contents()
        for index in 0..<count {
            contents.add(
                DictationRecord(
                    date: start.addingTimeInterval(Double(index) * 6 * 3600),
                    provider: SpeechModel.allCases[index % 4], audioSeconds: 12.5, speechSeconds: 1.25,
                    textSeconds: 1.5, words: 30, inputTokens: 300, outputTokens: 40),
                limit: 50, calendar: StatsTestSupport.calendar)
        }
        #expect(contents.records.count == 50)
        // October 2023 to September 2026.
        #expect(contents.months.count == 36)

        // One more through the log itself, to see what lands on disk.
        let fileURL = StatsTestSupport.newFileURL()
        let log = DictationLog(fileURL: fileURL, limit: 50, calendar: StatsTestSupport.calendar, contents: contents)
        await log.add(.sample("2026-10-11T09:00:00Z"))
        let size = try #require(try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int)
        #expect(size < 50_000)
        #expect(await log.stats(now: now).total.dictations == count + 1)
    }

    @Test func clearEmptiesTheLogAndRemovesTheFile() async {
        let fileURL = StatsTestSupport.newFileURL()
        let log = StatsTestSupport.makeLog(fileURL: fileURL)
        await log.add(.sample("2026-10-11T09:00:00Z"))
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        await log.clear()
        #expect(await log.stats(now: now).isEmpty)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(await StatsTestSupport.makeLog(fileURL: fileURL).stats(now: now).isEmpty)
    }

    @Test func aDictationHandsItsNumbersOverWithoutWaiting() async throws {
        let log = StatsTestSupport.makeLog()
        // A dictation whose recording could not be measured has no line.
        log.record(nil)
        log.record(.sample("2026-10-11T09:00:00Z", words: 7))

        // `record` does not wait for the file, so the test has to.
        var tries = 0
        while await log.stats(now: now).isEmpty, tries < 300 {
            try await Task.sleep(for: .milliseconds(10))
            tries += 1
        }
        #expect(await log.stats(now: now).total == DictationTotals(
            dictations: 1, words: 7, audioSeconds: 30, speechSeconds: 3))
    }
}
