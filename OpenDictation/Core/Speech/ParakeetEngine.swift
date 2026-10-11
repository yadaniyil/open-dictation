import CoreML
import FluidAudio
import Foundation

/// Nvidia Parakeet TDT 0.6B v3 (25 European languages, Ukrainian and Polish among them),
/// run on the phone through FluidAudio's Core ML build of it.
struct ParakeetEngine: LocalSpeechEngine {
    let folder: URL

    init(folder: URL) {
        self.folder = folder
    }

    /// FluidAudio's own check only looks for the model folders, which are already there halfway
    /// through a download. The marker is written once everything has arrived and loaded.
    var isDownloaded: Bool {
        FileManager.default.fileExists(atPath: marker.path)
            && AsrModels.modelsExist(at: modelFolder, version: .v3)
    }

    func download(progress: @escaping @Sendable (Double) -> Void) async throws {
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            // Also loads each part once. That makes iOS build the Neural Engine version now, with
            // the app open, and not during the first dictation from the Action Button.
            try await AsrModels.download(to: modelFolder, version: .v3) { update in
                if let fraction = Self.fraction(for: update) { progress(fraction) }
            }
            try Data().write(to: marker)
            progress(1)
        } catch {
            throw LocalSpeechError.failed("The download did not finish. \(error.localizedDescription)")
        }
    }

    func delete() throws {
        guard FileManager.default.fileExists(atPath: folder.path) else { return }
        try FileManager.default.removeItem(at: folder)
    }

    /// Parakeet works out the language by itself and cannot be told which one to expect,
    /// so `languageCode` is not used.
    func transcribe(fileURL: URL, languageCode: String) async throws -> String {
        guard isDownloaded else { throw LocalSpeechError.notDownloaded }
        let text: String
        do {
            // Loaded for this one recording and dropped at the end of this block: the model takes
            // several hundred MB, and iOS is quick to end a background app that holds that much.
            // `loadLocal` never downloads; the other loaders fetch the files again when a load fails.
            let models = try AsrModels.loadLocal(from: modelFolder, version: .v3, configuration: Self.configuration)
            let manager = AsrManager(models: models)
            var state = try TdtDecoderState()
            text = try await manager.transcribe(fileURL, decoderState: &state).text
        } catch {
            throw LocalSpeechError.failed("Parakeet could not turn this into text. \(error.localizedDescription)")
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LocalSpeechError.noSpeech }
        return trimmed
    }

    /// The Action Button runs this while another app is in front, and iOS refuses GPU work in
    /// the background. So: Neural Engine and CPU only, never `.all` or `.cpuAndGPU`.
    private static var configuration: MLModelConfiguration {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine
        return configuration
    }

    /// FluidAudio saves a model into a subfolder named after it.
    private var modelFolder: URL {
        folder.appendingPathComponent(Repo.parakeetV3.folderName)
    }

    private var marker: URL {
        folder.appendingPathComponent("downloaded")
    }

    /// FluidAudio reports the download as the first half of its own scale and starts that scale
    /// again for each part it loads. Here the download is the first 90% and loading is the rest.
    private static func fraction(for update: DownloadProgress) -> Double? {
        switch update.phase {
        case .listing:
            0
        case .downloading(_, let totalFiles):
            // Zero files means "already on disk": nothing new to say.
            totalFiles > 0 ? min(update.fractionCompleted * 2, 1) * 0.9 : nil
        case .compiling(let part):
            switch part {
            case ModelNames.ASR.preprocessorFile: 0.9
            case ModelNames.ASR.encoderFile: 0.92
            case ModelNames.ASR.decoderFile: 0.97
            case ModelNames.ASR.jointV3File: 0.99
            default: nil
            }
        }
    }
}
