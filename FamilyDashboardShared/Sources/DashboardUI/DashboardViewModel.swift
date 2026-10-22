#if canImport(SwiftUI)
import DashboardCore
import Foundation
import Observation
import SwiftUI

/// What the screens read and do.
///
/// The model owns the session, keeps the dashboard up to date through the
/// live update stream, and holds the state of the pairing flow.
@MainActor
@Observable
public final class DashboardViewModel {
    /// The dashboard, when it has been read.
    public private(set) var payload: DashboardPayload?
    /// Whether the dashboard is being read.
    public private(set) var isLoading = false
    /// The last error, when something went wrong.
    public private(set) var errorMessage: String?
    /// Whether this device is paired.
    public private(set) var isPaired = false
    /// The code to show the user while pairing.
    public private(set) var pairingCode: String?
    /// Whether the app is waiting for an approval.
    public private(set) var isWaitingForApproval = false
    /// Home Assistant instances found on the local network.
    public private(set) var discoveredServers: [DiscoveredServer] = []
    /// The address of the Home Assistant instance.
    public var serverAddress: String
    /// The tab that is open.
    public var selectedTab: DashboardTab = .home
    /// The name of this device, shown when it asks to pair.
    public var deviceName: String = ProcessInfo.processInfo.hostName
    /// The platform this app runs on.
    public let platform: String

    private let session: DashboardSession
    private let appVersion: String
    private var streamTask: Task<Void, Never>?
    private var discovery: HomeAssistantDiscovery?

    /// Create the model.
    public init(
        session: DashboardSession = DashboardSession(),
        platform: String,
        appVersion: String = "1.0"
    ) {
        self.session = session
        self.platform = platform
        self.appVersion = appVersion
        self.serverAddress = ServerConfiguration.defaultServerAddress
    }

    /// The colours of the dashboard.
    public var theme: Theme {
        payload?.theme ?? Theme()
    }

    /// The tabs to show.
    public var tabs: [DashboardTab] {
        payload?.enabledTabs ?? [.home]
    }

    /// Load the stored credential, read the dashboard and open the stream.
    public func start() async {
        // Keep the paired state even if the first network request is
        // temporarily unavailable. A Tailscale/VPN transition or an app
        // update must not send the user through pairing again.
        isPaired = await session.hasStoredCredential()
        do {
            let configuration = await session.configuration
            serverAddress = configuration.address
            let restored = try await session.restore()
            isPaired = await session.hasStoredCredential()
            if restored != nil {
                payload = restored
                startStream()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            isPaired = await session.hasStoredCredential()
        }
    }

    /// Read the dashboard again.
    public func refresh() async {
        guard isPaired else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            payload = try await session.refresh()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Run a command and read the dashboard again.
    public func run(_ action: DashboardAction) async {
        do {
            payload = try await session.run(action)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Ask to pair this device and show the code.
    public func requestPairing() async {
        isWaitingForApproval = true
        defer { isWaitingForApproval = false }
        do {
            let request = try await session.requestPairing(
                deviceName: deviceName,
                platform: platform,
                appVersion: appVersion
            )
            pairingCode = request.deviceCode
            errorMessage = nil
            let credential = try await session.awaitApproval(
                deviceCode: request.deviceCode,
                pollInterval: request.pollInterval,
                timeout: TimeInterval(request.expiresIn)
            )
            pairingCode = nil
            isPaired = true
            payload = try await session.refresh()
            startStream()
        } catch {
            pairingCode = nil
            errorMessage = error.localizedDescription
        }
    }

    /// Pair with the short code from Home Assistant.
    public func pair(with code: String) async {
        isWaitingForApproval = true
        defer { isWaitingForApproval = false }
        do {
            _ = try await session.pair(code: code, deviceName: deviceName, platform: platform)
            isPaired = true
            pairingCode = nil
            payload = try await session.refresh()
            errorMessage = nil
            startStream()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Point the app at another Home Assistant instance.
    public func setServer(_ address: String) async {
        do {
            let configuration = try ServerConfiguration.make(from: address)
            await session.setServer(configuration)
            serverAddress = configuration.address
            isPaired = false
            payload = nil
            pairingCode = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Forget this device on the server and in the keychain.
    public func unpair() async {
        await session.unpair()
        isPaired = false
        payload = nil
        pairingCode = nil
        streamTask?.cancel()
        streamTask = nil
    }

    /// Clear the last error.
    public func clearError() {
        errorMessage = nil
    }

    /// Search the local network for Home Assistant.
    public func startDiscovery() {
        #if canImport(Darwin)
        discovery?.stop()
        let finder = HomeAssistantDiscovery { [weak self] servers in
            Task { @MainActor in
                self?.discoveredServers = servers
            }
        }
        discovery = finder
        finder.start()
        #endif
    }

    /// Stop searching the local network.
    public func stopDiscovery() {
        discovery?.stop()
        discovery = nil
    }

    /// Use a discovered Home Assistant instance.
    public func useServer(_ server: DiscoveredServer) async {
        await setServer(server.address)
        stopDiscovery()
    }

    /// Build the authenticated request for an uploaded dashboard background.
    public func backgroundRequest() async -> URLRequest? {
        try? await session.homeAssistant.makeRequest(
            path: "/api/family_dashboard/device/background"
        )
    }

    // MARK: - Live updates

    /// Open the live update stream and keep it open.
    private func startStream() {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let configuration = await self.session.configuration
                for await event in LiveUpdates.events(configuration: configuration) {
                    guard !Task.isCancelled else { return }
                    self.apply(event)
                }
                // The stream dropped, so wait a moment and try again.
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    /// Fold one event from the stream into the dashboard.
    private func apply(_ event: StreamEvent) {
        switch event {
        case let .dashboard(payload):
            self.payload = payload
        case let .state(entityID, state, attributes):
            guard let payload else { return }
            self.payload = payload.applying(
                StateChange(entityID: entityID, state: state, attributes: attributes)
            )
        case .refresh:
            Task { await refresh() }
        }
    }
}
#endif
