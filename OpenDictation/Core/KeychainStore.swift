import Foundation
import Security

/// Stores the OpenAI and ElevenLabs keys in the Keychain. A key never leaves the device except in
/// requests to the service it belongs to.
enum KeychainStore {
    static let apiKeyAccount = "openai-api-key"
    static let elevenLabsKeyAccount = "elevenlabs-api-key"
    private static let service = "dev.yako.open-dictation"

    enum KeychainError: LocalizedError {
        case unhandled(OSStatus)

        var errorDescription: String? {
            switch self {
            case .unhandled(let status): "Could not save to the Keychain (error \(status))."
            }
        }
    }

    static func read(_ account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ value: String, account: String) throws {
        delete(account)
        var query = baseQuery(account)
        query[kSecValueData as String] = Data(value.utf8)
        // The Action Button can start a dictation while the phone is locked.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
    }

    static func delete(_ account: String) {
        SecItemDelete(baseQuery(account) as CFDictionary)
    }

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
