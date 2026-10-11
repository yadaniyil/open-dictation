import SwiftUI

/// How a speech model looks and reads in Settings.
extension SpeechModel {
    /// The logo of the company that made the model: Parakeet is NVIDIA's, Whisper is OpenAI's.
    var logo: ProviderMark {
        switch self {
        case .openAI, .whisperLargeTurbo: .openAI
        case .elevenLabs: .elevenLabs
        case .parakeetV3: .nvidia
        }
    }

    /// The line under the name in the list.
    var kind: String {
        if let sizeLabel { "On this iPhone · \(sizeLabel)" } else { "Cloud" }
    }

    /// One sentence at the top of the model's own screen.
    var summary: String {
        switch self {
        case .openAI:
            "OpenAI's speech model, in the cloud. You pay OpenAI for what you say, with your own key."
        case .elevenLabs:
            "ElevenLabs Scribe, in the cloud, with your own key. About $0.22 per hour of speech; the free plan includes 4.5 hours a month."
        case .parakeetV3:
            "Nvidia's Parakeet runs on this iPhone. Free after a 494 MB download. It knows 25 European languages, Ukrainian, Polish and English among them."
        case .whisperLargeTurbo:
            "Whisper Large Turbo runs on this iPhone. Free after a 632 MB download. It knows about a hundred languages."
        }
    }

    /// What the status symbol means, in words. VoiceOver reads this too.
    func statusText(_ status: SpeechModelStore.Status) -> String {
        switch status {
        case .ready: isOnDevice ? "Downloaded" : "Connected"
        case .notSetUp: isOnDevice ? "Not downloaded" : "Not connected"
        case .downloading(let progress): "Downloading \(Self.percent(progress))"
        case .preparing: "Preparing"
        case .failed(let message): message
        }
    }

    /// Said wherever a model is being prepared: on the main screen and on the model's own screen.
    /// Short enough for one line of the main screen's card on a small iPhone.
    static let preparingNote = "Once per update. Keep the app open."

    static func percent(_ progress: Double) -> String {
        "\(Int((min(max(progress, 0), 1) * 100).rounded(.down)))%"
    }
}
