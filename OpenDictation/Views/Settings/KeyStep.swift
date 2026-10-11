import Foundation

/// One thing to do on the way to a cloud provider's key. `ProviderKeySteps` numbers them.
struct KeyStep: Sendable {
    let text: String
    /// The page to do it on, where there is one. It opens in the browser.
    var link: KeyStepLink?
}

struct KeyStepLink: Sendable {
    /// The address as shown, without "https://".
    let title: String
    let url: URL
}

extension SpeechModel {
    /// How to get this provider's key, in order. Empty for an on-device model, which needs none.
    /// The words stay away from the sites' own button names, which change.
    var keySteps: [KeyStep] {
        switch self {
        case .openAI:
            [
                KeyStep(
                    text: "Open OpenAI's key page. Sign in, or make an account.",
                    link: KeyStepLink(title: "platform.openai.com/api-keys", url: AppLinks.openAIKeys)),
                KeyStep(
                    text: "Add a little credit under Billing. OpenAI asks for it before a key works.",
                    link: KeyStepLink(title: "Open Billing", url: AppLinks.openAIBilling)),
                KeyStep(
                    text: "Make a new secret key. If you restrict it, set List models to Read and Model capabilities to Request."),
                KeyStep(text: "Copy the key. Paste it at the top of this page."),
            ]
        case .elevenLabs:
            [
                KeyStep(
                    text: "Open ElevenLabs' key page. Sign in, or make an account.",
                    link: KeyStepLink(title: "elevenlabs.io/app/developers/api-keys", url: AppLinks.elevenLabsKeys)),
                KeyStep(text: "Make a new key. Give it the Speech to Text permission."),
                KeyStep(text: "Copy the key. Paste it at the top of this page."),
            ]
        case .parakeetV3, .whisperLargeTurbo:
            []
        }
    }
}
