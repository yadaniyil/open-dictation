import Foundation
import Testing
@testable import OpenDictation

struct OnboardingStateTests {
    /// A private store per test, so the app's own first-launch state is never touched.
    private func makeState() -> OnboardingState {
        OnboardingState(defaults: UserDefaults(suiteName: "onboarding-\(UUID().uuidString)")!)
    }

    @Test func aFreshInstallNeedsOnboardingAndHasNotAgreed() {
        let state = makeState()
        #expect(state.needsOnboarding)
        #expect(!state.hasAgreedToCloudProcessing)
        #expect(state.cloudConsentDate == nil)
    }

    @Test func agreeingStoresTheDateAndEndsOnboarding() {
        let state = makeState()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        state.agreeToCloudProcessing(on: date)

        #expect(state.hasAgreedToCloudProcessing)
        #expect(!state.needsOnboarding)
        #expect(state.cloudConsentDate == date)
    }

    @Test func theAgreementIsStillThereOnTheNextLaunch() {
        let state = makeState()
        state.agreeToCloudProcessing()

        let nextLaunch = OnboardingState(defaults: state.defaults)
        #expect(nextLaunch.hasAgreedToCloudProcessing)
    }

    @Test func resetBringsOnboardingBack() {
        let state = makeState()
        state.agreeToCloudProcessing()
        state.reset()

        #expect(state.needsOnboarding)
        #expect(state.cloudConsentDate == nil)
    }

    @Test func theConsentPageIsLastAndNamesBothCloudProviders() {
        #expect(OnboardingPage.all.last?.id == OnboardingPage.consent.id)
        let words = OnboardingPage.consent.tiles.compactMap(\.caption).map { String(localized: $0) }.joined(separator: " ")
        #expect(words.contains("OpenAI"))
        #expect(words.contains("ElevenLabs"))
    }
}
