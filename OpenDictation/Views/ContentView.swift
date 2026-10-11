import AVFoundation
import SwiftUI

struct ContentView: View {
    private let controller = DictationController.shared
    private let speechModels = SpeechModelStore.shared

    @State private var settings: SettingsSheet?
    @State private var style = AppSettings.style
    @State private var justCopied: HistoryStore.Item.ID?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    RecordPanel(controller: controller, missingKey: missingKey, toggle: toggle)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }

                Section {
                    StylePicker(style: $style)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Style")
                } footer: {
                    Text(styleFooter)
                }

                if let missingKey {
                    Section {
                        Button("Add your \(missingKey.name) key", systemImage: "key.fill") {
                            settings = SettingsSheet(provider: missingKey)
                        }
                    } footer: {
                        Text("\(missingKey.name) listens to your dictations, with your own account there. Settings has other choices, and the on-device ones need no account.")
                    }
                }

                if controller.hasUnsentRecording {
                    Section {
                        Button("Try the last recording again", systemImage: "arrow.clockwise") {
                            Task { await controller.retryUnsent() }
                        }
                        .disabled(controller.phase != .idle)
                        Button("Throw it away", systemImage: "trash", role: .destructive) {
                            controller.discardUnsent()
                        }
                    } footer: {
                        Text("The last recording was not turned into text. It is still saved on this phone.")
                    }
                }

                if !controller.history.items.isEmpty {
                    Section("Recent") {
                        ForEach(controller.history.items) { item in
                            HistoryRow(item: item, justCopied: justCopied == item.id) { copy(item) }
                        }
                        .onDelete { offsets in
                            offsets.map { controller.history.items[$0] }.forEach(controller.history.remove)
                        }
                    }
                }
            }
            .navigationTitle("Open Dictation")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { settings = SettingsSheet() }
                }
            }
            .sheet(item: $settings, onDismiss: refreshAfterSettings) { sheet in
                SettingsView(opening: sheet.provider)
            }
            .onChange(of: style) { AppSettings.style = style }
        }
    }

    private func refreshAfterSettings() {
        // Writing custom instructions in Settings picks the Custom style.
        style = AppSettings.style
    }

    /// The provider in use, while it still waits for its key. An on-device one never does.
    private var missingKey: SpeechModel? {
        speechModels.canListen ? nil : speechModels.selected
    }

    private var styleFooter: String {
        if style == .custom, style.instructions(custom: AppSettings.customInstructions) == nil {
            return "Write your own instructions in Settings first."
        }
        if style != .asSpoken, speechModels.status(of: .openAI) != .ready {
            return "Styles need an OpenAI key."
        }
        return style.summary
    }

    private func toggle() {
        Task {
            if AVAudioApplication.shared.recordPermission == .undetermined {
                _ = await AVAudioApplication.requestRecordPermission()
            }
            // The controller keeps the error to show under the button.
            _ = try? await controller.toggle()
        }
    }

    private func copy(_ item: HistoryStore.Item) {
        UIPasteboard.general.string = item.text
        justCopied = item.id
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if justCopied == item.id { justCopied = nil }
        }
    }
}

/// Settings as a sheet, optionally opened on one provider's screen.
private struct SettingsSheet: Identifiable {
    let id = UUID()
    var provider: SpeechModel?
}

private struct RecordPanel: View {
    let controller: DictationController
    /// The provider whose key has to be added before dictating, if any.
    let missingKey: SpeechModel?
    let toggle: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Button(action: toggle) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.accentColor)
                        .frame(width: 108, height: 108)
                    if controller.phase == .transcribing {
                        ProgressView()
                            .controlSize(.large)
                            .tint(.white)
                    } else {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(missingKey != nil || controller.phase == .transcribing)
            .opacity(missingKey == nil ? 1 : 0.4)
            .accessibilityLabel(isRecording ? "Stop and copy" : "Start dictating")
            .accessibilityIdentifier("recordButton")

            statusText
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("statusText")
        }
        .padding(.vertical, 12)
    }

    private var isRecording: Bool {
        if case .recording = controller.phase { true } else { false }
    }

    @ViewBuilder private var statusText: some View {
        switch controller.phase {
        case .recording(let startedAt):
            HStack(spacing: 6) {
                Text("Listening")
                Text(startedAt, style: .timer).monospacedDigit()
            }
        case .transcribing:
            Text("Working…")
        case .idle:
            // A missing key comes first: the button is off, and the last result does not say why.
            if let missingKey {
                Text("Add your \(missingKey.name) key to start.")
            } else {
                switch controller.lastMessage {
                case .copied(let note): result(note ?? "Copied. Paste it anywhere.", symbol: "checkmark.circle.fill")
                case .failed(let message): result(message, symbol: "exclamationmark.triangle.fill")
                case nil: Text("Tap to talk, or use the Action Button.")
                }
            }
        }
    }

    /// Not a `Label`: inside a list row that pushes the icon far away from the words.
    private func result(_ text: String, symbol: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
    }
}

private struct StylePicker: View {
    @Binding var style: WritingStyle

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(WritingStyle.allCases) { option in
                    Button(option.name) { style = option }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(option == style ? Color.white : Color.primary)
                        .background(Capsule().fill(option == style ? Color.accentColor : Color(.secondarySystemGroupedBackground)))
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(option == style ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
        }
        .scrollIndicators(.hidden)
    }
}

private struct HistoryRow: View {
    let item: HistoryStore.Item
    let justCopied: Bool
    let copy: () -> Void

    var body: some View {
        Button(action: copy) {
            VStack(alignment: .leading, spacing: 4) {
                // `Color.primary`, because plain `.primary` inside a button means the blue tint.
                Text(item.text)
                    .foregroundStyle(Color.primary)
                    .lineLimit(4)
                Text(justCopied ? "Copied" : item.date.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(justCopied ? Color.green : Color.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
