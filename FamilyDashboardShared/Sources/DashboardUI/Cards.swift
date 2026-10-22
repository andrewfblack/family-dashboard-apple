#if canImport(SwiftUI)
import DashboardCore
import SwiftUI

private struct DashboardThemeKey: EnvironmentKey {
    static let defaultValue = Theme()
}

public extension EnvironmentValues {
    /// The colours of the dashboard.
    var dashboardTheme: Theme {
        get { self[DashboardThemeKey.self] }
        set { self[DashboardThemeKey.self] = newValue }
    }
}

/// A card that holds one part of the dashboard.
public struct DashboardCard<Content: View>: View {
    @Environment(\.dashboardTheme) private var theme
    #if os(tvOS)
    @FocusState private var isFocused: Bool
    #endif

    private let title: String
    private let symbol: String?
    private let onActivate: (() -> Void)?
    private let content: Content

    private var cardBackground: Color {
        #if os(tvOS)
        return isFocused ? theme.backgroundColor.opacity(0.92) : theme.itemBackgroundColor
        #else
        return theme.itemBackgroundColor
        #endif
    }

    private var cardBorder: Color {
        #if os(tvOS)
        return isFocused ? theme.selectedBorderColor : theme.itemBorderColor
        #else
        return theme.itemBorderColor
        #endif
    }

    /// Create a card.
    public init(
        _ title: String,
        symbol: String? = nil,
        onActivate: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.onActivate = onActivate
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(theme.accentColor)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.itemHeader)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
        #if os(tvOS)
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.015 : 1)
        #endif
        .onTapGesture {
            onActivate?()
        }
    }
}

/// A number with a label under it.
public struct MetricTile: View {
    @Environment(\.dashboardTheme) private var theme

    private let label: String
    private let value: String
    private let detail: String?
    private let symbol: String?

    /// Create a tile.
    public init(label: String, value: String, detail: String? = nil, symbol: String? = nil) {
        self.label = label
        self.value = value
        self.detail = detail
        self.symbol = symbol
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.muted)
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(theme.accentColor)
                }
                Text(value)
                    .font(.title)
                    .foregroundStyle(theme.body)
            }
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One event on the agenda.
public struct EventRow: View {
    @Environment(\.dashboardTheme) private var theme

    private let event: CalendarEvent

    private var timeColumnWidth: CGFloat {
        #if os(tvOS)
        return 124
        #else
        return 76
        #endif
    }

    /// Create a row.
    public init(event: CalendarEvent) {
        self.event = event
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(event.timeLabel)
                .font(.caption.monospacedDigit())
                .foregroundStyle(theme.muted)
                .lineLimit(1)
                .frame(width: timeColumnWidth, alignment: .leading)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: event.color ?? "E5A84B"))
                .frame(width: 4, height: 22)
            Text(event.title)
                .font(.subheadline)
                .foregroundStyle(theme.body)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
    }
}

/// One day of the rolling schedule.
public struct ScheduleDayCard: View {
    @Environment(\.dashboardTheme) private var theme

    private let day: CalendarDay

    /// Create a card.
    public init(day: CalendarDay) {
        self.day = day
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.weekday)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(day.isToday ? theme.accentColor : theme.muted)
                Text("\(day.month) \(day.day)")
                    .font(.title3)
                    .foregroundStyle(theme.body)
            }
            if day.events.isEmpty {
                Text("Nothing planned")
                    .font(.caption)
                    .foregroundStyle(theme.muted)
            } else {
                ForEach(day.events) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.body)
                            .lineLimit(2)
                        Text(event.timeLabel)
                            .font(.caption2)
                            .foregroundStyle(theme.muted)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(hex: event.color ?? "E5A84B").opacity(0.22),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
            }
            if day.overflow > 0 {
                Text("+\(day.overflow) more")
                    .font(.caption2)
                    .foregroundStyle(theme.muted)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.itemBackgroundColor, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(day.isToday ? theme.accentColor : theme.itemBorderColor, lineWidth: day.isToday ? 2 : 1)
        )
        #if os(tvOS)
        .focusable()
        #endif
    }
}

/// One period of the forecast.
public struct ForecastTile: View {
    @Environment(\.dashboardTheme) private var theme

    private let forecast: WeatherForecast

    /// Create a tile.
    public init(forecast: WeatherForecast) {
        self.forecast = forecast
    }

    public var body: some View {
        VStack(spacing: 6) {
            Text(forecast.label)
                .font(.caption)
                .foregroundStyle(theme.muted)
            Image(systemName: WeatherSymbols.symbol(for: forecast.condition))
                .font(.title2)
                .foregroundStyle(theme.accentColor)
                .frame(height: 30)
            Text(WeatherSymbols.temperature(forecast.temperature))
                .font(.headline)
                .foregroundStyle(theme.body)
            if let low = forecast.templow {
                Text(WeatherSymbols.temperature(low))
                    .font(.caption2)
                    .foregroundStyle(theme.muted)
            }
            if let chance = forecast.precipitationProbability, chance > 0 {
                Text("\(Int(chance))% rain")
                    .font(.caption2)
                    .foregroundStyle(theme.muted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// A light that may be toggled and dimmed.
public struct LightTile: View {
    @Environment(\.dashboardTheme) private var theme

    private let light: LightCard
    private let action: (DashboardAction) -> Void

    /// Create a tile.
    public init(light: LightCard, action: @escaping (DashboardAction) -> Void) {
        self.light = light
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: light.isOn ? "lightbulb.fill" : "lightbulb")
                    .foregroundStyle(light.isOn ? theme.accentColor : theme.muted)
                Text(light.name)
                    .font(.headline)
                    .foregroundStyle(theme.body)
                Spacer()
            }
            Button {
                action(.lightToggle(entityID: light.entityID))
            } label: {
                Text(light.isOn ? "Turn off" : "Turn on")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accentColor)
            if light.isOn {
                HStack(spacing: 8) {
                    ForEach([25, 50, 75, 100], id: \.self) { percent in
                        Button("\(percent)%") {
                            action(.lightBrightness(entityID: light.entityID, percent: percent))
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.itemBackgroundColor, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.itemBorderColor, lineWidth: 1)
        )
    }
}

/// A scene or script that may be activated.
public struct SceneTile: View {
    @Environment(\.dashboardTheme) private var theme

    private let scene: SceneCard
    private let action: (DashboardAction) -> Void

    /// Create a tile.
    public init(scene: SceneCard, action: @escaping (DashboardAction) -> Void) {
        self.scene = scene
        self.action = action
    }

    public var body: some View {
        Button {
            action(.sceneActivate(entityID: scene.entityID))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(theme.accentColor)
                Text(scene.name)
                    .font(.headline)
                    .foregroundStyle(theme.body)
                    .multilineTextAlignment(.leading)
                Text("Activate")
                    .font(.caption)
                    .foregroundStyle(theme.muted)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.itemBackgroundColor, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.itemBorderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A thermostat that may be adjusted.
public struct ClimateTile: View {
    @Environment(\.dashboardTheme) private var theme

    private let climate: ClimateCard
    private let action: (DashboardAction) -> Void

    /// Create a tile.
    public init(climate: ClimateCard, action: @escaping (DashboardAction) -> Void) {
        self.climate = climate
        self.action = action
    }

    public var body: some View {
        let step = climate.targetTempStep > 0 ? climate.targetTempStep : 1
        let target = climate.displayTarget ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer.medium")
                    .foregroundStyle(theme.accentColor)
                Text(climate.name)
                    .font(.headline)
                    .foregroundStyle(theme.body)
                Spacer()
                Text(WeatherSymbols.temperature(climate.currentTemperature))
                    .font(.title3)
                    .foregroundStyle(theme.muted)
            }
            HStack {
                Button {
                    action(.climateTemperature(entityID: climate.entityID, temperature: target - step))
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                Spacer()
                Text(WeatherSymbols.temperature(climate.temperature))
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(theme.body)
                Spacer()
                Button {
                    action(.climateTemperature(entityID: climate.entityID, temperature: target + step))
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
            }
            HStack(spacing: 8) {
                ForEach(climate.hvacModes, id: \.self) { mode in
                    Button(mode.replacingOccurrences(of: "_", with: " ")) {
                        action(.climateMode(entityID: climate.entityID, mode: mode))
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(climate.state == mode ? theme.accentColor : theme.itemBorderColor)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.itemBackgroundColor, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.itemBorderColor, lineWidth: 1)
        )
    }
}
#endif
