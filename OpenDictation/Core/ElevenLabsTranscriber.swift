import Foundation

enum ElevenLabsError: LocalizedError, Equatable {
    case missingKey
    /// `reason` is ElevenLabs' own word for what went wrong, such as "missing_permissions".
    case api(status: Int, reason: String?, message: String)
    case badResponse
    case noSpeech

    var errorDescription: String? {
        switch self {
        case .missingKey: "Add your ElevenLabs key in the app first."
        case .api(401, "missing_permissions", _):
            "This key is not allowed to do speech to text. Check its permissions at ElevenLabs."
        case .api(401, _, _): "ElevenLabs did not accept the key. Check it in Settings."
        case .api(_, _, let message): message
        case .badResponse: "ElevenLabs sent back something unexpected."
        case .noSpeech: "No speech was heard."
        }
    }
}

/// Sends an audio file to ElevenLabs' speech-to-text endpoint with the user's own key.
struct ElevenLabsTranscriber: Sendable {
    static let model = "scribe_v2"

    var baseURL: URL = AppSettings.elevenLabsBaseURL
    var session: URLSession = .shared

    /// - Parameter languageCode: ISO-639-1 code, or empty to let ElevenLabs detect it.
    func transcribe(fileURL: URL, apiKey: String, languageCode: String = "") async throws -> String {
        let audio = try Data(contentsOf: fileURL)
        let boundary = "od-\(UUID().uuidString)"

        var request = URLRequest(url: baseURL.appendingPathComponent("speech-to-text"))
        request.timeoutInterval = 60
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartForm.body(
            fields: Self.fields(languageCode: languageCode),
            fileName: fileURL.lastPathComponent,
            fileData: audio,
            boundary: boundary)

        let (data, response) = try await session.data(for: request)
        try Self.check(response, data)

        guard let decoded = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) else {
            throw ElevenLabsError.badResponse
        }
        let text = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ElevenLabsError.noSpeech }
        return text
    }

    /// Form fields in order. The "Words to get right" setting is left out on purpose:
    /// ElevenLabs takes such words as `keyterms` and charges 20% more for them.
    static func fields(languageCode: String) -> [(name: String, value: String)] {
        var fields = [(name: "model_id", value: model)]
        let language = languageCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !language.isEmpty { fields.append((name: "language_code", value: language)) }
        return fields
    }

    private static func check(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw ElevenLabsError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.detail
            throw ElevenLabsError.api(
                status: http.statusCode,
                reason: detail?.status,
                message: detail?.message ?? "ElevenLabs returned error \(http.statusCode).")
        }
    }

    private struct TranscriptionResponse: Decodable {
        let text: String
    }

    private struct ErrorResponse: Decodable {
        /// Usually an object with a `status` and a `message`, but some errors send a bare string.
        struct Detail: Decodable {
            let status: String?
            let message: String?

            init(from decoder: any Decoder) throws {
                if let text = try? decoder.singleValueContainer().decode(String.self) {
                    status = nil
                    message = text
                } else {
                    let fields = try decoder.container(keyedBy: CodingKeys.self)
                    status = try fields.decodeIfPresent(String.self, forKey: .status)
                    message = try fields.decodeIfPresent(String.self, forKey: .message)
                }
            }

            private enum CodingKeys: String, CodingKey {
                case status, message
            }
        }
        let detail: Detail
    }
}
