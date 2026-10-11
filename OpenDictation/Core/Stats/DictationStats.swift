import Foundation

/// What the stats screens show: the log, added up as of one moment.
struct DictationStats: Equatable, Sendable {
    /// Every dictation in the log, by provider.
    var allTime: [SpeechModel: DictationTotals] = [:]
    /// The calendar month that "now" is in, by provider.
    var thisMonth: [SpeechModel: DictationTotals] = [:]
    /// The 7 times 24 hours up to "now".
    var lastSevenDays = DictationTotals()
    /// How many seconds a minute of speech takes to become text, for each provider that has
    /// been used enough to say.
    var secondsPerMinute: [SpeechModel: Double] = [:]

    var total: DictationTotals {
        allTime.values.reduce(into: DictationTotals()) { $0 += $1 }
    }

    var isEmpty: Bool { total.dictations == 0 }

    /// The providers that have been dictated with, in the order Settings lists them.
    var providers: [SpeechModel] {
        SpeechModel.allCases.filter { (allTime[$0]?.dictations ?? 0) > 0 }
    }

    // MARK: - Speed

    /// Speed is read off a provider's latest dictations only, so it follows the phone, the
    /// connection and the model as they are now.
    static let speedSample = 50
    /// With less speech than this there is nothing to go by: a short clip is mostly start-up time.
    static let speedNeedsAudioSeconds = 60.0

    /// Seconds of waiting per minute of speech over one provider's dictations (oldest first),
    /// or nil while there is too little speech to say.
    static func secondsPerMinute(of records: [DictationRecord]) -> Double? {
        let latest = records.suffix(speedSample)
        let audio = latest.reduce(0) { $0 + $1.audioSeconds }
        guard audio >= speedNeedsAudioSeconds else { return nil }
        return latest.reduce(0) { $0 + $1.speechSeconds } * 60 / audio
    }
}

extension DictationStats {
    /// - Parameters:
    ///   - now: decides which month is "this month" and where the last 7 days begin.
    ///   - calendar: decides where a month begins.
    init(_ log: DictationLog.Contents, now: Date, calendar: Calendar) {
        let thisMonthName = DictationLog.Contents.month(of: now, in: calendar)
        for (month, providers) in log.months {
            for (provider, totals) in providers {
                allTime[provider, default: DictationTotals()] += totals
                if month == thisMonthName {
                    thisMonth[provider, default: DictationTotals()] += totals
                }
            }
        }

        let weekAgo = now.addingTimeInterval(-7 * 24 * 3600)
        for record in log.records {
            allTime[record.provider, default: DictationTotals()].add(record)
            if DictationLog.Contents.month(of: record.date, in: calendar) == thisMonthName {
                thisMonth[record.provider, default: DictationTotals()].add(record)
            }
            if record.date > weekAgo {
                lastSevenDays.add(record)
            }
        }

        for provider in SpeechModel.allCases {
            secondsPerMinute[provider] = Self.secondsPerMinute(of: log.records.filter { $0.provider == provider })
        }
    }
}
