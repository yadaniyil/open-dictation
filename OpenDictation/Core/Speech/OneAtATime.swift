import Foundation

/// An on-device engine that waits its turn before it loads its model. A loaded model takes
/// several hundred MB, so two loads must never overlap: a dictation that starts while the app
/// prepares a model waits for that to end, and does not load a second copy next to it.
/// Every engine shares one queue unless told otherwise, so preparing one model and dictating
/// with the other take turns as well.
struct OneAtATime<Engine: LocalSpeechEngine>: LocalSpeechEngine {
    let engine: Engine
    let turns: ModelTurns

    init(_ engine: Engine, turns: ModelTurns = .shared) {
        self.engine = engine
        self.turns = turns
    }

    init(folder: URL) {
        self.init(Engine(folder: folder))
    }

    var isDownloaded: Bool { engine.isDownloaded }

    /// A download runs for minutes, so it does not hold the queue: a dictation with another
    /// model goes on meanwhile.
    func download(progress: @escaping @Sendable (Double) -> Void) async throws {
        try await engine.download(progress: progress)
    }

    func delete() throws {
        try engine.delete()
    }

    func prepare() async throws {
        try await turns.run { try await engine.prepare() }
    }

    func transcribe(fileURL: URL, languageCode: String) async throws -> String {
        try await turns.run { try await engine.transcribe(fileURL: fileURL, languageCode: languageCode) }
    }
}

/// Hands out turns: one piece of work runs, and the next waits until it has ended, in the order
/// they came.
actor ModelTurns {
    static let shared = ModelTurns()

    private var isTaken = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func run<Value: Sendable>(_ work: @Sendable () async throws -> Value) async rethrows -> Value {
        if isTaken {
            // Whoever ends hands the turn straight to the first in line, so `isTaken` stays true.
            await withCheckedContinuation { waiting.append($0) }
        } else {
            isTaken = true
        }
        defer {
            if waiting.isEmpty { isTaken = false } else { waiting.removeFirst().resume() }
        }
        return try await work()
    }
}
