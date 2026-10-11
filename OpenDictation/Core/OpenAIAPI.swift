import Foundation

enum OpenAIError: LocalizedError, Equatable {
    case missingKey
    case api(status: Int, code: String?, message: String)
    case badResponse
    /// OpenAI answered but stopped early, for example at the length limit.
    case incomplete(reason: String)
    case noSpeech

    var errorDescription: String? {
        switch self {
        case .missingKey: "Add your OpenAI key in the app first."
        case .api where isMissingPermission:
            "This key is not allowed to do that. Check its permissions at OpenAI."
        case .api(let status, let code, let message):
            switch (status, code) {
            case (401, _): "OpenAI did not accept the key. Check it in Settings."
            case (429, "credit_balance_exhausted"), (429, "insufficient_quota"):
                "Your OpenAI account is out of credit."
            default: message
            }
        case .badResponse: "OpenAI sent back something unexpected."
        case .incomplete(let reason): "OpenAI stopped before it finished (\(reason))."
        case .noSpeech: "No speech was heard."
        }
    }

    /// The key is real but restricted, and lacks the permission this call needs.
    /// OpenAI answers that with 401, the same status as a wrong key, so the wording has to tell them apart.
    var isMissingPermission: Bool {
        guard case .api(let status, let code, let message) = self, status == 401 || status == 403 else {
            return false
        }
        let wording = message.lowercased()
        return code == "missing_scope"
            || wording.contains("insufficient permissions")
            || wording.contains("missing scopes")
    }
}

/// What the transcription and rewrite calls share.
enum OpenAIAPI {
    static func request(_ path: String, baseURL: URL, apiKey: String, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.timeoutInterval = timeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    static func check(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let apiError = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error
            throw OpenAIError.api(
                status: http.statusCode,
                code: apiError?.code ?? apiError?.type,
                message: apiError?.message ?? "OpenAI returned error \(http.statusCode).")
        }
    }

    /// A cheap check that the key works, without sending any audio.
    static func validate(
        apiKey: String, baseURL: URL = AppSettings.apiBaseURL, session: URLSession = .shared
    ) async throws {
        let request = request("models", baseURL: baseURL, apiKey: apiKey, timeout: 20)
        let (data, response) = try await session.data(for: request)
        try check(response, data)
    }

    private struct ErrorResponse: Decodable {
        struct APIError: Decodable {
            let message: String?
            let type: String?
            let code: String?
        }
        let error: APIError
    }
}
