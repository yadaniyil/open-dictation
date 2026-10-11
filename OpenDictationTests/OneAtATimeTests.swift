import Foundation
import Testing
@testable import OpenDictation

/// Preparing a model and transcribing with it must never run side by side.
struct OneAtATimeTests {
    private let file = URL(fileURLWithPath: "/dev/null")

    /// Gives a task that should be waiting the time to do the wrong thing.
    private func aMoment() async {
        try? await Task.sleep(for: .milliseconds(60))
    }

    private func wait(for fake: FakeSpeechEngine, toReach events: [String]) async {
        for _ in 0..<400 where fake.events != events {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func aDictationWaitsForThePreparationToEnd() async throws {
        let fake = FakeSpeechEngine(downloaded: true)
        let engine = OneAtATime(fake, turns: ModelTurns())
        let hold = Latch()
        fake.planPreparing(hold: hold)

        let preparing = Task { try await engine.prepare() }
        await wait(for: fake, toReach: ["prepare began"])
        let dictation = Task { try await engine.transcribe(fileURL: file, languageCode: "") }
        await aMoment()
        // The model is loaded once, not twice: the dictation has not touched it yet.
        #expect(fake.events == ["prepare began"])

        hold.open()
        try await preparing.value
        // It waited, and then it worked.
        #expect(try await dictation.value == "fake")
        #expect(fake.events == ["prepare began", "prepare ended", "transcribe began", "transcribe ended"])
    }

    @Test func aPreparationWaitsForTheDictationToEnd() async throws {
        let fake = FakeSpeechEngine(downloaded: true)
        let engine = OneAtATime(fake, turns: ModelTurns())
        let hold = Latch()
        fake.planTranscribing(hold: hold)

        let dictation = Task { try await engine.transcribe(fileURL: file, languageCode: "") }
        await wait(for: fake, toReach: ["transcribe began"])
        let preparing = Task { try await engine.prepare() }
        await aMoment()
        #expect(fake.events == ["transcribe began"])

        hold.open()
        _ = try await dictation.value
        try await preparing.value
        #expect(fake.events == ["transcribe began", "transcribe ended", "prepare began", "prepare ended"])
    }

    @Test func twoModelsTakeTurnsToo() async throws {
        let turns = ModelTurns()
        let parakeet = FakeSpeechEngine(downloaded: true)
        let whisper = FakeSpeechEngine(downloaded: true)
        let hold = Latch()
        whisper.planPreparing(hold: hold)

        let preparing = Task { try await OneAtATime(whisper, turns: turns).prepare() }
        await wait(for: whisper, toReach: ["prepare began"])
        let dictation = Task { try await OneAtATime(parakeet, turns: turns).transcribe(fileURL: file, languageCode: "") }
        await aMoment()
        #expect(parakeet.events.isEmpty)

        hold.open()
        try await preparing.value
        #expect(try await dictation.value == "fake")
    }

    @Test func aFailedPreparationHandsTheTurnOn() async throws {
        let fake = FakeSpeechEngine(downloaded: true)
        let engine = OneAtATime(fake, turns: ModelTurns())
        fake.planPreparing(failure: .failed("No room."))

        await #expect(throws: LocalSpeechError.failed("No room.")) { try await engine.prepare() }
        #expect(try await engine.transcribe(fileURL: file, languageCode: "") == "fake")
    }

    @Test func turnsComeInTheOrderTheyWereAskedFor() async {
        let turns = ModelTurns()
        let hold = Latch()
        let order = Order()

        let first = Task {
            await turns.run {
                await hold.wait()
                order.add(1)
            }
        }
        await aMoment()
        let second = Task { await turns.run { order.add(2) } }
        await aMoment()
        let third = Task { await turns.run { order.add(3) } }
        await aMoment()
        #expect(order.all.isEmpty)

        hold.open()
        _ = await (first.value, second.value, third.value)
        #expect(order.all == [1, 2, 3])
    }

    @Test func everythingButTheLoadsGoesStraightToTheEngine() async throws {
        let fake = FakeSpeechEngine()
        let engine = OneAtATime(fake, turns: ModelTurns())
        #expect(!engine.isDownloaded)

        fake.plan(steps: [1])
        try await engine.download { _ in }
        #expect(engine.isDownloaded)

        try engine.delete()
        #expect(!fake.isDownloaded)
    }
}

/// Collects numbers from several tasks.
private final class Order: @unchecked Sendable {
    private let lock = NSLock()
    private var numbers: [Int] = []

    var all: [Int] { lock.withLock { numbers } }

    func add(_ number: Int) {
        lock.withLock { numbers.append(number) }
    }
}
