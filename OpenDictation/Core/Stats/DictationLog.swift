import Foundation

/// The numbers of past dictations, in one small file on the phone and nowhere else.
/// An actor, so that reading and writing the file never holds a dictation up.
actor DictationLog {
    /// The app's own log. A DEBUG launch with `-sampleStats` shows made-up numbers instead, for
    /// screenshots, and leaves the real file alone.
    static let shared: DictationLog = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-sampleStats") { return .samples() }
        #endif
        return DictationLog()
    }()

    private let fileURL: URL
    private let limit: Int
    private let calendar: Calendar
    /// Read from the file the first time it is asked for.
    private var contents: Contents?

    /// - Parameters:
    ///   - limit: how many dictations are kept one by one. Older ones live on as month totals.
    ///   - calendar: decides where a month begins. Tests pass a fixed one.
    ///   - contents: what the log starts with, in place of what the file holds.
    init(
        fileURL: URL = DictationLog.defaultFileURL, limit: Int = 2_000,
        calendar: Calendar = DictationLog.phoneCalendar, contents: Contents? = nil
    ) {
        self.fileURL = fileURL
        self.limit = limit
        self.calendar = calendar
        self.contents = contents
    }

    /// For the dictation itself: it returns at once, and nothing that goes wrong with the stats
    /// can reach the dictation. Nil, a dictation that could not be measured, is left out.
    nonisolated func record(_ record: DictationRecord?) {
        guard let record else { return }
        Task { await add(record) }
    }

    func add(_ record: DictationRecord) {
        var contents = loaded()
        contents.add(record, limit: limit, calendar: calendar)
        self.contents = contents
        save(contents)
    }

    /// Everything added up as of `now`, which decides what "this month" and "the last 7 days" are.
    func stats(now: Date = Date()) -> DictationStats {
        DictationStats(loaded(), now: now, calendar: calendar)
    }

    func clear() {
        contents = Contents()
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - The file

    private func loaded() -> Contents {
        if let contents { return contents }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // A file that cannot be read counts as no file: the stats start again from zero.
        let saved = (try? Data(contentsOf: fileURL)).flatMap { try? decoder.decode(Contents.self, from: $0) }
        let contents = saved ?? Contents()
        self.contents = contents
        return contents
    }

    /// A failure here costs the stats one dictation and nothing else.
    private func save(_ contents: Contents) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(contents) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appendingPathComponent("stats.json")
    }

    /// Month names in the file are always Gregorian ("2026-10"), whatever calendar the phone
    /// shows, and a month begins at midnight where the phone is.
    static var phoneCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }
}

extension DictationLog {
    /// What the file holds: the newer dictations one by one, the older ones added up by month.
    /// That keeps the file small however long the app is used.
    struct Contents: Codable, Equatable, Sendable {
        /// Oldest first.
        var records: [DictationRecord] = []
        /// By month, such as "2026-10", and then by provider.
        var months: [String: [SpeechModel: DictationTotals]] = [:]

        /// Adds a dictation. Any that are now over a year old, or have more than `limit` newer
        /// ones after them, move into their month's totals, so no number is ever lost.
        mutating func add(_ record: DictationRecord, limit: Int, calendar: Calendar) {
            records.append(record)
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: record.date) ?? .distantPast
            let tooMany = records.count - limit
            var kept: [DictationRecord] = []
            for (index, old) in records.enumerated() {
                if index < tooMany || old.date < yearAgo {
                    let month = Self.month(of: old.date, in: calendar)
                    months[month, default: [:]][old.provider, default: DictationTotals()].add(old)
                } else {
                    kept.append(old)
                }
            }
            records = kept
        }

        static func month(of date: Date, in calendar: Calendar) -> String {
            let parts = calendar.dateComponents([.year, .month], from: date)
            return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
        }
    }
}
