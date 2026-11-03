import Foundation
import Testing
@testable import OpenDictation

/// A result copied in the background is copied once more when the app comes to the front,
/// but never over something the user copied since.
struct ClipboardRetryTests {
    private let copiedAt = Date(timeIntervalSince1970: 1_800_000_000)

    private var retry: ClipboardRetry {
        ClipboardRetry(text: "Hello", date: copiedAt, changeCount: 7)
    }

    @Test func aFreshResultIsCopiedAgain() {
        #expect(retry.shouldCopyAgain(now: copiedAt.addingTimeInterval(30), changeCount: 7))
    }

    /// The user pasted the dictation, copied a link in Safari, then opened Open Dictation.
    @Test func somethingCopiedSinceIsNeverReplaced() {
        #expect(!retry.shouldCopyAgain(now: copiedAt.addingTimeInterval(30), changeCount: 8))
    }

    @Test func anOldResultIsLeftAlone() {
        let limit = ClipboardRetry.freshFor
        #expect(retry.shouldCopyAgain(now: copiedAt.addingTimeInterval(limit - 1), changeCount: 7))
        #expect(!retry.shouldCopyAgain(now: copiedAt.addingTimeInterval(limit), changeCount: 7))
    }
}
