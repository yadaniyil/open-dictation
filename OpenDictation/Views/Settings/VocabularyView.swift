import SwiftUI

/// Names and jargon the speech model should spell right.
struct VocabularyView: View {
    @Binding var vocabulary: String

    var body: some View {
        List {
            Section {
                TextEditor(text: $vocabulary)
                    .frame(minHeight: 200)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } footer: {
                Text("Names and special words, one per line. Only OpenAI's speech model uses them.")
            }
        }
        .navigationTitle("Words to get right")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// "None", "1 word", "12 words": the line under the row in Settings.
    nonisolated static func summary(of vocabulary: String) -> String {
        let count = vocabulary
            .split(whereSeparator: \.isNewline)
            .count { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return count == 0 ? "None" : count == 1 ? "1 word" : "\(count) words"
    }
}
