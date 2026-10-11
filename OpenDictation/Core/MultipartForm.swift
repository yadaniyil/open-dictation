import Foundation

/// The upload both cloud speech services take: a few text fields, then the audio file.
enum MultipartForm {
    static func body(
        fields: [(name: String, value: String)], fileName: String, fileData: Data, boundary: String
    ) -> Data {
        var body = Data()
        for field in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n")
            body.append("\(field.value)\r\n")
        }
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: audio/mp4\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
