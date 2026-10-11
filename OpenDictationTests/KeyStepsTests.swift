import Foundation
import Testing
@testable import OpenDictation

struct KeyStepsTests {
    @Test(arguments: [SpeechModel.openAI, .elevenLabs])
    func aCloudProviderSaysHowToGetItsKey(model: SpeechModel) throws {
        let steps = model.keySteps
        #expect(steps.count >= 3)
        // The first step opens the provider's own key page, the last one ends in the app.
        let link = try #require(steps.first?.link)
        #expect(link.url.scheme == "https")
        #expect(link.url.host()?.hasSuffix(model == .openAI ? "openai.com" : "elevenlabs.io") == true)
        #expect(steps.last?.text.contains("Paste it at the top") == true)
    }

    @Test(arguments: [SpeechModel.parakeetV3, .whisperLargeTurbo])
    func anOnDeviceModelNeedsNoKey(model: SpeechModel) {
        #expect(model.keySteps.isEmpty)
    }

    /// A restricted key that lacks these is saved and then fails on the first dictation.
    @Test func thePermissionsARestrictedKeyNeedsAreNamed() {
        let openAI = SpeechModel.openAI.keySteps.map(\.text).joined(separator: " ")
        #expect(openAI.contains("List models") && openAI.contains("Model capabilities"))
        let elevenLabs = SpeechModel.elevenLabs.keySteps.map(\.text).joined(separator: " ")
        #expect(elevenLabs.contains("Speech to Text"))
    }
}
