import BackgroundTasks
import Foundation
import Testing
@testable import OpenDictation

/// The background window that prepares the model after an update, while the phone charges.
@MainActor
struct BackgroundPreparationTests {
    @Test func itOnlyAsksForAWindowWhileThePhoneCharges() {
        let request = BackgroundPreparation.request(notBefore: nil)

        #expect(request.identifier == BackgroundPreparation.identifier)
        #expect(request.requiresExternalPower)
        #expect(!request.requiresNetworkConnectivity)
        #expect(request.earliestBeginDate == nil)
    }

    @Test func afterAWindowTheNextOneWaits() {
        let next = Date(timeIntervalSinceNow: BackgroundPreparation.pause)
        #expect(BackgroundPreparation.request(notBefore: next).earliestBeginDate == next)
        #expect(BackgroundPreparation.pause >= 60 * 60)
    }

    /// Every request keeps the pause after the last window, so asking again when the app goes
    /// to the background or a dictation starts does not undo it.
    @Test func thePauseHoldsForEveryRequest() {
        let window = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let pause = BackgroundPreparation.pause

        #expect(BackgroundPreparation.notBefore(lastWindow: nil, now: window) == nil)
        #expect(BackgroundPreparation.notBefore(lastWindow: window, now: window.addingTimeInterval(60))
            == window.addingTimeInterval(pause))
        // Once the pause is over, any time will do.
        #expect(BackgroundPreparation.notBefore(lastWindow: window, now: window.addingTimeInterval(pause + 1)) == nil)
    }

    // MARK: - What a window does

    private final class World {
        var keys: Set<SpeechModel> = []
        var freeBytes: Int64 = 20_000_000_000
    }

    private let world = World()
    private let parakeet = FakeSpeechEngine(downloaded: true)

    private func makeStore(selected: SpeechModel = .parakeetV3, notes: PreparedModels = .scratch()) -> SpeechModelStore {
        SpeechModelStore(
            engines: [.parakeetV3: parakeet], selected: selected,
            hasKey: { [world] in world.keys.contains($0) }, save: { _ in }, prepared: notes,
            isInFront: { false }, freeBytes: { [world] in world.freeBytes })
    }

    @Test func aWindowAfterAnUpdateReportsSuccess() async {
        let store = makeStore()
        #expect(store.needsChargingWindow)

        #expect(await BackgroundPreparation.prepare(store))
        #expect(parakeet.preparations == 1)
        #expect(!store.needsChargingWindow)
    }

    /// The negative case: a failed load is reported as a failure, and a window is still wanted.
    @Test func aFailedLoadIsReportedAsAFailure() async {
        parakeet.planPreparing(failure: .failed("No room."))
        let store = makeStore()

        #expect(await !BackgroundPreparation.prepare(store))
        #expect(parakeet.preparations == 1)
        #expect(store.needsChargingWindow)
    }

    @Test func aWindowOnALowPhoneDoesNothingAndSaysSo() async {
        world.freeBytes = 300_000_000
        let store = makeStore()

        #expect(await !BackgroundPreparation.prepare(store))
        #expect(parakeet.preparations == 0)
    }

    @Test func noWindowIsWantedWithoutWork() async {
        // A cloud model, with its key saved.
        world.keys = [.openAI]
        #expect(!makeStore(selected: .openAI).needsChargingWindow)

        // The model in use, already prepared on this version.
        let notes = PreparedModels.scratch()
        notes.markPrepared(.parakeetV3)
        let store = makeStore(notes: notes)
        #expect(!store.needsChargingWindow)
        // A window that comes anyway has nothing to do, and that counts as done.
        #expect(await BackgroundPreparation.prepare(store))
        #expect(parakeet.preparations == 0)
    }

    /// iOS refuses a window whose name is not in the app's Info.plist, and gives none without
    /// the processing background mode.
    @Test func theAppIsAllowedToAskForIt() throws {
        let info = try #require(Bundle.main.infoDictionary)
        let names = try #require(info["BGTaskSchedulerPermittedIdentifiers"] as? [String])
        let modes = try #require(info["UIBackgroundModes"] as? [String])

        #expect(names.contains(BackgroundPreparation.identifier))
        #expect(modes.contains("processing"))
        // The microphone from the Action Button still needs this one.
        #expect(modes.contains("audio"))
    }
}
