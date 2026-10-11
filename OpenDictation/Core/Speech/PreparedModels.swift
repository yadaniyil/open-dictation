import Foundation

/// Remembers which on-device models were loaded since the app or iOS last changed. iOS builds a
/// model's Neural Engine version on the first load after the app was installed or updated, or
/// iOS was, and that load takes half a minute to a few minutes. A model whose note is missing
/// or out of date still has that load ahead of it.
///
/// `UserDefaults` can be used from any thread but is not marked `Sendable`, hence `@unchecked`.
struct PreparedModels: @unchecked Sendable {
    /// The app's own notes, for this copy of the app on this iOS.
    static let standard = PreparedModels(defaults: .standard, stamp: currentStamp)

    let defaults: UserDefaults
    /// What a model is prepared for. A note with any other stamp is out of date.
    let stamp: String

    func needsPreparing(_ model: SpeechModel) -> Bool {
        defaults.string(forKey: Self.key(for: model)) != stamp
    }

    /// Call only after the model was loaded without an error.
    func markPrepared(_ model: SpeechModel) {
        defaults.set(stamp, forKey: Self.key(for: model))
    }

    /// For a model whose files were deleted.
    func forget(_ model: SpeechModel) {
        defaults.removeObject(forKey: Self.key(for: model))
    }

    /// - Parameters:
    ///   - appBuild: the app's build number, which every update changes.
    ///   - install: the folder iOS put the app in. Every install gets a new one, also when the
    ///     same build is installed again, as happens during development.
    ///   - system: the iOS version with its build, which every iOS update changes.
    static func stamp(appBuild: String, install: String, system: String) -> String {
        [appBuild, install, system].joined(separator: " | ")
    }

    private static var currentStamp: String {
        stamp(
            appBuild: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "",
            install: Bundle.main.bundlePath,
            system: ProcessInfo.processInfo.operatingSystemVersionString)
    }

    private static func key(for model: SpeechModel) -> String {
        "preparedFor.\(model.rawValue)"
    }
}
