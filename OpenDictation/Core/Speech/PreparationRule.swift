import Foundation

/// Decides whether the model in use is loaded once now, ahead of a dictation, so that the slow
/// first load after an app or iOS update does not land on one. Kept on its own so the rule can
/// be read, and tested, in one place.
///
/// The model is prepared only when all of these hold:
/// - it runs on the phone and all its files are there;
/// - its note says it was last loaded on another build, install or iOS (`PreparedModels`);
/// - no other preparation and no download is under way;
/// - and, depending on the moment:
///   - the app came to the front: it is still on the screen. No room is asked for: the user is
///     there to see it, and a phone short on space would otherwise keep the slow load for the
///     next dictation;
///   - iOS gave the app a background window: those only come while the phone charges (the
///     request asks for that), and the phone has room. Nobody is looking, so iOS's extra copy of
///     the model is not written onto a phone that is nearly full;
///   - a dictation started: always. That dictation loads the model anyway; this only starts the
///     load while the user is still talking instead of after Stop, so no room is asked for.
enum PreparationRule {
    enum Moment: String, Sendable {
        case appInFront
        case chargingWindow
        case dictationStarted
    }

    enum Decision: Equatable {
        case prepare
        case skip(Reason)
    }

    enum Reason: String, Equatable {
        case cloudModel = "it runs in the cloud"
        case notDownloaded = "it is not downloaded"
        case alreadyPrepared = "it was prepared on this version"
        case busy = "something else is loading or downloading"
        case notInFront = "the app is not on the screen"
        case lowStorage = "the phone is low on space"
    }

    /// Room a background window asks for: iOS writes its own copy of the model into the app's
    /// Caches folder while it prepares it, a new one for every install. Parakeet's copy was
    /// 1.19 GB in the Simulator (CPU, 2026-11-06); the iPhone's Neural Engine copy is not measured.
    static let neededFreeBytes: Int64 = 1_500_000_000

    /// - Parameters:
    ///   - status: the model's status, or nil for a cloud model.
    ///   - needsPreparing: true when its note is missing or from another version.
    ///   - isBusy: a preparation or a download is under way.
    ///   - freeBytes: asked last, and only when the answer matters.
    static func decide(
        _ moment: Moment,
        status: SpeechModelStore.Status?,
        needsPreparing: Bool,
        isBusy: Bool,
        isInFront: Bool,
        freeBytes: () -> Int64
    ) -> Decision {
        guard let status else { return .skip(.cloudModel) }
        switch status {
        case .ready: break
        case .preparing: return .skip(.busy)
        case .notSetUp, .downloading, .failed: return .skip(.notDownloaded)
        }
        guard needsPreparing else { return .skip(.alreadyPrepared) }
        guard !isBusy else { return .skip(.busy) }
        switch moment {
        case .appInFront:
            guard isInFront else { return .skip(.notInFront) }
        case .chargingWindow:
            guard freeBytes() >= neededFreeBytes else { return .skip(.lowStorage) }
        case .dictationStarted:
            break
        }
        return .prepare
    }

    /// Whether a background window is worth asking iOS for: the model in use runs on the phone,
    /// is downloaded, and its slow first load on this version is still ahead, or under way,
    /// which iOS may cut short. Room is looked at when the window comes.
    static func needsWindow(status: SpeechModelStore.Status?, needsPreparing: Bool) -> Bool {
        switch status {
        case .ready, .preparing: needsPreparing
        case nil, .notSetUp, .downloading, .failed: false
        }
    }
}
