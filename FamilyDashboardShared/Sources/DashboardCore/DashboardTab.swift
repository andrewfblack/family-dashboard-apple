import Foundation

/// The tabs the dashboard can show.
public enum DashboardTab: String, CaseIterable, Identifiable, Sendable {
    /// Today's events, the meal and the climate.
    case home
    /// The rolling family schedule.
    case calendar
    /// The current conditions and the forecast.
    case weather
    /// The lights that may be toggled and dimmed.
    case lights
    /// The scenes and scripts that may be activated.
    case scenes
    /// The thermostats that may be adjusted.
    case climate

    public var id: String { rawValue }

    /// The name on the tab.
    public var title: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .weather: return "Weather"
        case .lights: return "Lights"
        case .scenes: return "Scenes"
        case .climate: return "Climate"
        }
    }

    /// The symbol that stands for the tab.
    public var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .weather: return "cloud.sun.fill"
        case .lights: return "lightbulb.fill"
        case .scenes: return "sparkles"
        case .climate: return "thermometer.medium"
        }
    }

    /// Whether the administrator switched this tab on.
    ///
    /// The Home tab is always there.
    public func isEnabled(in tabs: Tabs) -> Bool {
        switch self {
        case .home: return true
        case .calendar: return tabs.calendar
        case .weather: return tabs.weather
        case .lights: return tabs.lights
        case .scenes: return tabs.scenes
        case .climate: return tabs.climate
        }
    }

    /// The tabs to show, in order.
    public static func enabled(in tabs: Tabs) -> [DashboardTab] {
        allCases.filter { $0.isEnabled(in: tabs) }
    }
}

extension DashboardPayload {
    /// The tabs to show.
    public var enabledTabs: [DashboardTab] {
        DashboardTab.enabled(in: tabs)
    }

    /// Apply a change the live update stream reported.
    ///
    /// The change is folded into the payload so the screen reacts at once,
    /// without waiting for the next full refresh.
    public func applying(_ change: StateChange) -> DashboardPayload {
        var copy = self
        copy.states[change.entityID] = EntityState(
            state: change.state,
            attributes: change.attributes
        )

        if let index = copy.lights.firstIndex(where: { $0.entityID == change.entityID }) {
            copy.lights[index].state = change.state
            if let brightness = change.attributes["brightness"]?.numberValue {
                copy.lights[index].brightness = Int(brightness)
            }
        }

        if let index = copy.scenes.firstIndex(where: { $0.entityID == change.entityID }) {
            copy.scenes[index].state = change.state
        }

        if let index = copy.climates.firstIndex(where: { $0.entityID == change.entityID }) {
            copy.climates[index].state = change.state
            if let temperature = change.attributes["current_temperature"]?.numberValue {
                copy.climates[index].currentTemperature = temperature
            }
            if let temperature = change.attributes["temperature"]?.numberValue {
                copy.climates[index].temperature = temperature
            }
            if let humidity = change.attributes["humidity"]?.numberValue {
                copy.climates[index].humidity = humidity
            }
            if let action = change.attributes["hvac_action"]?.stringValue {
                copy.climates[index].hvacAction = action
            }
        }

        return copy
    }

    /// The value of an attribute of one of the displayed entities.
    public func attribute(_ name: String, of entityID: String?) -> JSONValue? {
        guard let entityID else { return nil }
        return states[entityID]?.attributes[name]
    }

    /// The temperature of the indoor sensor, whatever kind it is.
    public var insideTemperature: Double? {
        guard let entityID = resolvedEntities.inside else { return nil }
        if let value = attribute("current_temperature", of: entityID)?.numberValue {
            return value
        }
        return states[entityID]?.attributes["current_temperature"]?.numberValue
            ?? states[entityID].flatMap { Double($0.state) }
    }

    /// The humidity of the indoor sensor.
    public var insideHumidity: Double? {
        if let entityID = resolvedEntities.insideHumidity {
            if let value = states[entityID].flatMap({ Double($0.state) }) {
                return value
            }
        }
        return attribute("humidity", of: resolvedEntities.inside)?.numberValue
    }

    /// The outdoor temperature.
    public var outsideTemperature: Double? {
        weather.temperature ?? attribute("temperature", of: resolvedEntities.outside)?.numberValue
    }

    /// The outdoor condition.
    public var outsideCondition: String? {
        weather.condition ?? states[resolvedEntities.outside ?? ""]?.state
    }
}
