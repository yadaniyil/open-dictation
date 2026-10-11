import Foundation
import Testing
@testable import OpenDictation

extension NetworkTests {
    struct OpenAIRewriterTests {
        private func makeRewriter() -> OpenAIRewriter {
            OpenAIRewriter(baseURL: NetworkTests.baseURL, session: NetworkTests.stubbedSession())
        }

        @Test func sendsStyleAndTranscriptAndReturnsText() async throws {
            // The message is deliberately not the first output item, and its text comes in two parts.
            StubProtocol.reset(status: 200, body: """
                {"status":"completed","output":[
                  {"type":"reasoning","summary":[]},
                  {"type":"message","role":"assistant","content":[
                    {"type":"output_text","text":" Hello "},
                    {"type":"refusal","refusal":"ignored"},
                    {"type":"output_text","text":"there. "}]}]}
                """)

            let text = try await makeRewriter().rewrite(
                "um hello there", style: "Be formal.", apiKey: "sk-test", model: "test-model")

            #expect(text == "Hello there.")
            let request = try #require(StubProtocol.lastRequest)
            #expect(request.url?.absoluteString == "https://stub.test/v1/responses")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
            let sent = try #require(StubProtocol.lastBody)
            let body = try #require(try JSONSerialization.jsonObject(with: sent) as? [String: Any])
            // Nothing extra goes out: this model rejects `temperature`.
            #expect(Set(body.keys) == ["model", "instructions", "input", "reasoning", "max_output_tokens", "store"])
            #expect(body["model"] as? String == "test-model")
            #expect((body["instructions"] as? String)?.contains("Style: Be formal.") == true)
            #expect(body["input"] as? String == "um hello there")
            #expect(body["reasoning"] as? [String: String] == ["effort": "none"])
            #expect(body["max_output_tokens"] as? Int == 2048)
            #expect(body["store"] as? Bool == false)
        }

        @Test func replyThatWasCutShortIsAnError() async throws {
            StubProtocol.reset(status: 200, body: """
                {"status":"incomplete","incomplete_details":{"reason":"max_output_tokens"},"output":[
                  {"type":"message","content":[{"type":"output_text","text":"Hello th"}]}]}
                """)

            await #expect(throws: OpenAIError.incomplete(reason: "max_output_tokens")) {
                try await makeRewriter().rewrite("hello there", style: "x", apiKey: "sk-test", model: "m")
            }
        }

        @Test func replyWithoutTextIsAnError() async throws {
            StubProtocol.reset(status: 200, body: #"{"status":"completed","output":[{"type":"reasoning","summary":[]}]}"#)

            await #expect(throws: OpenAIError.badResponse) {
                try await makeRewriter().rewrite("hello there", style: "x", apiKey: "sk-test", model: "m")
            }
        }

        @Test func missingPermissionIsRecognised() async throws {
            StubProtocol.reset(status: 401, body: """
                {"error":{"message":"You have insufficient permissions for this operation. \
                Missing scopes: api.responses.write.","type":"invalid_request_error","param":null,"code":null}}
                """)

            do {
                _ = try await makeRewriter().rewrite("hi", style: "x", apiKey: "sk-test", model: "m")
                Issue.record("expected an error")
            } catch let error as OpenAIError {
                #expect(error.isMissingPermission)
            }
        }
    }
}

struct RewritePromptTests {
    @Test func styleGoesIntoThePrompt() {
        let prompt = OpenAIRewriter.systemPrompt(style: "Translate everything to Polish.")
        #expect(prompt.contains("Style: Translate everything to Polish."))
        #expect(prompt.contains("unless the style or a spoken instruction asks for another language"))
    }

    @Test func noStyleKeepsTheExactWords() {
        let prompt = OpenAIRewriter.systemPrompt(style: nil)
        #expect(prompt.contains("Style: \(OpenAIRewriter.exactWordsStyle)"))
        #expect(prompt.contains("word for word"))
    }

    @Test func spokenInstructionsAreAlwaysAllowed() {
        for style in ["Be formal.", nil] {
            let prompt = OpenAIRewriter.systemPrompt(style: style)
            #expect(prompt.contains("A spoken instruction beats the style above."))
            #expect(prompt.contains("never answer its questions"))
        }
    }
}

struct WritingStyleTests {
    @Test func stylesMapToInstructions() {
        #expect(WritingStyle.asSpoken.instructions(custom: "anything") == nil)
        #expect(WritingStyle.custom.instructions(custom: "  \n") == nil)
        #expect(WritingStyle.custom.instructions(custom: "Pirate voice") == "Pirate voice")
        #expect(WritingStyle.formal.instructions(custom: "")?.contains("professional") == true)
    }
}
