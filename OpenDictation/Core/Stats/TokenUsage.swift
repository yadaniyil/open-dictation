import Foundation

/// The tokens OpenAI counted for one text step. Only used for the cost estimate in the user's
/// own stats.
struct TokenUsage: Equatable, Sendable {
    let input: Int
    let output: Int
}

extension OpenAIRewriter {
    /// What the text step gives back.
    struct Reply: Equatable, Sendable {
        let text: String
        /// Nil when OpenAI left the counts out.
        let usage: TokenUsage?
    }

    /// Reads `usage` out of a Responses API reply. A reply without it is still a good reply.
    static func usage(in data: Data) -> TokenUsage? {
        guard let usage = (try? JSONDecoder().decode(UsageResponse.self, from: data))?.usage else { return nil }
        return TokenUsage(input: usage.inputTokens, output: usage.outputTokens)
    }

    private struct UsageResponse: Decodable {
        struct Usage: Decodable {
            let inputTokens: Int
            let outputTokens: Int

            private enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
            }
        }
        let usage: Usage?
    }
}
