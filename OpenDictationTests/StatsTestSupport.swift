import Foundation
@testable import OpenDictation

/// What the stats tests share: fixed dates, a fixed calendar and short ways to make a dictation.
enum StatsTestSupport {
    /// Months begin at midnight UTC in the tests, wherever they run.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// "2026-10-11T12:00:00Z"
    static func date(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }

    /// A log with a file of its own, so the app's real stats are never touched.
    static func makeLog(fileURL: URL = newFileURL(), limit: Int = 2_000) -> DictationLog {
        DictationLog(fileURL: fileURL, limit: limit, calendar: calendar)
    }

    static func newFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("stats-\(UUID().uuidString).json")
    }

    /// What the log wrote, read straight from its file.
    static func saved(at fileURL: URL) throws -> DictationLog.Contents {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DictationLog.Contents.self, from: Data(contentsOf: fileURL))
    }
}

extension DictationRecord {
    /// Half a minute of speech that took three seconds to become 60 words, unless said otherwise.
    static func sample(
        _ date: String, _ provider: SpeechModel = .openAI, audio: Double = 30, speech: Double = 3,
        text: Double? = nil, words: Int = 60, input: Int? = nil, output: Int? = nil
    ) -> DictationRecord {
        DictationRecord(
            date: StatsTestSupport.date(date), provider: provider, audioSeconds: audio, speechSeconds: speech,
            textSeconds: text, words: words, inputTokens: input, outputTokens: output)
    }
}
