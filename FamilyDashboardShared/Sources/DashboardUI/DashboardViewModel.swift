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
    /// The locally preferred order of dashboard tabs on this device.
    public private(set) var tabOrder: [DashboardTab]
    /// The locally preferred order of remote players on this device.
    public private(set) var remoteOrder: [String]
    /// The locally preferred order of remote rooms on this device.
    public private(set) var roomOrder: [String]
    /// Locally assigned room names, keyed by media-player entity id.
    public private(set) var remoteRooms: [String: String]
    /// Locally selected layout types, keyed by media-player entity id.
    public private(set) var remoteDeviceTypes: [String: String]
    /// The name of this device, shown when it asks to pair.
    public var deviceName: String = ProcessInfo.processInfo.hostName
    /// The platform this app runs on.
    public let platform: String

    private let session: DashboardSession
    private let appVersion: String
    private static let tabOrderDefaultsKey = "FamilyDashboard.iOS.tabOrder"
    private static let remoteOrderDefaultsKey = "FamilyDashboard.iOS.remoteOrder"
    private static let roomOrderDefaultsKey = "FamilyDashboard.iOS.roomOrder"
    private static let remoteRoomsDefaultsKey = "FamilyDashboard.iOS.remoteRooms"
    private static let remoteDeviceTypesDefaultsKey = "FamilyDashboard.iOS.remoteDeviceTypes"
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
        let savedTabIDs = UserDefaults.standard.stringArray(forKey: Self.tabOrderDefaultsKey) ?? []
        var savedTabs: [DashboardTab] = []
        for tab in savedTabIDs.compactMap(DashboardTab.init(rawValue:)) where !savedTabs.contains(tab) {
            savedTabs.append(tab)
        }
        self.tabOrder = savedTabs + DashboardTab.allCases.filter { !savedTabs.contains($0) }
        self.remoteOrder = UserDefaults.standard.stringArray(forKey: Self.remoteOrderDefaultsKey) ?? []
        self.roomOrder = UserDefaults.standard.stringArray(forKey: Self.roomOrderDefaultsKey) ?? []
        self.remoteRooms = UserDefaults.standard.dictionary(forKey: Self.remoteRoomsDefaultsKey) as? [String: String] ?? [:]
        self.remoteDeviceTypes = UserDefaults.standard.dictionary(forKey: Self.remoteDeviceTypesDefaultsKey) as? [String: String] ?? [:]
    }

    /// The colours of the dashboard.
    public var theme: Theme {
        payload?.theme ?? Theme()
    }

    /// The tabs to show.
    public var tabs: [DashboardTab] {
        let enabled = payload?.enabledTabs ?? [.home]
        let available = platform == "ios" ? enabled : enabled.filter { $0 != .remote }
        return DashboardTab.ordered(available, preferred: tabOrder)
    }

    /// Sort the selected media players using this device's saved preference.
    public func orderedRemotes(_ remotes: [RemoteCard]) -> [RemoteCard] {
        let configured = remotes.map { remote -> RemoteCard in
            var copy = remote
            copy.room = remoteRooms[remote.entityID] ?? "Other"
            if let type = remoteDeviceTypes[remote.entityID], type != "auto" {
                copy.kind = type
                copy.commands = remoteCommands(for: type, hasRemote: remote.remoteEntityID != nil)
            }
            return copy
        }
        return RemoteCard.ordered(configured, preferredIDs: remoteOrder)
    }

    /// The selected per-device type override, if the user chose one.
    public func remoteTypeOverride(for remote: RemoteCard) -> String? {
        guard let type = remoteDeviceTypes[remote.entityID], type != "auto" else { return nil }
        return type
    }

    /// Save a room assignment for one player.
    public func setRemoteRoom(_ room: String, for remote: RemoteCard) {
        let cleaned = room.trimmingCharacters(in: .whitespacesAndNewlines)
        remoteRooms[remote.entityID] = cleaned.isEmpty ? "Other" : String(cleaned.prefix(40))
        UserDefaults.standard.set(remoteRooms, forKey: Self.remoteRoomsDefaultsKey)
    }

    /// Save the preferred remote layout type for one player.
    public func setRemoteDeviceType(_ type: String, for remote: RemoteCard) {
        let supported = ["auto", "roku", "apple_tv", "lg", "generic"]
        remoteDeviceTypes[remote.entityID] = supported.contains(type) ? type : "auto"
        UserDefaults.standard.set(remoteDeviceTypes, forKey: Self.remoteDeviceTypesDefaultsKey)
    }

    /// Return distinct room names in this device's preferred order.
    public func orderedRooms(for remotes: [RemoteCard]) -> [String] {
        var available: [String] = []
        for room in orderedRemotes(remotes).map(\.room) where !available.contains(room) {
            available.append(room)
        }
        return roomOrder.filter { available.contains($0) }
            + available.filter { !roomOrder.contains($0) }
    }

    /// Save a reordered tab list while retaining the order of currently disabled tabs.
    public func setTabOrder(_ orderedTabs: [DashboardTab]) {
        let currentIDs = orderedTabs.map(\.rawValue)
        let retainedIDs = tabOrder.map(\.rawValue).filter { !currentIDs.contains($0) }
        tabOrder = orderedTabs + retainedIDs.compactMap(DashboardTab.init(rawValue:))
        UserDefaults.standard.set(tabOrder.map(\.rawValue), forKey: Self.tabOrderDefaultsKey)
    }

    /// Save a reordered remote list while retaining entries that are not currently selected.
    public func setRemoteOrder(_ remotes: [RemoteCard]) {
        let currentIDs = remotes.map(\.entityID)
        let retainedIDs = remoteOrder.filter { !currentIDs.contains($0) }
        remoteOrder = currentIDs + retainedIDs
        UserDefaults.standard.set(remoteOrder, forKey: Self.remoteOrderDefaultsKey)
    }

    /// Reorder players within one room without changing the order of other rooms.
    public func setRemoteOrder(_ remotes: [RemoteCard], inRoom room: String) {
        guard let currentPayload = payload else { return }
        let allPlayers = orderedRemotes(currentPayload.remotes)
        let roomIDs = Set(allPlayers.filter { $0.room == room }.map(\.entityID))
        var result: [RemoteCard] = []
        var inserted = false
        for player in allPlayers {
            if roomIDs.contains(player.entityID) {
                if !inserted {
                    result.append(contentsOf: remotes)
                    inserted = true
                }
            } else {
                result.append(player)
            }
        }
        if !inserted { result.append(contentsOf: remotes) }
        setRemoteOrder(result)
    }

    /// Save the room order while preserving rooms added by later configuration changes.
    public func setRoomOrder(_ rooms: [String]) {
        let unique = rooms.reduce(into: [String]()) { result, room in
            if !result.contains(room) { result.append(room) }
        }
        roomOrder = unique + roomOrder.filter { !unique.contains($0) }
        UserDefaults.standard.set(roomOrder, forKey: Self.roomOrderDefaultsKey)
    }

    private func remoteCommands(for kind: String, hasRemote: Bool) -> [String] {
        guard hasRemote || kind == "lg" else { return [] }
        var commands = ["up", "down", "left", "right", "select", "back", "home", "reverse", "forward"]
        switch kind {
        case "roku": commands += ["replay", "options", "info"]
        case "apple_tv": commands.append("menu")
        case "lg": commands.append("input")
        default: break
        }
        return commands
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
