import Testing
@testable import OpenDictation

/// A restricted key without the right permission and a wrong key both come back as 401,
/// but the user has to fix them in different places.
struct OpenAIErrorTests {
    private let notAllowed = "This key is not allowed to do that. Check its permissions at OpenAI."
    private let notAccepted = "OpenAI did not accept the key. Check it in Settings."

    @Test(arguments: [
        OpenAIError.api(
            status: 401, code: "invalid_request_error",
            message: "You have insufficient permissions for this operation. Missing scopes: model.request."),
        OpenAIError.api(status: 401, code: "missing_scope", message: "Missing scopes: api.model.read"),
        OpenAIError.api(status: 403, code: nil, message: "Missing scopes: api.responses.write"),
    ])
    func restrictedKeyIsAMissingPermission(error: OpenAIError) {
        #expect(error.isMissingPermission)
        #expect(error.errorDescription == notAllowed)
    }

    @Test func wrongKeyIsNotAMissingPermission() {
        let error = OpenAIError.api(status: 401, code: "invalid_api_key", message: "Incorrect API key provided: sk-…")
        #expect(!error.isMissingPermission)
        #expect(error.errorDescription == notAccepted)
    }

    @Test func otherErrorsKeepTheirOwnWording() {
        // The words alone are not enough: the status has to be one OpenAI uses for keys.
        let serverError = OpenAIError.api(status: 500, code: nil, message: "insufficient permissions")
        #expect(!serverError.isMissingPermission)
        #expect(serverError.errorDescription == "insufficient permissions")

        let region = OpenAIError.api(
            status: 403, code: "unsupported_country_region_territory",
            message: "Country, region, or territory not supported")
        #expect(!region.isMissingPermission)
        #expect(region.errorDescription == "Country, region, or territory not supported")

        #expect(OpenAIError.incomplete(reason: "max_output_tokens").errorDescription
            == "OpenAI stopped before it finished (max_output_tokens).")
    }
}
