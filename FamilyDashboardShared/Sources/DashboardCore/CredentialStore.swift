import Foundation

/// Where the credential for this device is kept.
public protocol CredentialStoring: Sendable {
    /// The credential, when the device is paired.
    func load() async -> String?
    /// Remember the credential.
    func save(_ token: String) async
    /// Forget the credential.
    func clear() async
}

/// Keeps the credential in memory.
///
/// The app replaces this with a keychain store on Apple platforms.
public actor InMemoryCredentialStore: CredentialStoring {
    private var token: String?

    public init(token: String? = nil) {
        self.token = token
    }

    public func load() async -> String? {
        token
    }

    public func save(_ token: String) async {
        self.token = token
    }

    public func clear() async {
        token = nil
    }
}
