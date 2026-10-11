import Foundation
import Testing
@testable import OpenDictation

struct AcknowledgementsTests {
    @Test func bothTextsAreInTheApp() {
        let acknowledgements = LegalDocument.acknowledgements.text()
        #expect(acknowledgements.hasPrefix("Open Dictation is built with the work of other people."))
        #expect(acknowledgements.contains("FluidAudio"))
        #expect(acknowledgements.contains("WhisperKit"))

        let apache = LegalDocument.apacheLicense.text()
        #expect(apache.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("Apache License"))
        #expect(apache.contains("Version 2.0, January 2004"))
        #expect(apache.contains("END OF TERMS AND CONDITIONS"))

        for document in LegalDocument.allCases {
            #expect(!document.text().isEmpty, "\(document.rawValue).txt is missing or empty")
        }
    }

    @Test func aMissingFileIsEmptyText() {
        #expect(LegalDocument.acknowledgements.text(in: Bundle(for: BundleMarker.self)).isEmpty)
    }

    @Test func unwrappingKeepsEveryWordInOrder() {
        let original = LegalDocument.apacheLicense.text()
        let unwrapped = LegalDocument.unwrapped(original)
        #expect(words(in: unwrapped) == words(in: original))
        #expect(words(in: original).count > 1000)
    }

    @Test func unwrappingJoinsParagraphsAndKeepsTheTitleLines() {
        let wrapped = """

                                             Apache License
                                       Version 2.0, January 2004

               1. Definitions.

                  "License" shall mean the terms and conditions for use, reproduction,
                  and distribution as defined by Sections 1 through 9 of this document.

            """
        #expect(LegalDocument.unwrapped(wrapped) == """
            Apache License
            Version 2.0, January 2004

            1. Definitions.

            "License" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document.
            """)
    }

    /// The app's copy is the text inside the code fence of `ACKNOWLEDGEMENTS.md`.
    /// The Markdown file is read from the source folder, which the Simulator can see and a phone cannot.
    @Test(.enabled(if: FileManager.default.fileExists(atPath: markdownURL.path)))
    func theAppCopyMatchesTheMarkdownFile() throws {
        let markdown = try String(contentsOf: Self.markdownURL, encoding: .utf8)
        let parts = markdown.components(separatedBy: "```\n")
        try #require(parts.count == 3, "ACKNOWLEDGEMENTS.md should hold exactly one code fence")
        #expect(LegalDocument.acknowledgements.text() == parts[1])
    }

    private static let markdownURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ACKNOWLEDGEMENTS.md")

    private func words(in text: String) -> [Substring] {
        text.split(whereSeparator: \.isWhitespace)
    }
}

/// Only here so the tests can name their own bundle, which holds neither text file.
private final class BundleMarker {}
