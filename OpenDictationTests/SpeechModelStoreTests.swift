import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct SpeechModelStoreTests {
    /// The saved keys and the remembered choice, standing in for the Keychain and UserDefaults.
    private final class World {
        var keys: Set<SpeechModel> = [.openAI]
        var remembered: SpeechModel?
    }

    private let world = World()
    private let parakeet = FakeSpeechEngine()
    private let whisper = FakeSpeechEngine()

    private func makeStore(selected: SpeechModel = .openAI) -> SpeechModelStore {
        SpeechModelStore(
            engines: [.parakeetV3: parakeet, .whisperLargeTurbo: whisper],
            selected: selected,
            hasKey: { [world] in world.keys.contains($0) },
            save: { [world] in world.remembered = $0 },
            prepared: .scratch())
    }

    /// Progress hops threads before it shows, so a test has to give it a moment.
    private func wait(for store: SpeechModelStore, toShow status: SpeechModelStore.Status, of model: SpeechModel) async {
        for _ in 0..<400 where store.status(of: model) != status {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    // MARK: - What is set up

    @Test func statusComesFromKeysAndFiles() {
        let store = SpeechModelStore(
            engines: [.parakeetV3: FakeSpeechEngine(downloaded: true), .whisperLargeTurbo: whisper],
            selected: .openAI,
            hasKey: { $0 == .openAI },
            save: { _ in },
            prepared: .scratch())

        #expect(store.status(of: .openAI) == .ready)
        #expect(store.status(of: .elevenLabs) == .notSetUp)
        #expect(store.status(of: .parakeetV3) == .ready)
        #expect(store.status(of: .whisperLargeTurbo) == .notSetUp)
    }

    @Test func savingAKeyConnectsButNeverSwitches() {
        let store = makeStore()
        world.keys.insert(.elevenLabs)
        store.keysChanged()

        #expect(store.status(of: .elevenLabs) == .ready)
        #expect(store.selected == .openAI)
    }

    // MARK: - Downloads

    @Test func downloadShowsProgressThenIsReady() async {
        let store = makeStore()
        parakeet.plan(steps: [0.25, 0.5], waitsForRelease: true)

        let task = store.download(.parakeetV3)
        await wait(for: store, toShow: .downloading(progress: 0.5), of: .parakeetV3)
        #expect(store.status(of: .parakeetV3) == .downloading(progress: 0.5))

        parakeet.release()
        await task?.value
        #expect(store.status(of: .parakeetV3) == .ready)
        // Finishing a download never switches by itself.
        #expect(store.selected == .openAI)
        #expect(store.engine == nil)
    }

    @Test func aFirstDownloadIsPutInUseWhenNothingElseCanListen() async {
        world.keys = []
        let store = makeStore()
        #expect(!store.canListen)

        await store.download(.whisperLargeTurbo)?.value
        #expect(store.selected == .whisperLargeTurbo)
        #expect(store.canListen)
        #expect(world.remembered == .whisperLargeTurbo)
    }

    @Test func progressNeverGoesBackwards() async {
        let store = makeStore()
        parakeet.plan(steps: [0.6, 0.2], waitsForRelease: true)

        let task = store.download(.parakeetV3)
        await wait(for: store, toShow: .downloading(progress: 0.6), of: .parakeetV3)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(store.status(of: .parakeetV3) == .downloading(progress: 0.6))

        parakeet.release()
        await task?.value
    }

    @Test func failedDownloadShowsWhyAndCanBeTriedAgain() async {
        let store = makeStore()
        parakeet.plan(steps: [0.3], failure: .failed("The download did not finish."))

        await store.download(.parakeetV3)?.value
        #expect(store.status(of: .parakeetV3) == .failed("The download did not finish."))

        parakeet.plan(steps: [1])
        await store.download(.parakeetV3)?.value
        #expect(store.status(of: .parakeetV3) == .ready)
    }

    @Test func cancelledDownloadGoesBackToNotSetUp() async {
        let store = makeStore()
        parakeet.plan(steps: [0.4], waitsForRelease: true)

        let task = store.download(.parakeetV3)
        await wait(for: store, toShow: .downloading(progress: 0.4), of: .parakeetV3)
        store.cancelDownload(.parakeetV3)
        parakeet.release()
        await task?.value

        #expect(store.status(of: .parakeetV3) == .notSetUp)
        #expect(!parakeet.isDownloaded)
    }

    // MARK: - Which one is in use

    @Test func onlyAReadyModelCanBePicked() async {
        let store = makeStore()
        store.select(.parakeetV3)
        store.select(.elevenLabs)
        #expect(store.selected == .openAI)

        parakeet.plan(steps: [1])
        await store.download(.parakeetV3)?.value
        store.select(.parakeetV3)

        #expect(store.selected == .parakeetV3)
        #expect(world.remembered == .parakeetV3)
        #expect(store.engine as? FakeSpeechEngine === parakeet)
    }

    @Test func cloudModelsHaveNoEngine() {
        world.keys = [.openAI, .elevenLabs]
        let store = makeStore(selected: .elevenLabs)

        #expect(store.selected == .elevenLabs)
        #expect(store.canListen)
        #expect(store.engine == nil)
    }

    @Test func deletingTheModelInUseFallsBackToOpenAI() {
        let downloaded = FakeSpeechEngine(downloaded: true)
        let store = SpeechModelStore(
            engines: [.parakeetV3: downloaded],
            selected: .parakeetV3,
            hasKey: { _ in false },
            save: { [world] in world.remembered = $0 },
            prepared: .scratch())
        #expect(store.selected == .parakeetV3)

        store.delete(.parakeetV3)

        #expect(store.status(of: .parakeetV3) == .notSetUp)
        #expect(store.selected == .openAI)
        #expect(store.fellBackFrom == .parakeetV3)
        #expect(world.remembered == .openAI)
        #expect(store.engine == nil)
        // OpenAI has no key here, so the main screen has to ask for it.
        #expect(!store.canListen)
    }

    @Test func removingTheKeyInUseFallsBackToOpenAI() {
        world.keys = [.openAI, .elevenLabs]
        let store = makeStore(selected: .elevenLabs)

        world.keys.remove(.elevenLabs)
        store.keysChanged()

        #expect(store.selected == .openAI)
        #expect(store.fellBackFrom == .elevenLabs)
        #expect(store.canListen)

        // Picking something by hand clears the note about what happened.
        store.select(.openAI)
        #expect(store.fellBackFrom == nil)
    }

    @Test func openAIStaysInUseWithoutItsKey() {
        let store = makeStore()
        world.keys.remove(.openAI)
        store.keysChanged()

        #expect(store.selected == .openAI)
        #expect(store.fellBackFrom == nil)
        #expect(!store.canListen)
    }

    @Test func aChoiceRestoredWithoutItsFilesFallsBack() {
        let store = makeStore(selected: .whisperLargeTurbo)

        #expect(store.selected == .openAI)
        #expect(store.fellBackFrom == .whisperLargeTurbo)
        #expect(world.remembered == .openAI)
    }
}

/// The words Settings shows next to each status.
struct SpeechModelDisplayTests {
    @Test func statusReadsAsWords() {
        #expect(SpeechModel.openAI.statusText(.ready) == "Connected")
        #expect(SpeechModel.elevenLabs.statusText(.notSetUp) == "Not connected")
        #expect(SpeechModel.parakeetV3.statusText(.ready) == "Downloaded")
        #expect(SpeechModel.whisperLargeTurbo.statusText(.notSetUp) == "Not downloaded")
        #expect(SpeechModel.parakeetV3.statusText(.downloading(progress: 0.429)) == "Downloading 42%")
        #expect(SpeechModel.whisperLargeTurbo.statusText(.preparing) == "Preparing")
        #expect(SpeechModel.parakeetV3.statusText(.failed("No space left.")) == "No space left.")
    }

    @Test func cloudAndOnDeviceAreToldApart() {
        #expect(SpeechModel.allCases.map(\.isOnDevice) == [false, false, true, true])
        #expect(SpeechModel.elevenLabs.kind == "Cloud")
        #expect(SpeechModel.parakeetV3.kind == "On this iPhone · 494 MB")
        #expect(SpeechModel.openAI.makeEngine() == nil)
        #expect(SpeechModel.elevenLabs.makeEngine() == nil)
        // Wrapped, so that it waits its turn with the other model.
        #expect(SpeechModel.parakeetV3.makeEngine() is OneAtATime<ParakeetEngine>)
        #expect(SpeechModel.whisperLargeTurbo.makeEngine() is OneAtATime<WhisperEngine>)
    }

    @Test func wordsToGetRightAreCounted() {
        #expect(VocabularyView.summary(of: " \n\n") == "None")
        #expect(VocabularyView.summary(of: "Kyiv") == "1 word")
        #expect(VocabularyView.summary(of: "Kyiv\n\n Yako \n") == "2 words")
    }
}
