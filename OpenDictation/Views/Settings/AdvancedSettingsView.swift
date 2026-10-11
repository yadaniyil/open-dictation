import SwiftUI

/// The testing aid and the one clean-up action.
struct AdvancedSettingsView: View {
    @State private var keepsRecordings = AppSettings.keepsRecordings

    var body: some View {
        List {
            Section {
                Toggle("Keep recordings", isOn: $keepsRecordings)
            } footer: {
                Text("Keeps your last 20 recordings on this phone, so the same audio can be tried with other speech services. Turning it off deletes them.")
            }

            Section {
                Button("Clear recent dictations", role: .destructive) {
                    DictationController.shared.history.clear()
                }
            } footer: {
                Text("Removes the Recent list from the main screen.")
            }
        }
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: keepsRecordings) {
            AppSettings.keepsRecordings = keepsRecordings
            if !keepsRecordings { RecordingArchive.shared.clear() }
        }
    }
}
