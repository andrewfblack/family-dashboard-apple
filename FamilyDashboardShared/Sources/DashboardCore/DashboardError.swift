import Foundation

/// Every error the dashboard can report.
public enum DashboardError: Error, LocalizedError, Equatable, Sendable {
    /// The address the user typed cannot be used.
    case invalidServerAddress(String)
    /// The credential is missing, unknown or expired.
    case invalidToken
    /// The short pairing code is wrong.
    case invalidPairingCode
    /// The device code is wrong or the request expired.
    case unknownDeviceCode
    /// The network policy does not allow this device.
    case networkAccessDenied
    /// The request body could not be read.
    case invalidJSON
    /// The weekly meal plan did not carry seven days.
    case invalidMealPlan
    /// The climate mode is not supported by the entity.
    case invalidMode
    /// The entity is not part of the dashboard.
    case notAllowed
    /// Home Assistant refused the command.
    case serviceFailed
    /// No background image has been uploaded.
    case noBackground
    /// The integration is not set up.
    case notConfigured
    /// The request needs a credential.
    case unauthorized
    /// The request was refused in Home Assistant.
    case pairingDenied
    /// The request expired before it was approved.
    case pairingExpired
    /// The request could not be sent.
    case transport(String)
    /// The answer could not be read.
    case decoding(String)
    /// Something else went wrong.
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidServerAddress(address):
            return "\"\(address)\" is not a valid address."
        case .invalidToken:
            return "This device is not paired."
        case .invalidPairingCode:
            return "That pairing code is not correct."
        case .unknownDeviceCode:
            return "That device code is unknown or has expired."
        case .networkAccessDenied:
            return "Home Assistant blocked this device. Change the network access under Family Dashboard in Home Assistant."
        case .invalidJSON:
            return "Home Assistant could not read the request."
        case .invalidMealPlan:
            return "The meal plan needs a meal for every day of the week."
        case .invalidMode:
            return "That thermostat does not support that mode."
        case .notAllowed:
            return "That control is not part of this dashboard."
        case .serviceFailed:
            return "Home Assistant could not run that command."
        case .noBackground:
            return "No background image has been uploaded."
        case .notConfigured:
            return "The Family Dashboard integration is not set up."
        case .unauthorized:
            return "This device needs to be paired."
        case .pairingDenied:
            return "The pairing request was refused in Home Assistant."
        case .pairingExpired:
            return "The pairing request expired. Please try again."
        case let .transport(message):
            return message
        case let .decoding(message):
            return message
        case let .unknown(message):
            return message
        }
    }

    /// Build an error from the `error` field the server sends.
    public static func fromServer(code: String) -> DashboardError {
        switch code {
        case "invalid_token": return .invalidToken
        case "invalid_pairing_code": return .invalidPairingCode
        case "unknown_device_code": return .unknownDeviceCode
        case "network_access_denied": return .networkAccessDenied
        case "invalid_json": return .invalidJSON
        case "invalid_meal_plan": return .invalidMealPlan
        case "invalid_mode": return .invalidMode
        case "not_allowed": return .notAllowed
        case "service_failed": return .serviceFailed
        case "no_background": return .noBackground
        case "not_configured": return .notConfigured
        case "unauthorized": return .unauthorized
        default: return .unknown(code)
        }
    }
}
