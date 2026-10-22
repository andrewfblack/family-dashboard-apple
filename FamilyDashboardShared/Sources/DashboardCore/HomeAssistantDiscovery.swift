import Foundation

/// A Home Assistant instance found on the local network.
public struct DiscoveredServer: Identifiable, Hashable, Sendable {
    /// A stable identifier for the service.
    public let id: String
    /// The Bonjour service name.
    public let name: String
    /// The hostname resolved from Bonjour.
    public let host: String
    /// The advertised port.
    public let port: Int

    public init(id: String, name: String, host: String, port: Int) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
    }

    /// The HTTP address the dashboard can use.
    public var address: String {
        "http://\(host):\(port)"
    }
}

#if canImport(Darwin)
import Darwin

/// Finds Home Assistant instances advertised with Bonjour.
///
/// Home Assistant advertises `_home-assistant._tcp` on the local network.
/// Discovery is a convenience; users can still enter a URL manually for
/// Tailscale or reverse-proxy setups.
public final class HomeAssistantDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, @unchecked Sendable {
    private var browser: NetServiceBrowser?
    private var services: [String: NetService] = [:]
    private let lock = NSLock()
    private let callback: @Sendable ([DiscoveredServer]) -> Void

    public init(callback: @escaping @Sendable ([DiscoveredServer]) -> Void) {
        self.callback = callback
        super.init()
    }

    /// Begin searching the local network.
    public func start() {
        stop()
        let browser = NetServiceBrowser()
        browser.delegate = self
        self.browser = browser
        browser.searchForServices(ofType: "_home-assistant._tcp.", inDomain: "local.")
    }

    /// Stop searching and resolving services.
    public func stop() {
        browser?.stop()
        browser = nil
        lock.lock()
        let services = Array(self.services.values)
        self.services.removeAll()
        lock.unlock()
        services.forEach { $0.stop() }
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        lock.lock()
        services[serviceKey(service)] = service
        lock.unlock()
        service.resolve(withTimeout: 5)
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        lock.lock()
        services.removeValue(forKey: serviceKey(service))
        lock.unlock()
        publish()
    }

    public func netServiceDidResolveAddress(_ sender: NetService) {
        publish()
    }

    public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        lock.lock()
        services.removeValue(forKey: serviceKey(sender))
        lock.unlock()
        publish()
    }

    private func publish() {
        lock.lock()
        let values = services.values.compactMap { service -> DiscoveredServer? in
            guard let host = service.hostName, !host.isEmpty, service.port > 0 else { return nil }
            return DiscoveredServer(
                id: serviceKey(service),
                name: service.name,
                host: host,
                port: service.port
            )
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        lock.unlock()
        callback(values)
    }

    private func serviceKey(_ service: NetService) -> String {
        "\(service.name)|\(service.type)|\(service.domain)"
    }
}
#endif
