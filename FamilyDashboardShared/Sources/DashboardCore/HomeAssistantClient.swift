import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Talks to the Family Dashboard API.
///
/// The client is an actor, so a caller can share one instance between the
/// dashboard, the pairing flow and the live update stream.
public actor HomeAssistantClient {
    /// The base URL of the Home Assistant instance.
    public private(set) var configuration: ServerConfiguration
    /// The session used for the requests.
    private let session: URLSession

    /// Create a client.
    public init(configuration: ServerConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    /// Point the client at another instance, keeping the credential.
    public func update(configuration: ServerConfiguration) {
        self.configuration = configuration
    }

    /// Read the dashboard.
    public func dashboard() async throws -> DashboardPayload {
        let request = try makeRequest(path: "/api/family_dashboard/device")
        let data = try await perform(request)
        return try decode(DashboardPayload.self, from: data)
    }

    /// Run a command.
    @discardableResult
    public func run(_ action: DashboardAction) async throws -> Bool {
        var request = try makeRequest(path: "/api/family_dashboard/device/action")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: action.body)
        _ = try await perform(request)
        return true
    }

    /// The address of the uploaded background image, if there is one.
    public func backgroundURL() -> URL {
        configuration.serverURL.appending(path: "/api/family_dashboard/device/background")
    }

    /// Ask to pair this device.
    public func requestPairing(
        deviceName: String,
        platform: String,
        appVersion: String
    ) async throws -> PairingRequest {
        var request = try makeRequest(path: "/api/family_dashboard/pairing/request", authenticated: false)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "device_name": deviceName,
                "platform": platform,
                "app_version": appVersion,
            ]
        )
        let data = try await perform(request)
        return try decode(PairingRequest.self, from: data)
    }

    /// Ask whether a pairing request was approved.
    public func pairingStatus(deviceCode: String) async throws -> PairingStatus {
        let request = try makeRequest(
            path: "/api/family_dashboard/pairing/status",
            authenticated: false,
            query: [URLQueryItem(name: "device_code", value: deviceCode)]
        )
        let data = try await perform(request)
        let response = try decode(PairingStatusResponse.self, from: data)
        return response.value
    }

    /// Trade the short pairing code for a credential.
    public func exchangeCode(
        _ code: String,
        deviceName: String,
        platform: String
    ) async throws -> DeviceCredential {
        var request = try makeRequest(path: "/api/family_dashboard/pairing/code", authenticated: false)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "code": code.uppercased(),
                "device_name": deviceName,
                "platform": platform,
            ]
        )
        let data = try await perform(request)
        return try decode(DeviceCredential.self, from: data)
    }

    // MARK: - Plumbing

    /// Build a request for the API.
    public func makeRequest(
        path: String,
        authenticated: Bool = true,
        query: [URLQueryItem] = []
    ) throws -> URLRequest {
        guard var components = URLComponents(
            url: configuration.serverURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else {
            throw DashboardError.invalidServerAddress(configuration.address)
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else {
            throw DashboardError.invalidServerAddress(configuration.address)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authenticated, let credential = configuration.credential, !credential.isEmpty {
            request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// Send a request and return the body.
    func perform(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw DashboardError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw DashboardError.transport("Home Assistant sent an unexpected answer.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(from: data, statusCode: http.statusCode)
        }
        return data
    }

    /// Turn an error answer into an error.
    static func error(from data: Data, statusCode: Int) -> DashboardError {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let code = object["error"] as? String {
            return DashboardError.fromServer(code: code)
        }
        if statusCode == 401 { return .invalidToken }
        if statusCode == 403 { return .notAllowed }
        if statusCode == 404 { return .unknownDeviceCode }
        return .unknown("Home Assistant answered with HTTP \(statusCode).")
    }

    /// Decode the body of an answer.
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw DashboardError.decoding("Home Assistant sent something this app could not read.")
        }
    }
}
