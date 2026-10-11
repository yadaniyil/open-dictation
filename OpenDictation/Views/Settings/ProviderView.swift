import SwiftUI

/// One provider's own screen: what it is, whether it is set up, its key or its download,
/// and the button that puts it to use.
struct ProviderView: View {
    let model: SpeechModel
    let store: SpeechModelStore

    @FocusState private var keyFieldFocused: Bool

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    SettingsTile(symbol: model.symbol, tint: model.tint, side: 56)
                    Text(model.name)
                        .font(.title2.weight(.bold))
                    Text(model.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                statusRow
            } footer: {
                if store.fellBackFrom == model {
                    Text("\(model.name) is no longer set up, so dictation went back to OpenAI.")
                }
            }

            if model.isOnDevice {
                ProviderDownloadSection(model: model, store: store)
            } else {
                ProviderKeySection(model: model, store: store, fieldFocused: $keyFieldFocused)
            }
            if model == .openAI {
                OpenAIModelSection()
            }
        }
        .navigationTitle(model.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        // Pinned under the list, so the one action that matters is in reach however long the screen is.
        // It steps aside for the keyboard, which would push it over the Save button.
        .safeAreaBar(edge: .bottom) {
            if !keyFieldFocused {
                useButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    private var status: SpeechModelStore.Status { store.status(of: model) }

    /// Says in words what the check mark in the list means.
    private var statusRow: some View {
        Label {
            Text(model.statusText(status))
        } icon: {
            switch status {
            case .ready: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .notSetUp: Image(systemName: "circle.dashed").foregroundStyle(.secondary)
            case .downloading(let progress): ProgressRing(progress: progress)
            case .failed: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("providerStatus")
    }

    /// Picking is always the user's own tap: saving a key or finishing a download never switches by itself.
    @ViewBuilder private var useButton: some View {
        if store.selected == model {
            Label("In use", systemImage: "checkmark")
                .font(.headline)
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.tint.opacity(0.15), in: Capsule())
                .accessibilityIdentifier("inUse")
        } else {
            Button {
                store.select(model)
            } label: {
                Text("Use for dictation")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(status != .ready)
            .accessibilityIdentifier("useForDictation")
        }
    }
}

#Preview {
    NavigationStack { ProviderView(model: .parakeetV3, store: .shared) }
}
