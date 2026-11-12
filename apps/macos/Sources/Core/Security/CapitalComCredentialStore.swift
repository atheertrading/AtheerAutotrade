import Foundation
import Security

struct CapitalComCredentials: Codable, Equatable {
    let apiKey: String
    let identifier: String
    let password: String
}

/// Stores Capital.com secrets as one generic-password item in the macOS Keychain.
/// Secrets are never written to UserDefaults, files, process arguments, or logs.
enum CapitalComCredentialStore {
    private static let service = "com.atheertrading.desktop.capitalcom"
    private static let account = "primary-demo-credentials-v1"

    static var hasSavedCredentials: Bool {
        var query = baseQuery
        query[kSecReturnAttributes as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    /// Reads and decodes the single credential record from Keychain.
    /// A missing item returns nil; Keychain and decoding failures remain explicit.
    static func load() throws -> CapitalComCredentials? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw CapitalComCredentialStoreError.keychainStatus(status)
        }

        guard let data = result as? Data else {
            throw CapitalComCredentialStoreError.invalidStoredData
        }

        do {
            return try JSONDecoder().decode(CapitalComCredentials.self, from: data)
        } catch {
            throw CapitalComCredentialStoreError.invalidStoredData
        }
    }

    static func save(_ credentials: CapitalComCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        let query = baseQuery
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw CapitalComCredentialStoreError.keychainStatus(updateStatus)
        }

        var insertion = query
        insertion[kSecValueData as String] = data
        let addStatus = SecItemAdd(insertion as CFDictionary, nil)

        guard addStatus == errSecSuccess else {
            throw CapitalComCredentialStoreError.keychainStatus(addStatus)
        }

        guard try load() == credentials else {
            throw CapitalComCredentialStoreError.verificationFailed
        }
    }

    static func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CapitalComCredentialStoreError.keychainStatus(status)
        }
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum CapitalComCredentialStoreError: LocalizedError {
    case keychainStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .keychainStatus(let status):
            return "Keychain operation failed (OSStatus \(status))."
        }
    }
}
