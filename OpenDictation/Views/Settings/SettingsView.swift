import SwiftUI

/// The short top level of Settings. Everything with more than one control lives on its own screen.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private let speechModels = SpeechModelStore.shared

    @State private var path: [SettingsRoute]
    @State private var style = AppSettings.style
    @State private var languageCode = AppSettings.languageCode
    @State private var vocabulary = AppSettings.vocabulary
    @State private var maxMinutes = AppSettings.maxMinutes

    /// - Parameter provider: a provider whose own screen should be showing straight away.
    init(opening provider: SpeechModel? = nil) {
        _path = State(initialValue: provider.map { [.provider($0)] } ?? [])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(SpeechModel.allCases) { model in
                        NavigationLink(value: SettingsRoute.provider(model)) {
                            ProviderRow(model: model, store: speechModels)
                        }
                    }
                } header: {
                    Text("Speech")
                } footer: {
                    Text(speechFooter)
                }

                Section("Text") {
                    NavigationLink(value: SettingsRoute.style) {
                        SettingsRowLabel(title: "Style and instructions", subtitle: style.name, symbol: "wand.and.stars", tint: .pink)
                    }
                }

                Section {
                    Picker(selection: $languageCode) {
                        ForEach(DictationLanguage.all, id: \.code) { language in
                            Text(language.name).tag(language.code)
                        }
                    } label: {
                        SettingsRowLabel(title: "Language", symbol: "globe", tint: .blue)
                    }
                    .pickerStyle(.navigationLink)
                    NavigationLink(value: SettingsRoute.vocabulary) {
                        SettingsRowLabel(
                            title: "Words to get right", subtitle: VocabularyView.summary(of: vocabulary),
                            symbol: "character.book.closed.fill", tint: .brown)
                    }
                    Stepper(value: $maxMinutes, in: 1...30) {
                        SettingsRowLabel(title: "Stop after \(maxMinutes) min", symbol: "timer", tint: .gray)
                    }
                } header: {
                    Text("Dictation")
                } footer: {
                    Text("A recording you forget about stops by itself and is still turned into text.")
                }

                Section {
                    NavigationLink(value: SettingsRoute.setupGuide) {
                        SettingsRowLabel(title: "Action Button", subtitle: "How to set it up", symbol: "button.programmable", tint: .gray)
                    }
                }

                Section {
                    NavigationLink(value: SettingsRoute.advanced) {
                        SettingsRowLabel(title: "Advanced", symbol: "gearshape.fill", tint: .gray)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(privacyNote)
                        Text(Self.version)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .provider(let model): ProviderView(model: model, store: speechModels)
                case .style: StyleSettingsView(style: $style, store: speechModels)
                case .vocabulary: VocabularyView(vocabulary: $vocabulary)
                case .setupGuide: SetupGuideView()
                case .advanced: AdvancedSettingsView()
                }
            }
            .onChange(of: style) { AppSettings.style = style }
            .onChange(of: languageCode) { AppSettings.languageCode = languageCode }
            .onChange(of: vocabulary) { AppSettings.vocabulary = vocabulary }
            .onChange(of: maxMinutes) { AppSettings.maxMinutes = maxMinutes }
        }
    }

    private var speechFooter: String {
        let rule = "The one marked In use listens to you. Cloud ones need their key; on-device ones work offline."
        guard let lost = speechModels.fellBackFrom else { return rule }
        return "\(lost.name) is no longer set up, so dictation went back to OpenAI. " + rule
    }

    /// Where the voice goes, for whichever provider is in use.
    private var privacyNote: String {
        let text = "The text goes to OpenAI for styles and spoken instructions, when there is an OpenAI key. Recent text is kept on this phone only."
        switch speechModels.selected {
        case .openAI:
            return "Your voice goes straight from this phone to OpenAI with your key. Recent text is kept on this phone only."
        case .elevenLabs:
            return "Your voice goes straight from this phone to ElevenLabs with your key. " + text
        case .parakeetV3, .whisperLargeTurbo:
            return "Your voice stays on this phone. " + text
        }
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "Open Dictation \(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
