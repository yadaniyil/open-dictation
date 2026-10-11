import Foundation
import Testing
@testable import OpenDictation

extension NetworkTests {
    struct RewriteUsageTests {
        private func makeRewriter() -> OpenAIRewriter {
            OpenAIRewriter(baseURL: NetworkTests.baseURL, session: NetworkTests.stubbedSession())
        }

        @Test func theReplyCarriesTheTokenCounts() async throws {
            StubProtocol.reset(status: 200, body: """
                {"status":"completed","output":[
                  {"type":"message","content":[{"type":"output_text","text":"Hello there."}]}],
                 "usage":{"input_tokens":312,"input_tokens_details":{"cached_tokens":0},
                  "output_tokens":41,"output_tokens_details":{"reasoning_tokens":0},"total_tokens":353}}
                """)

            let reply = try await makeRewriter().rewrite("um hello there", style: nil, apiKey: "sk-test", model: "m")

            #expect(reply == OpenAIRewriter.Reply(text: "Hello there.", usage: TokenUsage(input: 312, output: 41)))
        }

        @Test func aReplyWithoutCountsIsStillAReply() async throws {
            StubProtocol.reset(status: 200, body: """
                {"status":"completed","output":[
                  {"type":"message","content":[{"type":"output_text","text":"Hello there."}]}]}
                """)

            let reply = try await makeRewriter().rewrite("um hello there", style: nil, apiKey: "sk-test", model: "m")

            #expect(reply == OpenAIRewriter.Reply(text: "Hello there.", usage: nil))
        }
    }
}

struct TokenUsageTests {
    @Test func usageIsReadFromAResponsesReply() {
        let reply = Data(#"{"status":"completed","usage":{"input_tokens":7,"output_tokens":3,"total_tokens":10}}"#.utf8)
        #expect(OpenAIRewriter.usage(in: reply) == TokenUsage(input: 7, output: 3))
    }

    @Test(arguments: [
        #"{"status":"completed"}"#,
        #"{"status":"completed","usage":null}"#,
        #"{"status":"completed","usage":{"total_tokens":10}}"#,
        #"{"usage":{"input_tokens":"seven","output_tokens":3}}"#,
        "not json",
        "",
    ])
    func anythingElseCountsAsNoUsage(reply: String) {
        #expect(OpenAIRewriter.usage(in: Data(reply.utf8)) == nil)
    }
}
