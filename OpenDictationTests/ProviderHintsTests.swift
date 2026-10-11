import Testing
@testable import OpenDictation

struct ProviderHintsTests {
    @Test(arguments: SpeechModel.allCases)
    func everyProviderSaysHowFastAndHowExactItIs(model: SpeechModel) {
        let hints = model.hints
        #expect(hints.count == 2)
        #expect(hints.last?.text.hasSuffix("accuracy") == true)
    }

    /// What the test with the owner's recordings showed: keep the words in step with it.
    @Test func theWordsFollowTheTest() {
        #expect(SpeechModel.parakeetV3.hints.map(\.text) == ["Super fast", "Average accuracy"])
        #expect(SpeechModel.whisperLargeTurbo.hints.map(\.text) == ["Slow", "Great accuracy"])
        #expect(SpeechModel.openAI.hints.map(\.text) == ["Fast", "Great accuracy"])
        #expect(SpeechModel.elevenLabs.hints.map(\.text) == ["Fast", "Best accuracy"])
    }

    @Test func onlyTheBestAndTheWeakestStandOut() {
        #expect(SpeechModel.parakeetV3.hints.map(\.level) == [.best, .weak])
        #expect(SpeechModel.whisperLargeTurbo.hints.map(\.level) == [.weak, .good])
        #expect(SpeechModel.elevenLabs.hints.map(\.level) == [.good, .best])
        #expect(SpeechModel.openAI.hints.map(\.level) == [.good, .good])
    }
}
