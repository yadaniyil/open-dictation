#if DEBUG
import AVFoundation
import Foundation
import UIKit

/// Times the on-device models on this iPhone. A development tool, not in release builds: it
/// runs when the app is launched with `-runBenchmark`, reads the sound files in
/// Documents/bench, and writes what each downloaded model made of them, and how long each
/// took, to results.json in the same folder.
@MainActor
enum ModelBenchmark {
    struct Run: Codable {
        let model: String
        let clip: String
        let audioSeconds: Double
        /// Loading the model, transcribing and letting the model go: what a dictation waits for.
        let seconds: Double
        let text: String
        let error: String?
    }

    struct Report: Codable {
        var device: String
        var finished = false
        var runs: [Run] = []
    }

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-runBenchmark")
    }

    static func run() async {
        let folder = URL.documentsDirectory.appendingPathComponent("bench")
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        let clips = files
            .filter { ["m4a", "wav", "mp3"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var report = Report(device: DeviceModel.identifier)
        save(report, to: folder)
        // A locked phone would stop the run.
        UIApplication.shared.isIdleTimerDisabled = true
        defer { UIApplication.shared.isIdleTimerDisabled = false }

        for model in SpeechModel.allCases where model.isOnDevice {
            guard let engine = model.makeEngine(), engine.isDownloaded else { continue }
            for clip in clips {
                let audio = (try? await AVURLAsset(url: clip).load(.duration).seconds) ?? 0
                let start = ContinuousClock.now
                var text = ""
                var failure: String?
                do {
                    text = try await engine.transcribe(fileURL: clip, languageCode: "")
                } catch {
                    failure = error.localizedDescription
                }
                let took = ContinuousClock.now - start
                let seconds = Double(took.components.seconds) + Double(took.components.attoseconds) / 1e18
                report.runs.append(Run(
                    model: model.rawValue, clip: clip.lastPathComponent,
                    audioSeconds: audio, seconds: seconds, text: text, error: failure))
                save(report, to: folder)
            }
        }
        report.finished = true
        save(report, to: folder)
    }

    private static func save(_ report: Report, to folder: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(report).write(to: folder.appendingPathComponent("results.json"), options: .atomic)
    }
}
#endif
