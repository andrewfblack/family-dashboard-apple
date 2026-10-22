#if canImport(Security)
import Foundation
import Security

/// Keeps the credential in the keychain.
///
/// The credential is never written to user defaults, so it does not end up
/// in an unencrypted backup.
public actor KeychainCredentialStore: CredentialStoring {
    private let service: String
    private let account: String

    public init(service: String = "com.familydashboard.dashboard", account: String = "device-token") {
        self.service = service
        self.account = account
    }

    public func load() async -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return nil }
        return token
    }

    public func save(_ token: String) async {
        guard let data = token.data(using: .utf8) else { return }
        let query = baseQuery
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    public func clear() async {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
#endif
