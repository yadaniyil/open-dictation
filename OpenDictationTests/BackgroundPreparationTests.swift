import BackgroundTasks
import Foundation
import Testing
@testable import OpenDictation

/// The background window that prepares the model after an update, while the phone charges.
struct BackgroundPreparationTests {
    @Test func itOnlyAsksForAWindowWhileThePhoneCharges() {
        let request = BackgroundPreparation.request(notBefore: nil)

        #expect(request.identifier == BackgroundPreparation.identifier)
        #expect(request.requiresExternalPower)
        #expect(!request.requiresNetworkConnectivity)
        #expect(request.earliestBeginDate == nil)
    }

    @Test func afterAWindowTheNextOneWaits() {
        let next = Date(timeIntervalSinceNow: BackgroundPreparation.pause)
        #expect(BackgroundPreparation.request(notBefore: next).earliestBeginDate == next)
        #expect(BackgroundPreparation.pause >= 60 * 60)
    }

    /// iOS refuses a window whose name is not in the app's Info.plist, and gives none without
    /// the processing background mode.
    @Test func theAppIsAllowedToAskForIt() throws {
        let info = try #require(Bundle.main.infoDictionary)
        let names = try #require(info["BGTaskSchedulerPermittedIdentifiers"] as? [String])
        let modes = try #require(info["UIBackgroundModes"] as? [String])

        #expect(names.contains(BackgroundPreparation.identifier))
        #expect(modes.contains("processing"))
        // The microphone from the Action Button still needs this one.
        #expect(modes.contains("audio"))
    }
}
