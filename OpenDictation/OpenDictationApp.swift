import SwiftUI

@main
struct OpenDictationApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // iOS only takes the handler for its background windows while the app launches.
        BackgroundPreparation.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onboarding()
                #if DEBUG
                .task { if ModelBenchmark.isRequested { await ModelBenchmark.run() } }
                #endif
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                // So that a window is waiting when the next update comes.
                BackgroundPreparation.ask()
            }
            guard scenePhase == .active else { return }
            DictationController.shared.appBecameActive()
            Task {
                await FirstModelDownload.resumeIfInterrupted()
                await FirstModelDownload.startIfSensible()
            }
            // After an update the model in use has its slow first load ahead of it. Better now,
            // with the app open, than during the next dictation.
            SpeechModelStore.shared.prepareIfNeeded()
        }
    }
}
