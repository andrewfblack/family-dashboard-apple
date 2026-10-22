import Foundation

/// The address of a Home Assistant instance and the credential to use.
///
/// The default is `http://homeassistant.local:8123`. That name matters on
/// Apple platforms: App Transport Security allows plain HTTP to a `.local`
/// host, but not to a bare IP address, so the default keeps the app working
/// without an exception.
public struct ServerConfiguration: Hashable, Sendable, Codable {
    /// The address the app starts with.
    public static let defaultServerAddress = "http://homeassistant.local:8123"

    /// The base URL of the Home Assistant instance.
    public var serverURL: URL

    /// The credential for this device, when it has one.
    public var credential: String?

    public init(serverURL: URL, credential: String? = nil) {
        self.serverURL = serverURL
        self.credential = credential
    }

    /// The configuration the app starts with.
    public static var `default`: ServerConfiguration {
        ServerConfiguration(serverURL: URL(string: defaultServerAddress)!)
    }

    /// The address as the user typed it.
    public var address: String {
        serverURL.absoluteString
    }

    /// Build a configuration from something the user typed.
    ///
    /// A missing scheme becomes `http`, and a trailing slash is removed so
    /// paths can be appended safely.
    public static func make(from address: String) throws -> ServerConfiguration {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DashboardError.invalidServerAddress(address)
        }
        let withScheme = trimmed.contains("://") ? trimmed : "http://\(trimmed)"
        guard var components = URLComponents(string: withScheme),
              let scheme = components.scheme,
              let host = components.host,
              !host.isEmpty
        else {
            throw DashboardError.invalidServerAddress(address)
        }
        components.scheme = scheme.lowercased()
        if components.path == "/" {
            components.path = ""
        }
        guard let url = components.url else {
            throw DashboardError.invalidServerAddress(address)
        }
        return ServerConfiguration(serverURL: url)
    }
}
