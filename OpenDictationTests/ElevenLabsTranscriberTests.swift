import Foundation
import Testing
@testable import OpenDictation

extension NetworkTests {
    struct ElevenLabsTranscriberTests {
        private func makeTranscriber() -> ElevenLabsTranscriber {
            ElevenLabsTranscriber(baseURL: NetworkTests.baseURL, session: NetworkTests.stubbedSession())
        }

        private func makeAudioFile() throws -> URL {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-\(UUID().uuidString).m4a")
            try Data("fake-audio".utf8).write(to: url)
            return url
        }

        private func transcribe(languageCode: String = "") async throws -> String {
            try await makeTranscriber().transcribe(fileURL: try makeAudioFile(), apiKey: "xi-test", languageCode: languageCode)
        }

        @Test func sendsMultipartRequestAndReturnsText() async throws {
            StubProtocol.reset(status: 200, body: #"{"language_code":"ukr","text":"  Привіт усім  ","words":[]}"#)

            let text = try await transcribe()

            #expect(text == "Привіт усім")
            let request = try #require(StubProtocol.lastRequest)
            #expect(request.url?.absoluteString == "https://stub.test/v1/speech-to-text")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "xi-api-key") == "xi-test")
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            let body = String(decoding: try #require(StubProtocol.lastBody), as: UTF8.self)
            #expect(body.contains("name=\"model_id\"\r\n\r\nscribe_v2\r\n"))
            #expect(body.contains("name=\"file\"; filename=\"test-"))
            #expect(body.contains("Content-Type: audio/mp4\r\n\r\nfake-audio"))
            // No language was picked, so ElevenLabs detects it. Key terms cost extra and are never sent.
            #expect(!body.contains("language_code"))
            #expect(!body.contains("keyterms"))
        }

        @Test func pickedLanguageIsSent() async throws {
            StubProtocol.reset(status: 200, body: #"{"text":"Cześć"}"#)

            _ = try await transcribe(languageCode: " PL ")

            let body = String(decoding: try #require(StubProtocol.lastBody), as: UTF8.self)
            #expect(body.contains("name=\"language_code\"\r\n\r\npl\r\n"))
            #expect(ElevenLabsTranscriber.fields(languageCode: "").map(\.name) == ["model_id"])
        }

        @Test func keyWithoutThePermissionSaysSo() async throws {
            StubProtocol.reset(status: 401, body: """
                {"detail":{"type":"authentication_error","code":"unauthorized","message":"The API key you used is \
                missing the permission speech_to_text to execute this operation.","status":"missing_permissions",\
                "request_id":"abc"}}
                """)

            do {
                _ = try await transcribe()
                Issue.record("expected an error")
            } catch let error as ElevenLabsError {
                #expect(error == .api(
                    status: 401, reason: "missing_permissions",
                    message: "The API key you used is missing the permission speech_to_text to execute this operation."))
                #expect(error.errorDescription
                    == "This key is not allowed to do speech to text. Check its permissions at ElevenLabs.")
            }
        }

        @Test func wrongKeySaysSo() async throws {
            StubProtocol.reset(status: 401, body: #"{"detail":{"status":"invalid_api_key","message":"Invalid API key"}}"#)

            do {
                _ = try await transcribe()
                Issue.record("expected an error")
            } catch let error as ElevenLabsError {
                #expect(error.errorDescription == "ElevenLabs did not accept the key. Check it in Settings.")
            }
        }

        @Test func otherErrorsKeepTheirOwnWording() async throws {
            // `detail` is not always an object.
            StubProtocol.reset(status: 400, body: #"{"detail":"The file is too long."}"#)
            await #expect(throws: ElevenLabsError.api(status: 400, reason: nil, message: "The file is too long.")) {
                try await transcribe()
            }

            // A validation error sends a list. Nothing readable in it, so the status has to do.
            StubProtocol.reset(status: 422, body: #"{"detail":[{"loc":["body","file"],"msg":"field required"}]}"#)
            await #expect(throws: ElevenLabsError.api(status: 422, reason: nil, message: "ElevenLabs returned error 422.")) {
                try await transcribe()
            }
        }

        @Test func emptyTextCountsAsNoSpeech() async throws {
            StubProtocol.reset(status: 200, body: #"{"text":" \n"}"#)

            await #expect(throws: ElevenLabsError.noSpeech) {
                try await transcribe()
            }
        }
    }
}
