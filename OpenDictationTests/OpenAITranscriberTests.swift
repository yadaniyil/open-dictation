import Foundation
import Testing
@testable import OpenDictation

extension NetworkTests {
    struct OpenAITranscriberTests {
        private func makeTranscriber() -> OpenAITranscriber {
            OpenAITranscriber(baseURL: NetworkTests.baseURL, session: NetworkTests.stubbedSession())
        }

        private func makeAudioFile() throws -> URL {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-\(UUID().uuidString).m4a")
            try Data("fake-audio".utf8).write(to: url)
            return url
        }

        @Test func sendsMultipartRequestAndReturnsText() async throws {
            StubProtocol.reset(status: 200, body: #"{"text":"  Hello there.  ","languages":[{"code":"en"}]}"#)
            let file = try makeAudioFile()

            let text = try await makeTranscriber().transcribe(
                fileURL: file, apiKey: "sk-test", options: .init(model: "gpt-transcribe"))

            #expect(text == "Hello there.")
            let request = try #require(StubProtocol.lastRequest)
            #expect(request.url?.absoluteString == "https://stub.test/v1/audio/transcriptions")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
            let body = String(decoding: try #require(StubProtocol.lastBody), as: UTF8.self)
            #expect(body.contains("name=\"model\"\r\n\r\ngpt-transcribe\r\n"))
            #expect(body.contains("name=\"file\"; filename=\"\(file.lastPathComponent)\""))
            #expect(body.contains("fake-audio"))
        }

        @Test func newModelUsesLanguagesAndKeywords() {
            let fields = OpenAITranscriber.fields(
                for: .init(model: "gpt-transcribe", languageCode: " UK ", vocabulary: "Kyiv\n\n <Yako> "))
            #expect(fields.map(\.name) == ["model", "languages[]", "keywords[]", "keywords[]"])
            #expect(fields.map(\.value) == ["gpt-transcribe", "uk", "Kyiv", "Yako"])
        }

        @Test func olderModelsUseLanguageAndPrompt() {
            let fields = OpenAITranscriber.fields(
                for: .init(model: "gpt-4o-mini-transcribe", languageCode: "en", vocabulary: "Kyiv\nYako"))
            #expect(fields.map(\.name) == ["model", "language", "prompt"])
            #expect(fields.last?.value == "Kyiv, Yako")
        }

        @Test func autoLanguageSendsOnlyTheModel() {
            let fields = OpenAITranscriber.fields(for: .init(model: "gpt-transcribe"))
            #expect(fields.map(\.name) == ["model"])
        }

        @Test func badKeyGivesReadableError() async throws {
            StubProtocol.reset(
                status: 401,
                body: #"{"error":{"message":"Incorrect API key provided: sk-…","type":"invalid_request_error","param":null,"code":"invalid_api_key"}}"#)

            await #expect(throws: OpenAIError.api(
                status: 401, code: "invalid_api_key", message: "Incorrect API key provided: sk-…")
            ) {
                let transcriber = makeTranscriber()
                try await OpenAIAPI.validate(apiKey: "sk-bad", baseURL: transcriber.baseURL, session: transcriber.session)
            }
            let error = OpenAIError.api(status: 401, code: "invalid_api_key", message: "x")
            #expect(error.errorDescription == "OpenAI did not accept the key. Check it in Settings.")
        }

        @Test func emptyTextCountsAsNoSpeech() async throws {
            StubProtocol.reset(status: 200, body: #"{"text":"  "}"#)
            let file = try makeAudioFile()

            await #expect(throws: OpenAIError.noSpeech) {
                try await makeTranscriber().transcribe(
                    fileURL: file, apiKey: "sk-test", options: .init(model: "gpt-transcribe"))
            }
        }
    }
}
