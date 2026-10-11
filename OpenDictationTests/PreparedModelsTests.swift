import Foundation
import Testing
@testable import OpenDictation

/// The notes that say which models were loaded since the app or iOS last changed.
struct PreparedModelsTests {
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "PreparedModelsTests.\(UUID().uuidString)"))
    }

    /// The same phone's notes, read by an app with this build, install folder and iOS.
    private func notes(appBuild: String = "5", install: String = "/Bundle/A/App.app", system: String = "Version 26.0 (Build 23A341)") -> PreparedModels {
        PreparedModels(
            defaults: defaults,
            stamp: PreparedModels.stamp(appBuild: appBuild, install: install, system: system))
    }

    @Test func aFreshInstallHasEverythingAheadOfIt() {
        for model in SpeechModel.allCases {
            #expect(notes().needsPreparing(model))
        }
    }

    @Test func aPreparedModelStaysPreparedOnTheSameBuild() {
        notes().markPrepared(.parakeetV3)

        // Also at the next launch, which reads the same notes.
        #expect(!notes().needsPreparing(.parakeetV3))
        // Each model has a note of its own.
        #expect(notes().needsPreparing(.whisperLargeTurbo))
    }

    @Test func aNewBuildOfTheAppNeedsItAgain() {
        notes().markPrepared(.parakeetV3)
        #expect(notes(appBuild: "6").needsPreparing(.parakeetV3))
    }

    @Test func theSameBuildInstalledAgainNeedsItAgain() {
        notes().markPrepared(.parakeetV3)
        #expect(notes(install: "/Bundle/B/App.app").needsPreparing(.parakeetV3))
    }

    @Test func aNewIOSNeedsItAgain() {
        notes().markPrepared(.whisperLargeTurbo)
        #expect(notes(system: "Version 26.1 (Build 23B85)").needsPreparing(.whisperLargeTurbo))
    }

    @Test func preparingAgainAfterAnUpdateBringsTheNoteUpToDate() {
        notes().markPrepared(.parakeetV3)
        let updated = notes(appBuild: "6")
        updated.markPrepared(.parakeetV3)

        #expect(!updated.needsPreparing(.parakeetV3))
        // Going back to the old build would mean a new install, and a new load.
        #expect(notes().needsPreparing(.parakeetV3))
    }

    @Test func aDeletedModelIsForgotten() {
        notes().markPrepared(.parakeetV3)
        notes().markPrepared(.whisperLargeTurbo)
        notes().forget(.parakeetV3)

        #expect(notes().needsPreparing(.parakeetV3))
        #expect(!notes().needsPreparing(.whisperLargeTurbo))
    }

    @Test func theAppsOwnStampNamesTheBuildAndTheSystem() throws {
        let build = try #require(Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
        let stamp = PreparedModels.standard.stamp

        #expect(stamp.hasPrefix("\(build) | "))
        #expect(stamp.contains(Bundle.main.bundlePath))
        #expect(stamp.hasSuffix(" | \(ProcessInfo.processInfo.operatingSystemVersionString)"))
    }
}
