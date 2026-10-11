#if DEBUG
import AVFoundation
import Foundation
import UIKit

/// Times the on-device models on this iPhone. A development tool, not in release builds: it
/// runs when the app is launched with `-runBenchmark`, reads the sound files in
/// Documents/bench, and writes what each downloaded model made of them, and how long each
/// took, to results.json in the same folder. The model in use is prepared first when it needs
/// it, as after any install, and the file says how long that took.
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
        /// The model the app prepared before the clips, when it had not been loaded since the
        /// last install, and how long that took. That is the wait a first dictation used to have.
        var prepared: String?
        var preparingSeconds: Double?
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

        // The app prepares the model in use once it is in front. That goes first, so no clip is
        // timed while it runs.
        for _ in 0..<50 where UIApplication.shared.applicationState != .active {
            try? await Task.sleep(for: .milliseconds(100))
        }
        let store = SpeechModelStore.shared
        let inUse = store.selected
        let preparingStart = ContinuousClock.now
        if let preparation = store.prepareIfNeeded() {
            await preparation.value
            report.prepared = inUse.rawValue
            report.preparingSeconds = seconds(since: preparingStart)
            save(report, to: folder)
        }

        // A locked phone would stop the run. Set after the preparation, which lets the screen
        // sleep again when it ends.
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
                report.runs.append(Run(
                    model: model.rawValue, clip: clip.lastPathComponent,
                    audioSeconds: audio, seconds: seconds(since: start), text: text, error: failure))
                save(report, to: folder)
            }
        }
        report.finished = true
        save(report, to: folder)
    }

    private static func seconds(since start: ContinuousClock.Instant) -> Double {
        let took = ContinuousClock.now - start
        return Double(took.components.seconds) + Double(took.components.attoseconds) / 1e18
    }

    private static func save(_ report: Report, to folder: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(report).write(to: folder.appendingPathComponent("results.json"), options: .atomic)
    }
}
#endif
