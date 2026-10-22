#if canImport(SwiftUI)
import Foundation
import SwiftUI

/// Turns the values from the dashboard into something to show.
public enum WeatherSymbols {
    /// The symbol that stands for a weather condition.
    public static func symbol(for condition: String?) -> String {
        switch condition {
        case "sunny", "clear-night": return "sun.max.fill"
        case "partlycloudy": return "cloud.sun.fill"
        case "cloudy": return "cloud.fill"
        case "rainy", "pouring": return "cloud.rain.fill"
        case "lightning", "lightning-rainy": return "cloud.bolt.rain.fill"
        case "snowy", "snowy-rainy": return "cloud.snow.fill"
        case "fog": return "cloud.fog.fill"
        case "windy", "windy-variant": return "wind"
        case "hail": return "cloud.hail.fill"
        case "exceptional": return "exclamationmark.triangle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    /// The symbol that stands for a thermostat mode.
    public static func symbol(forMode mode: String) -> String {
        switch mode {
        case "heat": return "flame.fill"
        case "cool": return "snowflake"
        case "heat_cool", "auto": return "arrow.triangle.2.circlepath"
        case "dry": return "humidity.fill"
        case "fan_only": return "fan.fill"
        case "off": return "power"
        default: return "thermometer.medium"
        }
    }

    /// A temperature with a degree sign.
    public static func temperature(_ value: Double?) -> String {
        guard let value else { return "--" }
        return "\(Int(value.rounded()))°"
    }

    /// A condition with readable capitalisation.
    public static func condition(_ condition: String?) -> String {
        guard let condition, !condition.isEmpty else { return "Unknown" }
        return condition
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }
}
#endif
