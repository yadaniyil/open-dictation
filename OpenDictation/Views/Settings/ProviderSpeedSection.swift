import SwiftUI

/// How fast this provider has been on this phone, in one plain line. It comes from the user's
/// own dictations, so it stays empty until there has been about a minute of speech.
struct ProviderSpeedSection: View {
    let model: SpeechModel
    var log: DictationLog = .shared

    /// Nil until the log has been read, which takes a moment at most.
    @State private var stats: DictationStats?

    var body: some View {
        Section {
            Text(stats == nil ? " " : StatsFormat.speedSentence(secondsPerMinute: speed))
                .foregroundStyle(speed == nil ? .secondary : .primary)
                .accessibilityIdentifier("providerSpeed")
                // Read again when a dictation ends while this screen is showing.
                .task(id: DictationController.shared.phase) { stats = await log.stats() }
        } header: {
            Text("Speed")
        } footer: {
            if stats != nil {
                Text(footer)
            }
        }
    }

    private var speed: Double? { stats?.secondsPerMinute[model] }

    private var footer: String {
        if speed == nil {
            "It shows once you have dictated for about a minute with \(model.name)."
        } else if model.isOnDevice {
            "Measured on this iPhone, from your own dictations."
        } else {
            "Measured on this iPhone, from your own dictations. Your connection plays a part."
        }
    }
}
