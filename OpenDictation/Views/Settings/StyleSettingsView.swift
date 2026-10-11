import SwiftUI

/// The text step: spoken instructions, the user's own style, and the model that does it.
struct StyleSettingsView: View {
    /// The style in use. Writing custom instructions here switches it to Custom.
    @Binding var style: WritingStyle
    let store: SpeechModelStore

    @State private var followsSpokenInstructions = AppSettings.followsSpokenInstructions
    @State private var customInstructions = AppSettings.customInstructions
    @State private var rewriteModel = AppSettings.rewriteModel

    var body: some View {
        List {
            if store.status(of: .openAI) != .ready {
                Section {
                    Label("This step needs your OpenAI key. Without it the text is copied as spoken.", systemImage: "key.fill")
                    NavigationLink(value: SettingsRoute.provider(.openAI)) {
                        HStack(spacing: 12) {
                            ProviderLogo(model: .openAI, side: 29)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("OpenAI")
                                Text("Add the key")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Toggle("Spoken instructions", isOn: $followsSpokenInstructions)
            } footer: {
                Text("Start or end a dictation with something like \"give me this in Polish\" or \"make it formal\", and it is done for that one dictation. With the As spoken style this adds about two seconds.")
            }

            Section {
                TextEditor(text: $customInstructions)
                    .frame(minHeight: 110)
            } header: {
                Text("Custom style")
            } footer: {
                Text("Say how the text should come out, in any language. For example: \"Translate everything to Polish.\" Writing here switches the style to Custom.")
            }

            Section("Advanced") {
                LabeledContent("Style model") {
                    TextField(AppSettings.defaultRewriteModel, text: $rewriteModel)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
        }
        .navigationTitle("Style and instructions")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: followsSpokenInstructions) { AppSettings.followsSpokenInstructions = followsSpokenInstructions }
        .onChange(of: customInstructions) {
            AppSettings.customInstructions = customInstructions
            // Text typed here is meant to be used, so the Custom style is picked for the user.
            if WritingStyle.custom.instructions(custom: customInstructions) != nil {
                style = .custom
            }
        }
        .onChange(of: rewriteModel) { AppSettings.rewriteModel = rewriteModel }
    }
}
