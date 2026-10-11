import Foundation
import Testing
@testable import OpenDictation

struct PricingTests {
    private func totals(audio: Double = 0, input: Int = 0, output: Int = 0) -> DictationTotals {
        DictationTotals(audioSeconds: audio, inputTokens: input, outputTokens: output)
    }

    private func isClose(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 0.000_000_1
    }

    @Test func openAISpeechIsPaidByTheMinute() {
        // 100 minutes at $0.0045.
        let cost = Pricing.cost(of: [.openAI: totals(audio: 6000)])
        #expect(isClose(cost.openAI, 0.45))
        #expect(cost.elevenLabs == 0)
        #expect(isClose(cost.total, 0.45))
    }

    @Test func elevenLabsSpeechIsPaidByTheHour() {
        // Two and a half hours at $0.22.
        let cost = Pricing.cost(of: [.elevenLabs: totals(audio: 9000)])
        #expect(isClose(cost.elevenLabs, 0.55))
        #expect(cost.openAI == 0)
    }

    @Test func onDeviceModelsCostNothing() {
        let cost = Pricing.cost(of: [.parakeetV3: totals(audio: 36_000), .whisperLargeTurbo: totals(audio: 36_000)])
        #expect(cost == Pricing.Cost())
        #expect(cost.total == 0)
    }

    @Test func theTextStepIsPaidByTheTokenToOpenAIWhoeverListened() {
        // A million tokens in and a million out: $0.10 and $0.50.
        for provider in SpeechModel.allCases {
            let cost = Pricing.cost(of: [provider: totals(input: 1_000_000, output: 1_000_000)])
            #expect(isClose(cost.openAI, 0.60))
        }
        // A usual dictation: about 300 tokens in and 60 out, far below a cent.
        let one = Pricing.cost(of: [.parakeetV3: totals(input: 300, output: 60)])
        #expect(isClose(one.openAI, 0.000_06))
    }

    @Test func everythingIsAddedUp() {
        let cost = Pricing.cost(of: [
            .openAI: totals(audio: 6000, input: 1_000_000, output: 200_000),
            .elevenLabs: totals(audio: 3600, input: 500_000),
            .parakeetV3: totals(audio: 6000, output: 100_000),
        ])
        // OpenAI: 0.45 speech, 0.15 input tokens, 0.15 output tokens.
        #expect(isClose(cost.openAI, 0.75))
        #expect(isClose(cost.elevenLabs, 0.22))
        #expect(isClose(cost.total, 0.97))
    }

    @Test func theSplitIsOnlyWorthShowingWhenBothSendABill() {
        #expect(Pricing.Cost(openAI: 1, elevenLabs: 1).isSplit)
        #expect(!Pricing.Cost(openAI: 1, elevenLabs: 0).isSplit)
        #expect(!Pricing.Cost(openAI: 0, elevenLabs: 1).isSplit)
        #expect(!Pricing.Cost().isSplit)
    }

    @Test func nothingDictatedCostsNothing() {
        #expect(Pricing.cost(of: [:]) == Pricing.Cost())
    }
}
