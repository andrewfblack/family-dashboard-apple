import DashboardCore
import DashboardUI
import SwiftUI

/// The dashboard on a television.
///
/// The tabs sit in a row at the top and the focus moves sideways, which is
/// how a remote is used.
struct TVDashboardView: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 0) {
                TVHeaderView()
                TVTabBarView()
            }
            .background(theme.itemBackgroundColor)
            ScrollView {
                TVTabContent()
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
            }
            .focusSection()
        }
        .padding(.top, 30)
    }
}

/// The title and clock on the television dashboard.
private struct TVHeaderView: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme

    var body: some View {
        HStack {
            Text(model.payload?.title ?? "Family Dashboard")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(theme.header)
            Spacer()
            Text(Date.now.formatted(date: .complete, time: .shortened))
                .font(.title3)
                .foregroundStyle(theme.muted)
        }
        .padding(.horizontal, 60)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }
}

/// The remote-friendly horizontal tab rail.
private struct TVTabBarView: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(model.tabs) { tab in
                    TVTabButton(
                        tab: tab,
                        isSelected: model.selectedTab == tab,
                        theme: theme
                    ) {
                        model.selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 14)
        }
        .focusSection()
    }
}

/// One focusable button in the tvOS tab rail.
private struct TVTabButton: View {
    let tab: DashboardTab
    let isSelected: Bool
    let theme: Theme
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Image(systemName: tab.symbol)
                .font(.system(size: 28, weight: .medium))
                .frame(width: 84, height: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .foregroundStyle(isSelected ? theme.backgroundColor : theme.body)
        .background(
            isSelected ? theme.accentColor : theme.itemBackgroundColor,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? theme.selectedBorderColor : theme.itemBorderColor, lineWidth: isSelected ? 2 : 1)
        )
    }
}

/// The screen for the tab that is open.
struct TVTabContent: View {
    @Environment(DashboardViewModel.self) private var model

    var body: some View {
        let payload = model.payload
        VStack(alignment: .leading, spacing: 28) {
            if let payload {
                switch model.selectedTab {
                case .home: TVHomeTab(payload: payload)
                case .calendar: TVCalendarTab(payload: payload)
                case .weather: TVWeatherTab(payload: payload)
                case .lights: TVLightsTab(payload: payload)
                case .scenes: TVScenesTab(payload: payload)
                case .climate: TVClimateTab(payload: payload)
                }
            } else {
                ProgressView()
            }
        }
    }
}

/// Today's events, the meal and the climate.
struct TVHomeTab: View {
    @Environment(\.dashboardTheme) private var theme
    let payload: DashboardPayload

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            DashboardCard("Today", symbol: "calendar") {
                VStack(spacing: 8) {
                    if payload.calendarEvents.isEmpty {
                        Text("No events today")
                            .font(.title3)
                            .foregroundStyle(theme.muted)
                    } else {
                        ForEach(payload.calendarEvents) { event in
                            EventRow(event: event)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 28) {
                DashboardCard("Meal plan", symbol: "fork.knife") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(payload.mealPlan.isEmpty ? "No meal planned" : payload.mealPlan)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(theme.body)
                        Text("Today")
                            .font(.title3)
                            .foregroundStyle(theme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DashboardCard("Climate", symbol: "thermometer.medium") {
                    HStack(spacing: 24) {
                        MetricTile(
                            label: "Inside",
                            value: WeatherSymbols.temperature(payload.insideTemperature),
                            detail: payload.insideHumidity.map { "\(Int($0))% humidity" },
                            symbol: "house"
                        )
                        MetricTile(
                            label: "Outside",
                            value: WeatherSymbols.temperature(payload.outsideTemperature),
                            detail: WeatherSymbols.condition(payload.outsideCondition),
                            symbol: WeatherSymbols.symbol(for: payload.outsideCondition)
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// The rolling family schedule.
struct TVCalendarTab: View {
    let payload: DashboardPayload

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(payload.calendarSchedule.days) { day in
                    ScheduleDayCard(day: day)
                        .frame(width: 230)
                }
            }
        }
    }
}

/// The current conditions and the forecast.
struct TVWeatherTab: View {
    @Environment(\.dashboardTheme) private var theme
    let payload: DashboardPayload

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            DashboardCard(payload.weather.name ?? "Weather", symbol: "cloud.sun.fill") {
                VStack(spacing: 12) {
                    Image(systemName: WeatherSymbols.symbol(for: payload.weather.condition))
                        .font(.system(size: 90))
                        .foregroundStyle(theme.accentColor)
                    Text(WeatherSymbols.temperature(payload.weather.temperature))
                        .font(.system(size: 68, weight: .semibold))
                        .foregroundStyle(theme.body)
                    Text(WeatherSymbols.condition(payload.weather.condition))
                        .font(.title2)
                        .foregroundStyle(theme.muted)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            if !payload.weather.forecast.isEmpty {
                DashboardCard("Forecast", symbol: "chart.bar") {
                    HStack(spacing: 20) {
                        ForEach(payload.weather.forecast) { forecast in
                            ForecastTile(forecast: forecast)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// The lights that may be toggled and dimmed.
struct TVLightsTab: View {
    @Environment(DashboardViewModel.self) private var model
    let payload: DashboardPayload

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: 24) {
            ForEach(payload.lights) { light in
                LightTile(light: light) { action in
                    Task { await model.run(action) }
                }
            }
        }
    }
}

/// The scenes and scripts that may be activated.
struct TVScenesTab: View {
    @Environment(DashboardViewModel.self) private var model
    let payload: DashboardPayload

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 24) {
            ForEach(payload.scenes) { scene in
                SceneTile(scene: scene) { action in
                    Task { await model.run(action) }
                }
            }
        }
    }
}

/// The thermostats that may be adjusted.
struct TVClimateTab: View {
    @Environment(DashboardViewModel.self) private var model
    let payload: DashboardPayload

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 420))], spacing: 24) {
            ForEach(payload.climates) { climate in
                ClimateTile(climate: climate) { action in
                    Task { await model.run(action) }
                }
            }
        }
    }
}
