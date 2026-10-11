import ActivityKit
import Foundation

/// What the Live Activity (Dynamic Island + Lock Screen) shows while dictating.
struct DictationActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        enum Phase: String, Codable, Hashable, Sendable {
            case recording
            case transcribing
            case copied
            case failed
        }

        var phase: Phase
        var startedAt: Date
        /// A short preview of the text, or the error message.
        var detail: String?
    }
}
