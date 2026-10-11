import SwiftUI

@main
struct OpenDictationApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onboarding()
                #if DEBUG
                .task { if ModelBenchmark.isRequested { await ModelBenchmark.run() } }
                #endif
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            DictationController.shared.appBecameActive()
            FirstModelDownload.resumeIfInterrupted()
            Task { await FirstModelDownload.startIfSensible() }
            // After an update the model in use has its slow first load ahead of it. Better now,
            // with the app open, than during the next dictation.
            SpeechModelStore.shared.prepareIfNeeded()
        }
    }
}
