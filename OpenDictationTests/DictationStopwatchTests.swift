import AVFoundation
import Testing
@testable import OpenDictation

struct DictationStopwatchTests {
    /// Writes a silent sound file of the given length and returns where it is.
    private func makeRecording(seconds: Double) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("clip-\(UUID().uuidString).wav")
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let frames = AVAudioFrameCount(seconds * format.sampleRate)
        let silence = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        silence.frameLength = frames
        // The file is complete once the writer has gone out of scope.
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: silence)
        }
        return url
    }

    @Test func theLengthOfARecordingIsReadFromItsFile() throws {
        #expect(DictationStopwatch.seconds(ofAudioAt: try makeRecording(seconds: 2)) == 2)
        #expect(DictationStopwatch.seconds(ofAudioAt: try makeRecording(seconds: 0.5)) == 0.5)
    }

    @Test func aFileThatIsNotSoundHasNoLength() throws {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).m4a")
        #expect(DictationStopwatch.seconds(ofAudioAt: missing) == nil)

        let text = FileManager.default.temporaryDirectory.appendingPathComponent("text-\(UUID().uuidString).m4a")
        try Data("not sound".utf8).write(to: text)
        #expect(DictationStopwatch.seconds(ofAudioAt: text) == nil)
    }

    @Test func aDictationWithATextStepGetsEveryNumber() throws {
        let recording = try makeRecording(seconds: 3)
        let date = StatsTestSupport.date("2026-10-11T09:00:00Z")

        var stopwatch = DictationStopwatch(provider: .elevenLabs)
        stopwatch.speechEnded()
        stopwatch.usage = TokenUsage(input: 312, output: 41)
        stopwatch.speechDollars = 0.0012
        stopwatch.textEnded()
        let record = try #require(stopwatch.record(text: "Hello there, world.", recording: recording, date: date))

        #expect(record.date == date)
        #expect(record.provider == .elevenLabs)
        #expect(record.audioSeconds == 3)
        #expect(record.words == 3)
        #expect(record.inputTokens == 312)
        #expect(record.outputTokens == 41)
        #expect(record.speechDollars == 0.0012)
        // Nothing was waited for here, so both steps took next to no time.
        #expect((0..<1).contains(record.speechSeconds))
        #expect((0..<1).contains(try #require(record.textSeconds)))
    }

    @Test func aDictationWithoutATextStepHasNoTextTime() throws {
        var stopwatch = DictationStopwatch(provider: .parakeetV3)
        stopwatch.speechEnded()
        let record = try #require(stopwatch.record(text: "Hello", recording: try makeRecording(seconds: 1)))

        #expect(record.textSeconds == nil)
        #expect(record.inputTokens == nil)
        #expect(record.outputTokens == nil)
        #expect(record.speechDollars == nil)
    }

    @Test func theStepsAreTimedOneAfterTheOther() async throws {
        var stopwatch = DictationStopwatch(provider: .openAI)
        try await Task.sleep(for: .milliseconds(300))
        stopwatch.speechEnded()
        try await Task.sleep(for: .milliseconds(20))
        stopwatch.textEnded()
        let record = try #require(stopwatch.record(text: "Hello", recording: try makeRecording(seconds: 1)))

        #expect(record.speechSeconds >= 0.3)
        #expect(try #require(record.textSeconds) >= 0.02)
        // The text step's time does not include the speech step's.
        #expect(try #require(record.textSeconds) < record.speechSeconds)
    }

    @Test func aRecordingThatCannotBeMeasuredGivesNoLine() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).m4a")
        var stopwatch = DictationStopwatch(provider: .openAI)
        stopwatch.speechEnded()
        #expect(stopwatch.record(text: "Hello", recording: missing) == nil)
    }
}
