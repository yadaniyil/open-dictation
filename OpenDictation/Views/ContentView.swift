import SwiftUI

/// The main screen. A new user sees two things to do: get something that listens, and set up
/// the one best way to start a dictation on this iPhone. Once that is done the screen is just
/// a reminder of how it goes, a place to try it, and the last texts.
struct ContentView: View {
    /// Which way to start is shown: the Action Button where there is one, Control Center elsewhere.
    var hasActionButton = DeviceModel.hasActionButton

    private let controller = DictationController.shared
    private let speechModels = SpeechModelStore.shared

    /// Set by the first dictation the shortcut starts, or by the user.
    @AppStorage(SetupProgress.doneKey) private var isSetUp = false
    @State private var settings: SettingsSheet?
    @State private var showsStats = false

    private var guide: Tutorial { Tutorial.best(hasActionButton: hasActionButton) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomeTopBar(openStats: { showsStats = true }, openSettings: { settings = SettingsSheet() })

                    Text(isSetUp ? "Ready" : "Set it up once")
                        .font(HomeStyle.titleFont)
                        .tracking(HomeStyle.titleTracking)
                        .foregroundStyle(HomeStyle.text)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, HomeStyle.barToTitle)
                        .padding(.bottom, HomeStyle.titleToContent)

                    VStack(alignment: .leading, spacing: HomeStyle.sectionSpacing) {
                        // First, because a download takes a while and can run during the steps.
                        if !speechModels.canListen {
                            SpeechModelCard(store: speechModels) { settings = SettingsSheet() }
                        } else if speechModels.isPreparing {
                            PreparingCard()
                        }
                        if isSetUp {
                            ReadyCard(guide: guide) { withAnimation { isSetUp = false } }
                        } else {
                            SetupSteps(guide: guide) { withAnimation { isSetUp = true } }
                        }
                        if speechModels.canListen {
                            TryItRow(controller: controller, speechModels: speechModels) { provider in
                                settings = SettingsSheet(provider: provider)
                            }
                        }
                        if controller.hasUnsentRecording {
                            UnsentRecordingCard(controller: controller)
                        }
                        if !controller.history.items.isEmpty {
                            RecentTexts(history: controller.history)
                        }
                    }
                    // The card comes and goes by itself, so the rest makes room gently.
                    .animation(.default, value: speechModels.isPreparing)
                }
                .padding(.horizontal, HomeStyle.sideMargin)
                .padding(.top, HomeStyle.topMargin)
                .padding(.bottom, HomeStyle.bottomMargin)
            }
            .background(HomeStyle.background)
            // The page has its own top bar. The name is what a guide's back button goes back to.
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $settings) { sheet in
                SettingsView(opening: sheet.provider)
            }
            .sheet(isPresented: $showsStats) {
                NavigationStack {
                    YourStatsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showsStats = false }
                            }
                        }
                }
            }
        }
    }
}

/// Settings as a sheet, optionally opened on one provider's screen.
private struct SettingsSheet: Identifiable {
    let id = UUID()
    var provider: SpeechModel?
}

#Preview("With an Action Button") {
    ContentView(hasActionButton: true)
}

#Preview("Without one") {
    ContentView(hasActionButton: false)
}
