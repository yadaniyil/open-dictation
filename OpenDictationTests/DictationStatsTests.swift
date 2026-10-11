import Foundation
import Testing
@testable import OpenDictation

struct DictationStatsTests {
    private func stats(_ records: [DictationRecord], now: String, limit: Int = 2_000) -> DictationStats {
        var contents = DictationLog.Contents()
        for record in records {
            contents.add(record, limit: limit, calendar: StatsTestSupport.calendar)
        }
        return DictationStats(contents, now: StatsTestSupport.date(now), calendar: StatsTestSupport.calendar)
    }

    // MARK: - The last 7 days and this month

    @Test func theLastSevenDaysAreCountedBackFromNow() {
        let records: [DictationRecord] = [
            .sample("2026-10-01T09:00:00Z", words: 1),
            // One second too old, then one second inside.
            .sample("2026-10-04T11:59:59Z", words: 10),
            .sample("2026-10-04T12:00:01Z", words: 100),
            .sample("2026-10-11T11:00:00Z", .parakeetV3, words: 1000),
        ]

        let today = stats(records, now: "2026-10-11T12:00:00Z")
        #expect(today.lastSevenDays.words == 1100)
        #expect(today.lastSevenDays.dictations == 2)

        // The same log a week later: nothing is that new any more.
        let later = stats(records, now: "2026-10-18T12:00:00Z")
        #expect(later.lastSevenDays == DictationTotals())
        #expect(later.total.words == 1111)
    }

    @Test func thisMonthBeginsOnTheFirst() {
        let records: [DictationRecord] = [
            .sample("2026-09-30T23:59:59Z", words: 1),
            .sample("2026-10-01T00:00:00Z", words: 10),
            .sample("2026-10-11T09:00:00Z", .elevenLabs, words: 100),
        ]

        let october = stats(records, now: "2026-10-11T12:00:00Z")
        #expect(october.thisMonth[.openAI]?.words == 10)
        #expect(october.thisMonth[.elevenLabs]?.words == 100)
        // September's dictation is not this month's, but it is one of the last 7 days'.
        #expect(october.lastSevenDays.words == 100)
        #expect(stats(Array(records.prefix(2)), now: "2026-10-01T00:00:01Z").lastSevenDays.words == 11)

        let november = stats(records, now: "2026-11-02T12:00:00Z")
        #expect(november.thisMonth.isEmpty)
        #expect(november.total.words == 111)
    }

    @Test func thisMonthCountsWhatWasFoldedIntoMonthTotalsToo() {
        let records: [DictationRecord] = [
            .sample("2026-09-29T09:00:00Z", words: 1),
            .sample("2026-10-02T09:00:00Z", words: 10),
            .sample("2026-10-03T09:00:00Z", words: 100),
        ]
        // Only the newest is kept as a line of its own.
        let october = stats(records, now: "2026-10-11T12:00:00Z", limit: 1)
        #expect(october.thisMonth[.openAI]?.words == 110)
        #expect(october.total.words == 111)
    }

    // MARK: - Speed

    @Test func speedIsWaitingPerMinuteOfSpeech() {
        // 90 seconds of speech took 13.5 seconds: 9 for each minute.
        let records: [DictationRecord] = [
            .sample("2026-10-10T09:00:00Z", .whisperLargeTurbo, audio: 30, speech: 6),
            .sample("2026-10-10T10:00:00Z", .whisperLargeTurbo, audio: 60, speech: 7.5),
        ]
        #expect(DictationStats.secondsPerMinute(of: records) == 9)
    }

    @Test func speedNeedsAMinuteOfSpeech() {
        let short: [DictationRecord] = [
            .sample("2026-10-10T09:00:00Z", audio: 29.5, speech: 3),
            .sample("2026-10-10T10:00:00Z", audio: 30, speech: 3),
        ]
        #expect(DictationStats.secondsPerMinute(of: short) == nil)
        #expect(DictationStats.secondsPerMinute(of: []) == nil)
        #expect(DictationStats.secondsPerMinute(of: short + [.sample("2026-10-10T11:00:00Z", audio: 0.5, speech: 0)]) == 6)
    }

    @Test func speedFollowsTheLatestDictationsOnly() {
        // Ten slow ones from long ago, then fifty quick ones.
        let slow = (0..<10).map { _ in DictationRecord.sample("2026-01-01T09:00:00Z", audio: 60, speech: 60) }
        let quick = (0..<DictationStats.speedSample).map { _ in
            DictationRecord.sample("2026-10-10T09:00:00Z", audio: 60, speech: 4)
        }
        #expect(DictationStats.secondsPerMinute(of: slow + quick) == 4)
    }

    @Test func eachProviderHasItsOwnSpeed() {
        let measured = stats([
            .sample("2026-10-10T09:00:00Z", .parakeetV3, audio: 120, speech: 10),
            .sample("2026-10-10T10:00:00Z", .whisperLargeTurbo, audio: 120, speech: 40),
            .sample("2026-10-10T11:00:00Z", .openAI, audio: 20, speech: 2),
        ], now: "2026-10-11T12:00:00Z")

        #expect(measured.secondsPerMinute[.parakeetV3] == 5)
        #expect(measured.secondsPerMinute[.whisperLargeTurbo] == 20)
        // Used, but not for long enough to say.
        #expect(measured.secondsPerMinute[.openAI] == nil)
        #expect(measured.secondsPerMinute[.elevenLabs] == nil)
        #expect(measured.providers == [.openAI, .parakeetV3, .whisperLargeTurbo])
    }

    // MARK: - Time

    @Test func timeSavedIsTypingTimeLessTalkingAndWaiting() {
        // 360 words are ten minutes of typing. Saying them took 150 seconds, the text 20 more.
        var totals = DictationTotals()
        totals.add(.sample("2026-10-10T09:00:00Z", audio: 150, speech: 12, text: 8, words: 360))
        #expect(totals.secondsSaved == 600 - 150 - 12 - 8)
    }

    @Test func timeSavedIsNeverLessThanNothing() {
        var totals = DictationTotals()
        totals.add(.sample("2026-10-10T09:00:00Z", audio: 60, speech: 30, words: 3))
        #expect(totals.secondsSaved == 0)
        #expect(DictationTotals().secondsSaved == 0)
    }

    @Test func theTextStepIsAveragedOverTheDictationsThatHadOne() {
        var totals = DictationTotals()
        totals.add(.sample("2026-10-10T09:00:00Z", text: 1))
        totals.add(.sample("2026-10-10T10:00:00Z"))
        totals.add(.sample("2026-10-10T11:00:00Z", text: 2))
        #expect(totals.textSteps == 2)
        #expect(totals.secondsPerTextStep == 1.5)
        #expect(DictationTotals().secondsPerTextStep == nil)
    }

    // MARK: - Words

    @Test(arguments: [
        ("", 0),
        ("  \n ", 0),
        ("Hello", 1),
        ("Hello there, world.", 3),
        ("Don't stop: it's 12% of 250 zł.", 7),
        ("Привіт, як справи?", 3),
        ("one\ntwo\tthree  four", 4),
    ] as [(String, Int)])
    func wordsAreCounted(text: String, expected: Int) {
        #expect(DictationRecord.words(in: text) == expected)
    }
}
