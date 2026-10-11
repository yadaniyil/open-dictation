import Foundation
import Testing
@testable import OpenDictation

struct StatsFormatTests {
    @Test func wordsAreCountedInWords() {
        #expect(StatsFormat.words(0) == "0 words")
        #expect(StatsFormat.words(1) == "1 word")
        #expect(StatsFormat.words(2) == "2 words")
    }

    @Test(arguments: [
        (0.0, "0 sec"),
        (42.4, "42 sec"),
        (59.4, "59 sec"),
        (59.6, "1 min"),
        (89.0, "1 min"),
        (720.0, "12 min"),
        // 59 minutes and 40 seconds.
        (3580.0, "1 hr"),
        (3600.0, "1 hr"),
        (11_100.0, "3 hr 5 min"),
        (111_540.0, "30 hr 59 min"),
    ] as [(Double, String)])
    func aLengthOfTimeIsShort(seconds: Double, expected: String) {
        #expect(StatsFormat.duration(seconds) == expected)
    }

    @Test func aPriceShowsAsManyDigitsAsItNeeds() {
        #expect(StatsFormat.dollars(0.22) == "$0.22")
        #expect(StatsFormat.dollars(0.0045) == "$0.0045")
        #expect(StatsFormat.dollars(0) == "$0.00")
        #expect(StatsFormat.dollars(12.5) == "$12.50")
    }

    @Test(arguments: [
        (0.0, "$0.00"),
        (0.000_06, "Less than $0.01"),
        (0.009, "Less than $0.01"),
        (0.01, "About $0.01"),
        (0.424, "About $0.42"),
        (3.096, "About $3.10"),
        (1234.5, "About $1,234.50"),
    ] as [(Double, String)])
    func everySumIsAnEstimate(amount: Double, expected: String) {
        #expect(StatsFormat.estimate(amount) == expected)
    }

    @Test func theSplitNamesWhoSendsTheBill() {
        #expect(StatsFormat.split(Pricing.Cost(openAI: 2.554, elevenLabs: 0.55)) == "OpenAI $2.55 · ElevenLabs $0.55")
        #expect(StatsFormat.split(Pricing.Cost(openAI: 0.002, elevenLabs: 0.3)) == "OpenAI under $0.01 · ElevenLabs $0.30")
        #expect(StatsFormat.split(Pricing.Cost(openAI: 2.5, elevenLabs: 0)) == nil)
        #expect(StatsFormat.split(Pricing.Cost()) == nil)
    }
}
