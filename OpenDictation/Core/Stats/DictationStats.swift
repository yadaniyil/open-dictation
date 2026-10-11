import Foundation

/// What the stats screens show: the log, added up as of one moment.
struct DictationStats: Equatable, Sendable {
    /// Every dictation in the log, by provider.
    var allTime: [SpeechModel: DictationTotals] = [:]
    /// The calendar month that "now" is in, by provider.
    var thisMonth: [SpeechModel: DictationTotals] = [:]
    /// The 7 times 24 hours up to "now".
    var lastSevenDays = DictationTotals()

    var total: DictationTotals {
        allTime.values.reduce(into: DictationTotals()) { $0 += $1 }
    }

    var isEmpty: Bool { total.dictations == 0 }
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
    }
}
