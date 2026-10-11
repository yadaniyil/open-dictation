import Foundation

/// What the first-launch screens leave behind: the moment the user agreed to where recordings go.
/// It has its own key in UserDefaults, apart from `AppSettings`.
///
/// `UserDefaults` can be used from any thread but is not marked `Sendable`, hence `@unchecked`.
struct OnboardingState: @unchecked Sendable {
    /// The app's own state. A DEBUG launch with `-resetOnboarding` forgets the agreement first,
    /// so the screens show again for screenshots.
    static let standard: OnboardingState = {
        let state = OnboardingState(defaults: .standard)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") { state.reset() }
        #endif
        return state
    }()

    /// Other code asks this before a recording goes to a cloud provider.
    static var hasAgreedToCloudProcessing: Bool { standard.hasAgreedToCloudProcessing }

    private static let consentDateKey = "onboarding.cloudConsentDate"

    let defaults: UserDefaults

    /// When the user tapped "I agree" on the "Where your voice goes" page.
    var cloudConsentDate: Date? { defaults.object(forKey: Self.consentDateKey) as? Date }

    var hasAgreedToCloudProcessing: Bool { cloudConsentDate != nil }

    /// The screens show until the user has agreed: that tap is also what ends them.
    var needsOnboarding: Bool { !hasAgreedToCloudProcessing }

    func agreeToCloudProcessing(on date: Date = Date()) {
        defaults.set(date, forKey: Self.consentDateKey)
    }

    func reset() {
        defaults.removeObject(forKey: Self.consentDateKey)
    }
}
