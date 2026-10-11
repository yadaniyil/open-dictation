import SwiftUI

/// The key of a cloud provider: paste, save, see its last four characters, remove.
/// How to get one is `ProviderKeySteps`, just under it on the screen.
struct ProviderKeySection: View {
    let model: SpeechModel
    let store: SpeechModelStore
    /// Owned by the screen, which makes room for the keyboard while the field is in use.
    let fieldFocused: FocusState<Bool>.Binding

    @State private var draft = ""
    @State private var savedHint: String?
    @State private var outcome: Outcome = .none

    private enum Outcome: Equatable {
        case none
        case checking
        case works
        /// Saved, but nothing here can prove that it works.
        case unchecked(String)
        case problem(String)
    }

    init(model: SpeechModel, store: SpeechModelStore, fieldFocused: FocusState<Bool>.Binding) {
        self.model = model
        self.store = store
        self.fieldFocused = fieldFocused
        _savedHint = State(initialValue: Self.hint(for: model.savedKey))
    }

    var body: some View {
        Section {
            if let savedHint {
                LabeledContent("Saved key", value: savedHint)
            }
            SecureField(savedHint == nil ? "Paste your key" : "Paste a new key", text: $draft)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused(fieldFocused)
                // The keyboard can cover the Save row, so its own key saves too.
                .submitLabel(.done)
                .onSubmit(save)
                .accessibilityIdentifier("apiKeyField")
            // A filled button, so it cannot be taken for a second field under the first.
            Button(action: save) {
                Text(checksKey ? "Save and check" : "Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSave)
            .padding(.vertical, 4)
            .accessibilityIdentifier("saveKey")
            switch outcome {
            case .none: EmptyView()
            case .checking: Label("Checking…", systemImage: "hourglass")
            case .works: Label("The key works.", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            case .unchecked(let note): Label(note, systemImage: "checkmark.circle")
            case .problem(let message): Label(message, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
            if savedHint != nil {
                Button("Remove key", role: .destructive, action: remove)
            }
        } header: {
            Text("Key")
        } footer: {
            Text(footer)
        }
    }

    /// OpenAI has a free call that tells a good key from a bad one. ElevenLabs has none that a
    /// restricted key is sure to pass, so there the first dictation is the check.
    private var checksKey: Bool { model == .openAI }

    private var footer: String {
        switch model {
        case .elevenLabs:
            "The key is stored in this phone's Keychain and is only sent to ElevenLabs."
        default:
            "The key is stored in this phone's Keychain and is only sent to OpenAI.\n\nThis key is also used for styles and spoken instructions, whichever provider listens."
        }
    }

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && outcome != .checking
    }

    private func save() {
        guard canSave, let account = model.keychainAccount else { return }
        let key = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try KeychainStore.write(key, account: account)
        } catch {
            outcome = .problem(error.localizedDescription)
            return
        }
        // The field keeps showing the old dots if it is emptied while it still has the keyboard.
        fieldFocused.wrappedValue = false
        draft = ""
        savedHint = Self.hint(for: key)
        store.keysChanged()
        guard checksKey else {
            outcome = .unchecked("Saved. Try a dictation to check it.")
            return
        }
        outcome = .checking
        Task {
            do {
                try await OpenAIAPI.validate(apiKey: key)
                outcome = .works
            } catch let error as OpenAIError where error.isMissingPermission {
                outcome = .unchecked("Saved. This key is restricted, so it can't be checked here. Try a dictation.")
            } catch {
                outcome = .problem(error.localizedDescription)
            }
        }
    }

    private func remove() {
        guard let account = model.keychainAccount else { return }
        KeychainStore.delete(account)
        savedHint = Self.hint(for: model.savedKey)
        outcome = .none
        store.keysChanged()
    }

    private static func hint(for key: String?) -> String? {
        guard let key else { return nil }
        return "••••" + key.suffix(4)
    }
}

/// Which of OpenAI's speech models to ask for. Shown on OpenAI's screen only.
struct OpenAIModelSection: View {
    @State private var model = AppSettings.model

    var body: some View {
        Section("Advanced") {
            Picker("Speech model", selection: $model) {
                ForEach(choices, id: \.self) { Text($0).tag($0) }
            }
        }
        .onChange(of: model) { AppSettings.model = model }
    }

    private var choices: [String] {
        AppSettings.suggestedModels.contains(model) ? AppSettings.suggestedModels : AppSettings.suggestedModels + [model]
    }
}
