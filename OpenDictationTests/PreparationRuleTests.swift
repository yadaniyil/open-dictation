import Foundation
import Testing
@testable import OpenDictation

/// The rule for when the model in use is loaded once ahead of a dictation.
struct PreparationRuleTests {
    typealias Rule = PreparationRule

    /// Plenty of room, unless a test says otherwise.
    private static let roomy: Int64 = 20_000_000_000

    /// The rule for a model on the phone that is downloaded, with the app on the screen and room
    /// to spare. Each test changes one thing.
    private func decide(
        _ moment: Rule.Moment,
        status: SpeechModelStore.Status? = .ready,
        needsPreparing: Bool = true,
        isBusy: Bool = false,
        isInFront: Bool = true,
        freeBytes: Int64 = roomy
    ) -> Rule.Decision {
        Rule.decide(
            moment, status: status, needsPreparing: needsPreparing, isBusy: isBusy,
            isInFront: isInFront, freeBytes: { freeBytes })
    }

    @Test(arguments: [Rule.Moment.appInFront, .chargingWindow, .dictationStarted])
    func aNewVersionMeansPreparingAgain(moment: Rule.Moment) {
        #expect(decide(moment) == .prepare)
    }

    /// The negative case: on the version it was prepared on there is no work, at no moment, and
    /// the phone's free space is not even asked.
    @Test(arguments: [Rule.Moment.appInFront, .chargingWindow, .dictationStarted])
    func theSameVersionMeansNoWork(moment: Rule.Moment) {
        var askedForSpace = false
        let decision = Rule.decide(
            moment, status: .ready, needsPreparing: false, isBusy: false, isInFront: true,
            freeBytes: { askedForSpace = true; return Self.roomy })

        #expect(decision == .skip(.alreadyPrepared))
        #expect(!askedForSpace)
    }

    @Test(arguments: [SpeechModelStore.Status.notSetUp, .downloading(progress: 0.4), .failed("Network lost.")])
    func aModelThatIsNotDownloadedYetIsLeftAlone(status: SpeechModelStore.Status) {
        for moment in [Rule.Moment.appInFront, .chargingWindow, .dictationStarted] {
            #expect(decide(moment, status: status) == .skip(.notDownloaded))
        }
    }

    @Test func aCloudModelNeedsNothing() {
        #expect(decide(.appInFront, status: nil) == .skip(.cloudModel))
        #expect(decide(.chargingWindow, status: nil) == .skip(.cloudModel))
        #expect(decide(.dictationStarted, status: nil) == .skip(.cloudModel))
    }

    @Test func oneLoadAtATime() {
        #expect(decide(.appInFront, status: .preparing) == .skip(.busy))
        #expect(decide(.chargingWindow, isBusy: true) == .skip(.busy))
        #expect(decide(.dictationStarted, isBusy: true) == .skip(.busy))
    }

    @Test func onTheScreenOnlyWhileTheAppIsThere() {
        #expect(decide(.appInFront, isInFront: false) == .skip(.notInFront))
        // The other two moments come while the app is in the background.
        #expect(decide(.chargingWindow, isInFront: false) == .prepare)
        #expect(decide(.dictationStarted, isInFront: false) == .prepare)
    }

    @Test func lowSpaceStopsAnExtraLoad() {
        let tight = Rule.neededFreeBytes - 1
        #expect(decide(.appInFront, freeBytes: tight) == .skip(.lowStorage))
        #expect(decide(.chargingWindow, freeBytes: tight) == .skip(.lowStorage))
        #expect(decide(.appInFront, freeBytes: Rule.neededFreeBytes) == .prepare)
        // A dictation loads the model anyway, so starting that load sooner needs no extra room.
        #expect(decide(.dictationStarted, freeBytes: tight) == .prepare)
    }
}
