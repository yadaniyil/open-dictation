import CoreML
import Foundation
import WhisperKit

/// Whisper Large v3 Turbo on the phone, run by WhisperKit (Core ML).
struct WhisperEngine: LocalSpeechEngine {
    /// The compressed large-v3-turbo build in WhisperKit's model repo on Hugging Face.
    static let repo = "argmaxinc/whisperkit-coreml"
    static let variant = "openai_whisper-large-v3-v20240930_turbo_632MB"
    /// What the download weighs. Only used to turn bytes on disk into a fraction.
    private static let downloadBytes = 646_000_000.0

    /// iOS refuses GPU work from an app in the background, and has crashed apps that try. A
    /// dictation usually ends there, so no stage may use the GPU: the two big models run on
    /// CPU + Neural Engine, and prewarm loads them with these same units. WhisperKit would put the
    /// mel stage on the GPU; it runs on the CPU, because on the Neural Engine it cost accuracy
    /// (25 wrong words instead of 17 on the 8 test clips).
    private static let compute = ModelComputeOptions(
        melCompute: .cpuOnly,
        audioEncoderCompute: .cpuAndNeuralEngine,
        textDecoderCompute: .cpuAndNeuralEngine)

    let folder: URL

    init(folder: URL) {
        self.folder = folder
    }

    var isDownloaded: Bool {
        FileManager.default.fileExists(atPath: readyFlag.path)
    }

    func download(progress: @escaping @Sendable (Double) -> Void) async throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // The model can be fetched again, so it has no place in an iCloud backup.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var excluded = folder
        try excluded.setResourceValues(values)

        // A second call skips the files that are complete and resumes the one that is not.
        _ = try await WhisperKit.download(variant: Self.variant, downloadBase: folder, from: Self.repo) { _ in
            // WhisperKit counts files, and two of the 22 hold 97% of the bytes. So measure the folder.
            progress(0.9 * min(1, Self.bytes(in: folder) / Self.downloadBytes))
        }
        progress(0.9)

        // Core ML compiles a model for this chip the first time it loads, which can take minutes.
        // Loading once here (WhisperKit's prewarm) moves that wait from the first dictation to the
        // download. The load also fetches the small tokenizer files.
        let whisper = try await WhisperKit(config(prewarm: true))
        await whisper.unloadModels()

        // Core ML cannot be stopped halfway, so a cancel during the compile only shows up here.
        try Task.checkCancellation()
        try Data().write(to: readyFlag)
        progress(1)
    }

    func delete() throws {
        guard FileManager.default.fileExists(atPath: folder.path) else { return }
        try FileManager.default.removeItem(at: folder)
    }

    /// WhisperKit's prewarm loads the three parts one after the other and drops each at once, so
    /// the memory needed is that of the biggest part and not of all three. With `load` off nothing
    /// is loaded a second time to stay.
    func prepare() async throws {
        guard isDownloaded else { throw LocalSpeechError.notDownloaded }
        _ = try await WhisperKit(config(prewarm: true, load: false))
    }

    func transcribe(fileURL: URL, languageCode: String) async throws -> String {
        guard isDownloaded else { throw LocalSpeechError.notDownloaded }
        // WhisperKit quietly treats a code it does not know as English. Detecting is the better guess.
        let code = languageCode.trimmingCharacters(in: .whitespaces).lowercased()
        let language = Constants.languageCodes.contains(code) ? code : nil
        let options = DecodingOptions(
            task: .transcribe,
            language: language,
            detectLanguage: language == nil,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            // WhisperKit skips the last second of audio by default, so a one-word recording came back empty.
            windowClipTime: 0)

        // Whisper hears 30 seconds at a time, so a longer recording is cut at its pauses. A piece
        // with nothing louder than room noise is dropped: Whisper answers silence with made-up
        // words such as "Thank you." WhisperKit can do the cutting itself, but then a piece that
        // fails is left out without an error.
        let samples = try AudioProcessor.loadAudioAsFloatArray(fromPath: fileURL.path)
        let voice = EnergyVAD()
        let pieces = try await VADAudioChunker(vad: voice)
            .chunkAll(audioArray: samples, maxChunkLength: Constants.defaultWindowSamples, decodeOptions: options)
            .filter { voice.voiceActivity(in: $0.audioSamples).contains(true) }
        guard !pieces.isEmpty else { throw LocalSpeechError.noSpeech }

        // WhisperKit picks each token with MLTensor, which is able to use the GPU. Same rule: CPU.
        let text = try await withMLTensorComputePolicy(.cpuOnly) {
            let whisper = try await WhisperKit(config(prewarm: false))
            do {
                var texts: [String] = []
                for piece in pieces {
                    texts += try await whisper.transcribe(audioArray: piece.audioSamples, decodeOptions: options).map(\.text)
                }
                await whisper.unloadModels()
                return texts.joined(separator: " ")
            } catch {
                await whisper.unloadModels()
                throw error
            }
        }

        // A hum or a click can come back as a lone full stop.
        let cleaned = Self.clean(text)
        guard cleaned.contains(where: { $0.isLetter || $0.isNumber }) else { throw LocalSpeechError.noSpeech }
        return cleaned
    }

    /// Whisper can write noises as tags such as `[BLANK_AUDIO]` or `(music)`. They are not speech.
    static func clean(_ text: String) -> String {
        text.replacing(/<\|[^|]*\|>|\[[^\]]*\]|\([^)]*\)/, with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    // MARK: - Files

    /// Written last, so a download that stopped halfway never counts as done.
    private var readyFlag: URL {
        folder.appendingPathComponent("ready")
    }

    /// Where WhisperKit's downloader puts the variant inside `folder`.
    private var modelFolder: URL {
        HubApiWrapper(downloadBase: folder).localRepoLocation(.init(id: Self.repo))
            .appendingPathComponent(Self.variant)
    }

    /// Everything stays inside `folder`, so nothing is fetched while transcribing.
    private func config(prewarm: Bool, load: Bool = true) -> WhisperKitConfig {
        WhisperKitConfig(
            modelFolder: modelFolder.path,
            tokenizerFolder: folder,
            computeOptions: Self.compute,
            verbose: false,
            prewarm: prewarm,
            load: load,
            download: false)
    }

    private static func bytes(in folder: URL) -> Double {
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.fileSizeKey])
        var total = 0
        while let file = files?.nextObject() as? URL {
            total += (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        return Double(total)
    }
}
