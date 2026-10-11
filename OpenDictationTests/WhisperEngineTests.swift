import Foundation
import Testing
@testable import OpenDictation

struct WhisperEngineTests {
    private func makeEngine() -> WhisperEngine {
        WhisperEngine(folder: FileManager.default.temporaryDirectory.appendingPathComponent("whisper-\(UUID().uuidString)"))
    }

    @Test func nothingIsDownloadedInAnEmptyFolder() throws {
        let engine = makeEngine()
        #expect(!engine.isDownloaded)
        try FileManager.default.createDirectory(at: engine.folder, withIntermediateDirectories: true)
        #expect(!engine.isDownloaded)
    }

    @Test func deleteIsHarmlessWhenThereIsNothingToDelete() throws {
        let engine = makeEngine()
        try engine.delete()
        try FileManager.default.createDirectory(at: engine.folder, withIntermediateDirectories: true)
        try engine.delete()
        #expect(!FileManager.default.fileExists(atPath: engine.folder.path))
    }

    @Test func transcribingWithoutTheModelSaysSo() async {
        await #expect(throws: LocalSpeechError.notDownloaded) {
            try await makeEngine().transcribe(fileURL: URL(fileURLWithPath: "/dev/null"), languageCode: "")
        }
    }

    @Test func noiseTagsAndSpecialTokensAreRemoved() {
        #expect(WhisperEngine.clean(" [BLANK_AUDIO] ") == "")
        #expect(WhisperEngine.clean("<|uk|><|transcribe|> Привіт (музика)  світ. [MUSIC]<|endoftext|>") == "Привіт світ.")
        #expect(WhisperEngine.clean("Bump the version to 2.4.") == "Bump the version to 2.4.")
    }
}
