import AVFoundation

/// Records the microphone into a small AAC file that OpenAI accepts as-is.
@MainActor
final class AudioRecorder {
    struct Recording: Sendable {
        let url: URL
        let duration: TimeInterval
    }

    enum RecorderError: LocalizedError {
        case couldNotStart

        var errorDescription: String? {
            switch self {
            case .couldNotStart: "The microphone did not start."
            }
        }
    }

    private var recorder: AVAudioRecorder?

    var isRecording: Bool { recorder?.isRecording ?? false }

    func start() throws {
        try activateSession()

        // 16 kHz mono is all speech recognition needs: about 0.25 MB per minute.
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 32_000,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        do {
            let recorder = try AVAudioRecorder(url: Self.newFileURL(), settings: settings)
            guard recorder.record() else { throw RecorderError.couldNotStart }
            self.recorder = recorder
        } catch {
            deactivateSession()
            throw error
        }
    }

    /// Stops and returns the file, or nil when nothing was recording.
    func stop() -> Recording? {
        guard let recorder else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        deactivateSession()
        return Recording(url: recorder.url, duration: duration)
    }

    /// Recording on its own takes over the audio, so music pauses. iOS can refuse that while the
    /// app is in the background (error '!int'); then the session mixes with whatever is playing.
    /// Mixing needs `.playAndRecord`: Apple allows `.mixWithOthers` there but not with `.record`.
    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        }
    }

    private func deactivateSession() {
        // Lets music or a podcast pick up again.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func newFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("dictation-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
    }
}
