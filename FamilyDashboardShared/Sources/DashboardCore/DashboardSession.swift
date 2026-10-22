import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Everything the app does with a Home Assistant instance.
///
/// The session owns the address, the credential and the dashboard payload, so
/// the screens only have to ask for what they need.
public actor DashboardSession {
    /// The address and the credential.
    public private(set) var configuration: ServerConfiguration
    /// The last dashboard that was read.
    public private(set) var payload: DashboardPayload?
    /// Where the credential is kept.
    private let credentialStore: CredentialStoring
    /// The client that talks to Home Assistant.
    private let client: HomeAssistantClient

    public init(
        configuration: ServerConfiguration = .default,
        credentialStore: CredentialStoring = InMemoryCredentialStore(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.credentialStore = credentialStore
        self.client = HomeAssistantClient(configuration: configuration, session: session)
    }

    /// The client, for the screens that need to open a stream.
    public var homeAssistant: HomeAssistantClient {
        client
    }

    /// Load the stored credential and read the dashboard.
    ///
    /// - Returns: the dashboard, or nil when the device is not paired yet.
    @discardableResult
    public func restore() async throws -> DashboardPayload? {
        let token = await credentialStore.load()
        guard let token, !token.isEmpty else {
            payload = nil
            return nil
        }
        configuration.credential = token
        await client.update(configuration: configuration)
        do {
            let payload = try await client.dashboard()
            self.payload = payload
            return payload
        } catch DashboardError.invalidToken {
            // The credential was revoked, so forget it.
            await credentialStore.clear()
            configuration.credential = nil
            self.payload = nil
            return nil
        }
    }

    /// Read the dashboard again.
    @discardableResult
    public func refresh() async throws -> DashboardPayload {
        let payload = try await client.dashboard()
        self.payload = payload
        return payload
    }

    /// Run a command and read the dashboard again.
    @discardableResult
    public func run(_ action: DashboardAction) async throws -> DashboardPayload {
        try await client.run(action)
        return try await refresh()
    }

    /// Point the session at another instance and forget the credential.
    public func setServer(_ server: ServerConfiguration) async {
        configuration = ServerConfiguration(serverURL: server.serverURL)
        await credentialStore.clear()
        payload = nil
        await client.update(configuration: configuration)
    }

    /// Ask to pair this device and return the code to show.
    public func requestPairing(
        deviceName: String,
        platform: String,
        appVersion: String
    ) async throws -> PairingRequest {
        try await client.requestPairing(
            deviceName: deviceName,
            platform: platform,
            appVersion: appVersion
        )
    }

    /// Wait for an administrator to approve a pairing request.
    public func awaitApproval(
        deviceCode: String,
        pollInterval: Int,
        timeout: TimeInterval
    ) async throws -> DeviceCredential {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try await Task.sleep(for: .seconds(max(1, pollInterval)))
            let status = try await client.pairingStatus(deviceCode: deviceCode)
            switch status {
            case let .approved(credential):
                try await store(credential)
                return credential
            case .denied:
                throw DashboardError.pairingDenied
            case .expired:
                throw DashboardError.pairingExpired
            case .consumed:
                throw DashboardError.pairingExpired
            case .pending:
                continue
            }
        }
        throw DashboardError.pairingExpired
    }

    /// Trade the short pairing code for a credential.
    public func pair(
        code: String,
        deviceName: String,
        platform: String
    ) async throws -> DeviceCredential {
        let credential = try await client.exchangeCode(
            code,
            deviceName: deviceName,
            platform: platform
        )
        try await store(credential)
        return credential
    }

    /// Remember the credential for this device.
    public func store(_ credential: DeviceCredential) async throws {
        await credentialStore.save(credential.token)
        configuration.credential = credential.token
        await client.update(configuration: configuration)
    }

    /// Forget the credential for this device.
    public func unpair() async {
        await credentialStore.clear()
        configuration.credential = nil
        payload = nil
        await client.update(configuration: configuration)
    }
}
