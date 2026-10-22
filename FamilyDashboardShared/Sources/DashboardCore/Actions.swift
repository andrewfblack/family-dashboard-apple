import Foundation

/// A command the dashboard accepts.
///
/// Every command is allowlisted on the server: an entity that was not chosen
/// in the Home Assistant options is refused.
public enum DashboardAction: Hashable, Sendable {
    /// Replace the plan for the whole week.
    case mealWeek([String])
    /// Turn a light on or off.
    case lightToggle(entityID: String)
    /// Set the brightness of a light, as a percentage.
    case lightBrightness(entityID: String, percent: Int)
    /// Activate a scene or run a script.
    case sceneActivate(entityID: String)
    /// Set the target temperature of a thermostat.
    case climateTemperature(entityID: String, temperature: Double)
    /// Set the mode of a thermostat.
    case climateMode(entityID: String, mode: String)

    /// The name the server knows this action by.
    public var name: String {
        switch self {
        case .mealWeek: return "meal_week"
        case .lightToggle: return "light_toggle"
        case .lightBrightness: return "light_brightness"
        case .sceneActivate: return "scene_activate"
        case .climateTemperature: return "climate_temperature"
        case .climateMode: return "climate_mode"
        }
    }

    /// The body the server expects.
    public var body: [String: Any] {
        switch self {
        case let .mealWeek(meals):
            return ["action": name, "value": meals]
        case let .lightToggle(entityID):
            return ["action": name, "entity_id": entityID]
        case let .lightBrightness(entityID, percent):
            return ["action": name, "entity_id": entityID, "value": max(1, min(100, percent))]
        case let .sceneActivate(entityID):
            return ["action": name, "entity_id": entityID]
        case let .climateTemperature(entityID, temperature):
            return ["action": name, "entity_id": entityID, "value": temperature]
        case let .climateMode(entityID, mode):
            return ["action": name, "entity_id": entityID, "value": mode]
        }
    }
}

/// The answer to a pairing request.
public struct PairingRequest: Decodable, Hashable, Sendable {
    /// The code to show the user.
    public var deviceCode: String
    /// How long the code stays valid, in seconds.
    public var expiresIn: Int
    /// How often to ask for the status, in seconds.
    public var pollInterval: Int

    public init(deviceCode: String, expiresIn: Int, pollInterval: Int) {
        self.deviceCode = deviceCode
        self.expiresIn = expiresIn
        self.pollInterval = pollInterval
    }

    private enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case expiresIn = "expires_in"
        case pollInterval = "poll_interval"
    }
}

/// The state of a pairing request.
public enum PairingStatus: Hashable, Sendable {
    /// The request is waiting for an administrator.
    case pending
    /// The request was approved and carries a credential.
    case approved(credential: DeviceCredential)
    /// The request was refused.
    case denied
    /// The credential was already handed over.
    case consumed
    /// The request expired before it was approved.
    case expired

    /// The credential, when the request was approved.
    public var credential: DeviceCredential? {
        if case let .approved(credential) = self { return credential }
        return nil
    }
}

/// The answer to a pairing status check.
public struct PairingStatusResponse: Decodable, Hashable, Sendable {
    /// The state of the request.
    public var status: String
    /// The credential, present once, in the answer that reports `approved`.
    public var deviceToken: String?
    /// The identifier of the device.
    public var deviceID: String?
    /// How long the request stays valid, in seconds.
    public var expiresIn: Int?

    public init(status: String, deviceToken: String? = nil, deviceID: String? = nil, expiresIn: Int? = nil) {
        self.status = status
        self.deviceToken = deviceToken
        self.deviceID = deviceID
        self.expiresIn = expiresIn
    }

    private enum CodingKeys: String, CodingKey {
        case status
        case deviceToken = "device_token"
        case deviceID = "device_id"
        case expiresIn = "expires_in"
    }

    /// The state as a value.
    public var value: PairingStatus {
        switch status {
        case "approved":
            guard let token = deviceToken, !token.isEmpty else { return .consumed }
            return .approved(credential: DeviceCredential(token: token, deviceID: deviceID ?? ""))
        case "denied": return .denied
        case "consumed": return .consumed
        case "expired": return .expired
        default: return .pending
        }
    }
}

/// The credential for one device.
public struct DeviceCredential: Codable, Hashable, Sendable {
    /// The token to send in the Authorization header.
    public var token: String
    /// The identifier of the device.
    public var deviceID: String?

    public init(token: String, deviceID: String? = nil) {
        self.token = token
        self.deviceID = deviceID
    }

    private enum CodingKeys: String, CodingKey {
        case token = "device_token"
        case deviceID = "device_id"
    }

    /// Decode the credential from the server's answer.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
        deviceID = try container.decodeIfPresent(String.self, forKey: .deviceID)
    }
}
