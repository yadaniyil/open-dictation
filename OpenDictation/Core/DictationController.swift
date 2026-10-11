import ActivityKit
import AVFoundation
import Observation
import UIKit

/// The one place that knows whether we are listening, working or idle.
/// The app screen, the Action Button intent and the Live Activity button all go through it.
@MainActor
@Observable
final class DictationController {
    static let shared = DictationController()

    enum Phase: Equatable {
        case idle
        case recording(startedAt: Date)
        case transcribing
    }

    enum Outcome: Equatable, Sendable {
        case started
        case finished(text: String)
    }

    enum Message: Equatable {
        /// `note` explains anything that went half right, such as a style step that failed.
        case copied(note: String?)
        case failed(String)
    }

    enum DictationError: LocalizedError {
        case busy
        case notRecording
        case needsFirstSteps
        case needsMicrophonePermission
        case microphoneDenied
        case liveActivitiesOff
        case tooShort
        case stillWorking

        var errorDescription: String? {
            switch self {
            case .busy: "Still working on the last one."
            case .notRecording: "Nothing is being recorded."
            case .needsFirstSteps: "Open the app once to finish the first steps."
            case .needsMicrophonePermission: "Open the app once to allow the microphone."
            case .microphoneDenied: "The microphone is turned off for Open Dictation in Settings."
            case .liveActivitiesOff: "Turn on Live Activities for Open Dictation in Settings."
            case .tooShort: "That was too short."
            case .stillWorking: "This one is taking a while. The text will be in the app when it is ready."
            }
        }
    }

    private(set) var phase: Phase = .idle
    /// The result of the last dictation, shown under the button in the app.
    private(set) var lastMessage: Message?
    /// True when a recording could not be sent and is waiting for another try.
    private(set) var hasUnsentRecording = false
    let history = HistoryStore()

    private let recorder = AudioRecorder()
    private let speechModels = SpeechModelStore.shared
    private var activity: LiveActivity?
    private var closingActivityTask: Task<Void, Never>?
    private var limitTask: Task<Void, Never>?
    private var interruptionObserver: (any NSObjectProtocol)?
    private var pendingClipboard: (text: String, date: Date)?

    private init() {
        hasUnsentRecording = FileManager.default.fileExists(atPath: Self.unsentURL.path)
        // A Live Activity left over from a run that was killed would show a timer that never stops.
        for stale in Activity<DictationActivityAttributes>.activities.map(LiveActivity.init) {
            Task { await stale.end() }
        }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { note in
            let rawType = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            guard rawType == AVAudioSession.InterruptionType.began.rawValue else { return }
            Task { @MainActor in DictationController.shared.finishEarly() }
        }
    }

    // MARK: - Start and stop

    /// For the button in the app.
    @discardableResult
    func toggle() async throws -> Outcome {
        switch phase {
        case .idle:
            try start()
            return .started
        case .recording:
            return .finished(text: try await finish())
        case .transcribing:
            throw DictationError.busy
        }
    }

    /// For the Action Button. iOS gives an intent about 30 seconds, so a slow answer is not waited
    /// for: the work carries on and the text lands in the app's Recent list.
    func toggleFromIntent() async throws -> Outcome {
        switch phase {
        case .idle:
            try start(requireLiveActivity: true)
            // Only the shortcut comes this way, so it is set up and the main screen can drop its steps.
            SetupProgress.markDone()
            return .started
        case .recording:
            let work = Task { try await self.finish() }
            return .finished(text: try await Self.value(of: work, within: .seconds(25)))
        case .transcribing:
            throw DictationError.busy
        }
    }

    /// Used after the intent has brought the app to the front because the background start failed.
    func startAfterComingToFront() async throws {
        if AVAudioApplication.shared.recordPermission == .undetermined {
            _ = await AVAudioApplication.requestRecordPermission()
        }
        try start(requireLiveActivity: true)
        SetupProgress.markDone()
    }

    /// - Parameter requireLiveActivity: iOS ends a recording that an intent started unless a
    ///   Live Activity is showing, so the intent refuses to record without one.
    func start(requireLiveActivity: Bool = false) throws {
        guard phase == .idle else { throw DictationError.busy }
        do {
            // Nothing is recorded before the user has agreed to where recordings go.
            guard OnboardingState.hasAgreedToCloudProcessing else { throw DictationError.needsFirstSteps }
            guard speechModels.canListen else {
                throw speechModels.selected == .elevenLabs ? ElevenLabsError.missingKey : OpenAIError.missingKey
            }
            switch AVAudioApplication.shared.recordPermission {
            case .granted: break
            case .undetermined: throw DictationError.needsMicrophonePermission
            default: throw DictationError.microphoneDenied
            }

            let startedAt = Date()
            startActivity(startedAt: startedAt)
            if requireLiveActivity, activity == nil { throw DictationError.liveActivitiesOff }
            do {
                try recorder.start()
            } catch {
                endActivityNow()
                throw error
            }
            phase = .recording(startedAt: startedAt)
            lastMessage = nil
            scheduleLimit()
        } catch {
            lastMessage = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Stops listening, turns the recording into text and puts it on the clipboard.
    func finish() async throws -> String {
        guard case .recording(let startedAt) = phase, let recording = recorder.stop() else {
            throw DictationError.notRecording
        }
        limitTask?.cancel()
        limitTask = nil

        guard recording.duration >= 0.5 else {
            try? FileManager.default.removeItem(at: recording.url)
            return try await fail(DictationError.tooShort, startedAt: startedAt)
        }

        phase = .transcribing
        await updateActivity(.transcribing, startedAt: startedAt)
        return try await transcribe(recording.url, startedAt: startedAt)
    }

    /// Tries the recording that failed last time again, with the model that is picked now.
    func retryUnsent() async {
        guard phase == .idle, hasUnsentRecording else { return }
        phase = .transcribing
        _ = try? await transcribe(Self.unsentURL, startedAt: Date())
    }

    func discardUnsent() {
        try? FileManager.default.removeItem(at: Self.unsentURL)
        hasUnsentRecording = false
    }

    /// iOS can ignore a clipboard write made from the background, so a fresh result is copied
    /// again when the app comes to the front.
    func appBecameActive() {
        guard let pending = pendingClipboard else { return }
        pendingClipboard = nil
        // An old result must not replace something the user copied since.
        if pending.date.timeIntervalSinceNow > -120 {
            UIPasteboard.general.string = pending.text
        }
    }

    // MARK: - Transcribing

    private func transcribe(_ fileURL: URL, startedAt: Date) async throws -> String {
        // Keeps the app awake for the upload, or the on-device model, after the microphone has let go.
        let background = UIApplication.shared.beginBackgroundTask(withName: "transcribe")
        defer { UIApplication.shared.endBackgroundTask(background) }

        do {
            let apiKey = AppSettings.apiKey
            let spoken: String
            // What did the listening, for the recording archive.
            let model: String
            // Times the steps, for the user's own stats.
            var stopwatch = DictationStopwatch(provider: speechModels.selected)
            if let engine = speechModels.engine {
                model = speechModels.selected.rawValue
                spoken = try await engine.transcribe(fileURL: fileURL, languageCode: AppSettings.languageCode)
            } else if speechModels.selected == .elevenLabs {
                guard let key = AppSettings.elevenLabsKey else { throw ElevenLabsError.missingKey }
                model = ElevenLabsTranscriber.model
                spoken = try await ElevenLabsTranscriber().transcribe(
                    fileURL: fileURL, apiKey: key, languageCode: AppSettings.languageCode)
            } else {
                guard let apiKey else { throw OpenAIError.missingKey }
                model = AppSettings.model
                let options = OpenAITranscriber.Options(
                    model: model,
                    languageCode: AppSettings.languageCode,
                    vocabulary: AppSettings.vocabulary)
                spoken = try await OpenAITranscriber().transcribe(fileURL: fileURL, apiKey: apiKey, options: options)
            }
            stopwatch.speechEnded()
            var text = spoken

            // The style step is always OpenAI's, so it needs OpenAI's key whoever did the listening.
            // A failed style step must not cost the user their dictation: fall back to the plain text.
            var note: String?
            let style = AppSettings.style.instructions(custom: AppSettings.customInstructions)
            if let apiKey, style != nil || AppSettings.followsSpokenInstructions {
                do {
                    let reply = try await OpenAIRewriter().rewrite(
                        text, style: style, apiKey: apiKey, model: AppSettings.rewriteModel)
                    text = reply.text
                    stopwatch.usage = reply.usage
                } catch {
                    note = "Copied as spoken. The style step did not work: \(error.localizedDescription)"
                }
                stopwatch.textEnded()
            } else if style != nil {
                note = "Copied as spoken. Styles need an OpenAI key."
            }

            copyToClipboard(text)
            history.add(text)
            // Before the recording is moved or deleted: its length is read from the file.
            DictationLog.shared.record(stopwatch.record(text: text, recording: fileURL))
            if AppSettings.keepsRecordings {
                RecordingArchive.shared.keep(fileURL, note: .init(
                    spoken: spoken, final: text, style: AppSettings.style.rawValue, model: model))
            } else {
                try? FileManager.default.removeItem(at: fileURL)
            }
            if fileURL == Self.unsentURL { hasUnsentRecording = false }

            phase = .idle
            lastMessage = .copied(note: note)
            await closeActivity(.copied, startedAt: startedAt, detail: text)
            return text
        } catch {
            switch error {
            case OpenAIError.noSpeech, ElevenLabsError.noSpeech, LocalSpeechError.noSpeech:
                try? FileManager.default.removeItem(at: fileURL)
                if fileURL == Self.unsentURL { hasUnsentRecording = false }
            default:
                keepForRetry(fileURL)
            }
            return try await fail(error, startedAt: startedAt)
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        if UIApplication.shared.applicationState != .active {
            pendingClipboard = (text, Date())
        }
    }

    private func fail(_ error: any Error, startedAt: Date) async throws -> String {
        phase = .idle
        lastMessage = .failed(error.localizedDescription)
        await closeActivity(.failed, startedAt: startedAt, detail: error.localizedDescription)
        throw error
    }

    private func keepForRetry(_ fileURL: URL) {
        guard fileURL != Self.unsentURL else { return }
        let manager = FileManager.default
        try? manager.createDirectory(
            at: Self.unsentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? manager.removeItem(at: Self.unsentURL)
        do {
            try manager.moveItem(at: fileURL, to: Self.unsentURL)
            hasUnsentRecording = true
        } catch {
            hasUnsentRecording = manager.fileExists(atPath: Self.unsentURL.path)
        }
    }

    private static var unsentURL: URL {
        URL.applicationSupportDirectory.appendingPathComponent("unsent.m4a")
    }

    /// Waits for `task`, but only for so long. The task itself keeps running either way.
    private static func value(of task: Task<String, any Error>, within limit: Duration) async throws -> String {
        let gate = ResumeGate()
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                let result = await task.result
                if gate.claim() { continuation.resume(with: result) }
            }
            Task {
                try? await Task.sleep(for: limit)
                if gate.claim() { continuation.resume(throwing: DictationError.stillWorking) }
            }
        }
    }

    // MARK: - Stopping without the user

    private func scheduleLimit() {
        let limit = Duration.seconds(AppSettings.maxMinutes * 60)
        limitTask = Task { [weak self] in
            try? await Task.sleep(for: limit)
            guard !Task.isCancelled else { return }
            self?.finishEarly()
        }
    }

    /// The time limit ran out, or a phone call took the microphone: send what we have.
    private func finishEarly() {
        guard case .recording = phase else { return }
        // A fresh task, because `finish()` cancels the limit task that may be calling this.
        Task { _ = try? await finish() }
    }

    // MARK: - Live Activity

    private func startActivity(startedAt: Date) {
        endActivityNow()
        let state = DictationActivityAttributes.ContentState(phase: .recording, startedAt: startedAt)
        activity = (try? Activity.request(
            attributes: DictationActivityAttributes(),
            content: ActivityContent(state: state, staleDate: nil))
        ).map(LiveActivity.init)
    }

    private func updateActivity(_ phase: DictationActivityAttributes.ContentState.Phase, startedAt: Date) async {
        await activity?.update(DictationActivityAttributes.ContentState(phase: phase, startedAt: startedAt))
    }

    /// Shows the result in the Dynamic Island for a moment, then takes the activity away.
    private func closeActivity(
        _ phase: DictationActivityAttributes.ContentState.Phase, startedAt: Date, detail: String
    ) async {
        guard let activity else { return }
        let state = DictationActivityAttributes.ContentState(
            phase: phase, startedAt: startedAt, detail: String(detail.prefix(160)))
        await activity.update(state)

        closingActivityTask = Task { [weak self] in
            let background = UIApplication.shared.beginBackgroundTask(withName: "close-activity")
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled, self?.activity?.id == activity.id {
                self?.activity = nil
                await activity.end()
            }
            UIApplication.shared.endBackgroundTask(background)
        }
    }

    private func endActivityNow() {
        closingActivityTask?.cancel()
        closingActivityTask = nil
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end() }
    }
}

/// ActivityKit's `Activity` can be used from any thread but is not marked `Sendable`,
/// so this box carries it across `await`s.
private struct LiveActivity: @unchecked Sendable {
    let activity: Activity<DictationActivityAttributes>

    var id: String { activity.id }

    func update(_ state: DictationActivityAttributes.ContentState) async {
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end() async {
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}

/// Lets exactly one of two racing tasks resume a continuation.
@MainActor
private final class ResumeGate {
    private var claimed = false

    func claim() -> Bool {
        guard !claimed else { return false }
        claimed = true
        return true
    }
}

extension DictationActivityAttributes.ContentState {
    init(phase: Phase, startedAt: Date) {
        self.init(phase: phase, startedAt: startedAt, detail: nil)
    }
}
