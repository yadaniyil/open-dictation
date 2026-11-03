import Foundation
import Testing
@testable import OpenDictation

/// The upload both cloud speech services take.
struct MultipartFormTests {
    @Test func theFieldsComeFirstThenTheFile() {
        let body = MultipartForm.body(
            fields: [(name: "model", value: "gpt-transcribe"), (name: "languages[]", value: "uk")],
            fileName: "in-work.m4a", fileData: Data("AUDIO".utf8), boundary: "od-1")

        #expect(String(decoding: body, as: UTF8.self) == """
            --od-1\r
            Content-Disposition: form-data; name="model"\r
            \r
            gpt-transcribe\r
            --od-1\r
            Content-Disposition: form-data; name="languages[]"\r
            \r
            uk\r
            --od-1\r
            Content-Disposition: form-data; name="file"; filename="in-work.m4a"\r
            Content-Type: audio/mp4\r
            \r
            AUDIO\r
            --od-1--\r

            """)
    }

    @Test func theSoundIsSentByteForByte() {
        let sound = Data([0x00, 0xFF, 0x0D, 0x0A, 0x2D, 0x2D, 0x80])

        let body = MultipartForm.body(fields: [], fileName: "a.m4a", fileData: sound, boundary: "b")

        #expect(body.range(of: Data("\r\n\r\n".utf8) + sound + Data("\r\n--b--\r\n".utf8)) != nil)
        #expect(body.starts(with: Data("--b\r\nContent-Disposition: form-data; name=\"file\"".utf8)))
    }
}
