import Foundation

/// One first-launch screen, as data. `OnboardingPageView` draws every page the same way.
struct OnboardingPage: Sendable {
    struct FooterLink: Sendable {
        let title: LocalizedStringResource
        let url: URL
    }

    /// A short name, used to tell the pages apart in code and in UI tests.
    let id: String
    /// What VoiceOver says for the drawing at the top. Only a page that has this gets the drawing.
    var heroDescription: LocalizedStringResource?
    let title: LocalizedStringResource
    let tiles: [OnboardingTile]
    /// How many tiles sit side by side.
    let columns: Int
    /// One more tile under the others, as wide as the page.
    var wideTile: OnboardingTile?
    let buttonTitle: LocalizedStringResource
    /// A plain link under the button.
    var link: FooterLink?

    /// In the order they are shown. The consent page is last, so nobody can finish without it.
    static let all = [talk, yours, consent]

    static let talk = OnboardingPage(
        id: "talk",
        heroDescription: "Hold the Action Button, talk, hold again, and your words are on the clipboard.",
        title: "Talk. Paste.",
        tiles: [
            OnboardingTile(picture: .phoneWithButton, label: "Hold"),
            OnboardingTile(picture: .symbol("mic.fill"), label: "Talk"),
            OnboardingTile(picture: .clipboardWithCheck, label: "Paste"),
        ],
        columns: 3,
        buttonTitle: "Continue")

    static let yours = OnboardingPage(
        id: "yours",
        title: "Your keys.\nYour phone.",
        tiles: [
            OnboardingTile(picture: .symbol("key.fill"), label: "Your own key"),
            OnboardingTile(picture: .phoneWithWaveform, label: "On-device models"),
            OnboardingTile(picture: .crossedOut("person.fill"), label: "No account"),
            OnboardingTile(picture: .crossedOut("server.rack"), label: "No servers"),
            OnboardingTile(picture: .crossedOut("chart.bar.fill"), label: "No analytics"),
            OnboardingTile(
                picture: .symbol("chevron.left.forwardslash.chevron.right"),
                label: "Open source",
                url: AppLinks.repository),
        ],
        columns: 2,
        buttonTitle: "Continue")

    /// The disclosure and permission that App Store guideline 5.1.2(i) asks for before anything
    /// is sent to a third-party AI service. The two captions are the whole disclosure: change
    /// them only together with the privacy policy.
    static let consent = OnboardingPage(
        id: "consent",
        title: "Where your\nvoice goes",
        tiles: [
            OnboardingTile(
                picture: .symbol("cloud.fill"),
                label: "Cloud",
                caption: "Goes to OpenAI or ElevenLabs, with your key"),
            OnboardingTile(
                picture: .symbol("iphone"),
                label: "On device",
                caption: "Stays on this iPhone. A 494 MB download."),
        ],
        columns: 2,
        wideTile: OnboardingTile(
            picture: .symbol("checkmark.shield.fill"),
            label: "We never receive it",
            look: .good),
        buttonTitle: "I agree",
        link: FooterLink(title: "Privacy policy", url: AppLinks.privacyPolicy))
}

/// One tile on a page: a picture over a few words.
struct OnboardingTile: Identifiable, Sendable {
    enum Picture: Sendable {
        /// An SF Symbol by name.
        case symbol(String)
        /// The symbol with a line through it, for what the app does not have.
        case crossedOut(String)
        // Three pictures SF Symbols does not have, each put together from two parts.
        case phoneWithButton
        case phoneWithWaveform
        case clipboardWithCheck
    }

    enum Look: Sendable {
        case plain
        /// A green picture, for the reassuring tile.
        case good
    }

    let picture: Picture
    let label: LocalizedStringResource
    var caption: LocalizedStringResource?
    var look = Look.plain
    /// A tile with a link opens it when tapped, and is filled with the accent colour to say so.
    var url: URL?

    var id: String { label.key }
}
