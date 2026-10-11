import SwiftUI

/// The download of an on-device model: start, watch, cancel, delete.
struct ProviderDownloadSection: View {
    let model: SpeechModel
    let store: SpeechModelStore

    @State private var confirmsDelete = false

    var body: some View {
        Section {
            switch store.status(of: model) {
            case .notSetUp:
                Button("Download (\(size))") { store.download(model) }
                    .accessibilityIdentifier("download")
            case .downloading(let progress):
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progress)
                    Text("\(SpeechModel.percent(progress)) of \(size)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                Button("Cancel") { store.cancelDownload(model) }
            case .ready:
                deleteButton
            case .preparing:
                // iOS is reading the files right now.
                deleteButton.disabled(true)
            case .failed:
                Button("Try again") { store.download(model) }
                // A download that stopped halfway keeps its files so it can carry on. This clears them.
                deleteButton
            }
        } header: {
            Text("Download")
        } footer: {
            Text("Your voice stays on this iPhone, and it works offline. Keep the app open while it downloads. After an update, open the app once so it can prepare the model again. A dictation before that takes much longer.")
        }
    }

    private var size: String { model.sizeLabel ?? "" }

    /// The question hangs off the button itself, which is where iOS points the bubble.
    private var deleteButton: some View {
        Button("Delete download", role: .destructive) { confirmsDelete = true }
            .accessibilityIdentifier("deleteDownload")
            .confirmationDialog("Delete \(model.name) from this iPhone?", isPresented: $confirmsDelete, titleVisibility: .visible) {
                Button("Delete download", role: .destructive) { store.delete(model) }
            } message: {
                Text("You can download it again later.")
            }
    }
}
