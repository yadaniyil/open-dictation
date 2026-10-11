import SwiftUI

/// The notices that the licences of the speech models and libraries ask for,
/// followed by the Apache License in full.
struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                LegalText(text: LegalDocument.acknowledgements.text())
                    .accessibilityIdentifier("acknowledgementsText")
            }
            Section("Apache License 2.0") {
                LegalText(text: LegalDocument.unwrapped(LegalDocument.apacheLicense.text()))
                    .accessibilityIdentifier("apacheLicenseText")
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Small, plain and selectable: text to look something up in, not to read through.
private struct LegalText: View {
    let text: String

    var body: some View {
        Text(verbatim: text.trimmingCharacters(in: .whitespacesAndNewlines))
            .font(.footnote)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A text file that ships inside the app, in `OpenDictation/Resources`.
enum LegalDocument: String, CaseIterable {
    /// The text inside the code fence of `ACKNOWLEDGEMENTS.md`. Change the two together.
    case acknowledgements = "Acknowledgements"
    /// https://www.apache.org/licenses/LICENSE-2.0.txt, unchanged.
    case apacheLicense = "Apache-2.0"

    /// The file's text, or nothing if the file is not in the bundle.
    func text(in bundle: Bundle = .main) -> String {
        guard let url = bundle.url(forResource: rawValue, withExtension: "txt") else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    /// The Apache text is cut into lines of 76 characters, and a phone would cut each of them again.
    /// This puts every paragraph back on one line. No word is added, dropped or moved.
    /// The centred title lines at the top stay one to a line.
    static func unwrapped(_ text: String) -> String {
        var paragraphs: [String] = []
        var lines: [Substring] = []
        func closeParagraph() {
            guard !lines.isEmpty else { return }
            let isCentred = lines.allSatisfy { $0.prefix(while: { $0 == " " }).count > 16 }
            paragraphs.append(
                lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: isCentred ? "\n" : " "))
            lines = []
        }
        for line in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            if line.allSatisfy(\.isWhitespace) {
                closeParagraph()
            } else {
                lines.append(line)
            }
        }
        closeParagraph()
        return paragraphs.joined(separator: "\n\n")
    }
}

#Preview {
    NavigationStack { AcknowledgementsView() }
}
