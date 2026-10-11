#if DEBUG
import Foundation

extension DictationLog {
    /// A log of made-up dictations, for screenshots of the stats screens (`-sampleStats`).
    /// It writes to a temporary file, so the real stats are left alone.
    static func samples(now: Date = Date()) -> DictationLog {
        let calendar = phoneCalendar
        var contents = Contents()
        for record in sampleRecords(endingAt: now) {
            contents.add(record, limit: 2_000, calendar: calendar)
        }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("sample-stats.json")
        return DictationLog(fileURL: file, calendar: calendar, contents: contents)
    }

    /// Fourteen months of dictations, oldest first, the same on every run: a cloud provider
    /// at first, the on-device models lately.
    private static func sampleRecords(endingAt now: Date) -> [DictationRecord] {
        var records: [DictationRecord] = []
        var index = 0
        for daysAgo in stride(from: 420, through: 0, by: -1) {
            for turn in 0..<[3, 0, 5, 2, 4, 1, 6][daysAgo % 7] {
                index += 1
                let provider: SpeechModel = switch daysAgo {
                case 300...: .openAI
                case 120...: index % 3 == 0 ? .elevenLabs : .openAI
                default: index % 4 == 0 ? .whisperLargeTurbo : index % 9 == 0 ? .openAI : .parakeetV3
                }
                let audio = 6 + Double(index * 37 % 41)
                let words = Int(audio * 2.4)
                let speech: Double = switch provider {
                case .openAI: 0.9 + audio * 0.035
                case .elevenLabs: 1.1 + audio * 0.05
                case .parakeetV3: 0.5 + audio * 0.06
                case .whisperLargeTurbo: 1.6 + audio * 0.3
                }
                let hasTextStep = index % 3 != 0
                records.append(DictationRecord(
                    date: now.addingTimeInterval(-Double(daysAgo) * 86_400 - Double(turn) * 2_820 - 600),
                    provider: provider, audioSeconds: audio, speechSeconds: speech,
                    textSeconds: hasTextStep ? 1.2 + Double(index % 5) * 0.15 : nil, words: words,
                    inputTokens: hasTextStep ? 260 + words * 7 / 5 : nil,
                    outputTokens: hasTextStep ? words * 4 / 3 : nil))
            }
        }
        return records.sorted { $0.date < $1.date }
    }
}
#endif
