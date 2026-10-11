import Foundation

/// Sends an audio file to OpenAI's speech-to-text endpoint with the user's own key.
struct OpenAITranscriber: Sendable {
    struct Options: Sendable, Equatable {
        var model: String
        /// ISO-639-1 code, or empty to let OpenAI detect it.
        var languageCode: String = ""
        /// Names and jargon, one per line.
        var vocabulary: String = ""
    }

    var baseURL: URL = AppSettings.apiBaseURL
    var session: URLSession = .shared

    func transcribe(fileURL: URL, apiKey: String, options: Options) async throws -> String {
        let audio = try Data(contentsOf: fileURL)
        let boundary = "od-\(UUID().uuidString)"

        var request = OpenAIAPI.request("audio/transcriptions", baseURL: baseURL, apiKey: apiKey, timeout: 60)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartForm.body(
            fields: Self.fields(for: options),
            fileName: fileURL.lastPathComponent,
            fileData: audio,
            boundary: boundary)

        let (data, response) = try await session.data(for: request)
        try OpenAIAPI.check(response, data)

        guard let decoded = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) else {
            throw OpenAIError.badResponse
        }
        let text = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw OpenAIError.noSpeech }
        return text
    }

    // MARK: - Request building

    /// Form fields in order. `gpt-transcribe` takes `languages[]` and `keywords[]`;
    /// the older models take `language` and a free-text `prompt`.
    static func fields(for options: Options) -> [(name: String, value: String)] {
        var fields = [(name: "model", value: options.model)]
        let language = options.languageCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let words = options.vocabulary
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "") }
            .filter { !$0.isEmpty }

        if options.model.hasPrefix("gpt-transcribe") {
            if !language.isEmpty { fields.append((name: "languages[]", value: language)) }
            for word in words { fields.append((name: "keywords[]", value: word)) }
        } else {
            if !language.isEmpty { fields.append((name: "language", value: language)) }
            if !words.isEmpty { fields.append((name: "prompt", value: words.joined(separator: ", "))) }
        }
        return fields
    }

    private struct TranscriptionResponse: Decodable {
        let text: String
    }
}
