import Foundation
import Testing
@testable import OpenDictation

/// After an update the store loads the model in use once, with the app open, so that the slow
/// first load does not land on a dictation.
@MainActor
struct ModelPreparationTests {
    /// Whether the app is on the screen, and which keys are saved.
    private final class World {
        var isInFront = true
        var keys: Set<SpeechModel> = []
    }

    private let world = World()
    private let parakeet = FakeSpeechEngine(downloaded: true)
    private let whisper = FakeSpeechEngine(downloaded: true)
    /// Nothing has been prepared yet, as after an update.
    private let notes = PreparedModels.scratch()

    private func makeStore(selected: SpeechModel = .parakeetV3) -> SpeechModelStore {
        SpeechModelStore(
            engines: [.parakeetV3: parakeet, .whisperLargeTurbo: whisper],
            selected: selected,
            hasKey: { [world] in world.keys.contains($0) },
            save: { _ in },
            prepared: notes,
            isInFront: { [world] in world.isInFront })
    }

    /// A preparation that was started by something else has to be given a moment to show.
    private func wait(until isTrue: () -> Bool) async {
        for _ in 0..<400 where !isTrue() {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    // MARK: - When it runs

    @Test func theModelInUseIsPreparedOnceAfterAnUpdate() async {
        let store = makeStore()
        let hold = Latch()
        parakeet.planPreparing(hold: hold)

        let task = store.prepareIfNeeded()
        #expect(store.status(of: .parakeetV3) == .preparing)
        #expect(store.isPreparing)
        // Asking again while it runs starts nothing new.
        _ = store.prepareIfNeeded()

        hold.open()
        await task?.value
        #expect(store.status(of: .parakeetV3) == .ready)
        #expect(!store.isPreparing)
        #expect(!notes.needsPreparing(.parakeetV3))

        // The next time the app comes to the front there is nothing left to do.
        #expect(store.prepareIfNeeded() == nil)
        #expect(parakeet.preparations == 1)
    }

    @Test func aModelThatWasPreparedOnThisBuildIsLeftAlone() {
        notes.markPrepared(.parakeetV3)
        let store = makeStore()

        #expect(store.prepareIfNeeded() == nil)
        #expect(store.status(of: .parakeetV3) == .ready)
        #expect(parakeet.preparations == 0)
    }

    @Test func onlyTheModelInUseIsPrepared() async {
        let store = makeStore()

        await store.prepareIfNeeded()?.value
        #expect(parakeet.preparations == 1)
        #expect(whisper.preparations == 0)
        #expect(notes.needsPreparing(.whisperLargeTurbo))
    }

    @Test func aCloudModelInUseNeedsNothing() {
        world.keys = [.openAI]
        let store = makeStore(selected: .openAI)

        #expect(store.prepareIfNeeded() == nil)
        #expect(parakeet.preparations == 0)
        #expect(whisper.preparations == 0)
    }

    @Test func nothingIsPreparedWhileTheAppIsNotInFront() async {
        let store = makeStore()
        world.isInFront = false
        #expect(store.prepareIfNeeded() == nil)
        #expect(parakeet.preparations == 0)

        // Back on the screen, it starts.
        world.isInFront = true
        await store.prepareIfNeeded()?.value
        #expect(parakeet.preparations == 1)
    }

    @Test func nothingIsPreparedWhileADownloadRuns() async {
        whisper.plan(steps: [0.5], waitsForRelease: true)
        try? whisper.delete()
        let store = makeStore()

        let download = store.download(.whisperLargeTurbo)
        #expect(store.prepareIfNeeded() == nil)
        #expect(parakeet.preparations == 0)

        // When the download has ended, the model in use gets its turn by itself.
        whisper.release()
        await download?.value
        await wait { !notes.needsPreparing(.parakeetV3) }
        #expect(parakeet.preparations == 1)
        // The download loaded its own model, so that one needs nothing more.
        #expect(whisper.preparations == 0)
        #expect(!notes.needsPreparing(.whisperLargeTurbo))
    }

    @Test func aFreshDownloadCountsAsPrepared() async {
        try? parakeet.delete()
        let store = makeStore(selected: .openAI)
        parakeet.plan(steps: [1])

        // Nothing could listen, so the new model is put in use as well.
        await store.download(.parakeetV3)?.value
        #expect(store.selected == .parakeetV3)
        #expect(!notes.needsPreparing(.parakeetV3))
        #expect(store.prepareIfNeeded() == nil)
        #expect(parakeet.preparations == 0)
    }

    @Test func puttingAnotherDownloadedModelInUsePreparesIt() async {
        notes.markPrepared(.parakeetV3)
        let store = makeStore()

        store.select(.whisperLargeTurbo)
        #expect(store.status(of: .whisperLargeTurbo) == .preparing)
        await wait { !notes.needsPreparing(.whisperLargeTurbo) }
        #expect(whisper.preparations == 1)
        #expect(parakeet.preparations == 0)
    }

    @Test func aModelPutInUseDuringAPreparationIsPreparedNext() async {
        let store = makeStore()
        let hold = Latch()
        parakeet.planPreparing(hold: hold)

        let first = store.prepareIfNeeded()
        store.select(.whisperLargeTurbo)
        // One at a time: the second waits for the first to end.
        #expect(store.status(of: .whisperLargeTurbo) == .ready)
        #expect(whisper.preparations == 0)

        hold.open()
        await first?.value
        await wait { !notes.needsPreparing(.whisperLargeTurbo) }
        #expect(whisper.preparations == 1)
        #expect(!notes.needsPreparing(.parakeetV3))
    }

    // MARK: - While it runs

    @Test func aModelThatIsBeingPreparedCanStillBeUsed() async {
        world.keys = [.openAI]
        let store = makeStore()
        let hold = Latch()
        parakeet.planPreparing(hold: hold)

        let task = store.prepareIfNeeded()
        #expect(store.canListen)
        #expect(store.engine as? FakeSpeechEngine === parakeet)
        #expect(SpeechModelStore.Status.preparing.isUsable)

        // It can be picked again after a change of mind, but not downloaded or deleted meanwhile.
        store.select(.openAI)
        #expect(!store.isPreparing)
        store.select(.parakeetV3)
        #expect(store.selected == .parakeetV3)
        #expect(store.download(.parakeetV3) == nil)
        store.delete(.parakeetV3)
        #expect(parakeet.isDownloaded)

        hold.open()
        await task?.value
        #expect(store.status(of: .parakeetV3) == .ready)
        #expect(parakeet.preparations == 1)
    }

    @Test func onlyAModelThatIsSetUpIsUsable() {
        #expect(SpeechModelStore.Status.ready.isUsable)
        #expect(SpeechModelStore.Status.preparing.isUsable)
        #expect(!SpeechModelStore.Status.notSetUp.isUsable)
        #expect(!SpeechModelStore.Status.downloading(progress: 0.9).isUsable)
        #expect(!SpeechModelStore.Status.failed("No space left.").isUsable)
    }

    @Test func aDictationThatStartsMeanwhileWaitsAndThenWorks() async throws {
        // As the app wires it: the store's engines wait their turn.
        let engine = OneAtATime(parakeet, turns: ModelTurns())
        let store = SpeechModelStore(
            engines: [.parakeetV3: engine], selected: .parakeetV3,
            hasKey: { _ in false }, save: { _ in }, prepared: notes, isInFront: { true })
        let hold = Latch()
        parakeet.planPreparing(hold: hold)

        let preparing = store.prepareIfNeeded()
        await wait { parakeet.events == ["prepare began"] }
        let inUse = try #require(store.engine)
        let dictation = Task { try await inUse.transcribe(fileURL: URL(fileURLWithPath: "/dev/null"), languageCode: "") }
        try? await Task.sleep(for: .milliseconds(60))
        // No second copy of the model next to the one being prepared.
        #expect(parakeet.events == ["prepare began"])

        hold.open()
        await preparing?.value
        #expect(try await dictation.value == "fake")
        #expect(parakeet.events == ["prepare began", "prepare ended", "transcribe began", "transcribe ended"])
    }

    // MARK: - When it goes wrong

    @Test func aFailedPreparationIsTriedAgainAndDoesNotStopDictation() async throws {
        let store = makeStore()
        parakeet.planPreparing(failure: .failed("No room."))

        await store.prepareIfNeeded()?.value
        // Nothing is written down, so it still counts as not prepared.
        #expect(notes.needsPreparing(.parakeetV3))
        #expect(store.status(of: .parakeetV3) == .ready)
        #expect(store.selected == .parakeetV3)
        #expect(store.canListen)
        let engine = try #require(store.engine)
        #expect(try await engine.transcribe(fileURL: URL(fileURLWithPath: "/dev/null"), languageCode: "") == "fake")

        // The next time the app comes to the front it is tried again.
        parakeet.planPreparing()
        await store.prepareIfNeeded()?.value
        #expect(parakeet.preparations == 2)
        #expect(!notes.needsPreparing(.parakeetV3))
    }

    @Test func deletingAModelForgetsThatItWasPrepared() async {
        world.keys = [.openAI]
        let store = makeStore()
        await store.prepareIfNeeded()?.value
        #expect(!notes.needsPreparing(.parakeetV3))

        store.delete(.parakeetV3)
        #expect(store.status(of: .parakeetV3) == .notSetUp)
        #expect(notes.needsPreparing(.parakeetV3))
    }
}
