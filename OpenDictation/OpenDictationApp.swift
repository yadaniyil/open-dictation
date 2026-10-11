import SwiftUI

@main
struct OpenDictationApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { DictationController.shared.appBecameActive() }
        }
    }
}
