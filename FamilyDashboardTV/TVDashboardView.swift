import DashboardCore
import DashboardUI
import SwiftUI

/// The dashboard on a television.
///
/// The layout follows the Roku dashboard: navigation runs across the top and
/// the selected screen gets the rest of the display.
struct TVDashboardView: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme

    var body: some View {
        ZStack {
            TVBackgroundView()
            Color.black.opacity(0.08).ignoresSafeArea()
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
}

/// The title and clock on the television dashboard.
private struct TVHeaderView: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(model.payload?.title ?? "Family Dashboard")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(theme.header)
            Spacer()
            Text(Date.now.formatted(date: .complete, time: .shortened))
                .font(.title2)
                .foregroundStyle(theme.muted)
        }
        .padding(.horizontal, 42)
        .padding(.top, 12)
        .padding(.bottom, 26)
    }
}

/// The remote-friendly horizontal tab bar.
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
    @FocusState private var isFocused: Bool

    let tab: DashboardTab
    let isSelected: Bool
    let theme: Theme
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Image(systemName: tab.symbol)
                .font(.system(size: 24, weight: .medium))
                .frame(width: 84, height: 64)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .accessibilityLabel(tab.title)
        .foregroundStyle(isSelected ? theme.accentColor : theme.body)
        .background(
            isSelected || isFocused
                ? theme.backgroundColor.opacity(0.92)
                : theme.itemBackgroundColor,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected || isFocused ? theme.selectedBorderColor : theme.itemBorderColor,
                    lineWidth: isSelected || isFocused ? 3 : 1
                )
        )
        .scaleEffect(isSelected || isFocused ? 1.03 : 1)
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
        HStack(alignment: .top, spacing: 22) {
            DashboardCard("Today's Calendar", symbol: "calendar") {
                VStack(alignment: .leading, spacing: 16) {
                    if payload.calendarEvents.isEmpty {
                        Text("No events today")
                            .font(.title3)
                            .foregroundStyle(theme.muted)
                    } else {
                        ForEach(payload.calendarEvents) { event in
                            EventRow(event: event)
                        }
                    }
                    Divider().overlay(theme.itemBorderColor)
                    HStack {
                        Text(payload.monthCalendar.title.isEmpty ? "Calendar" : payload.monthCalendar.title)
                            .font(.headline)
                            .foregroundStyle(theme.itemHeader)
                        Spacer()
                    }
                    TVMonthCalendarGrid(month: payload.monthCalendar)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)

            VStack(spacing: 22) {
                DashboardCard("Meal plan", symbol: "fork.knife") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(payload.mealPlan.isEmpty ? "No meal planned" : payload.mealPlan)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(theme.body)
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
                        Rectangle()
                            .fill(theme.itemBorderColor)
                            .frame(width: 1, height: 64)
                        MetricTile(
                            label: "Outside",
                            value: WeatherSymbols.temperature(payload.outsideTemperature),
                            detail: WeatherSymbols.condition(payload.outsideCondition),
                            symbol: WeatherSymbols.symbol(for: payload.outsideCondition)
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}

/// A Roku-style monthly calendar grid for the Apple TV Home screen.
private struct TVMonthCalendarGrid: View {
    @Environment(\.dashboardTheme) private var theme
    let month: MonthCalendar
    private let weekdayNames = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 7), spacing: 10) {
            ForEach(weekdayNames, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.muted)
            }
            ForEach(Array(slots.enumerated()), id: \.offset) { _, day in
                if day == 0 {
                    Color.clear.frame(minHeight: 34)
                } else {
                    Text("\(day)")
                        .font(.title3.weight(day == month.today ? .bold : .regular))
                        .foregroundStyle(day == month.today ? theme.backgroundColor : theme.body)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(
                            day == month.today
                                ? theme.accentColor
                                : (month.eventDays.contains(day) ? theme.selectedBackgroundColor : .clear),
                            in: Circle()
                        )
                }
            }
        }
    }

    private var slots: [Int] {
        Array(repeating: 0, count: max(0, month.firstWeekday))
            + Array(1...max(1, month.daysInMonth))
    }
}

/// The rolling family schedule.
struct TVCalendarTab: View {
    let payload: DashboardPayload

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 18
            let cardWidth = max(220, (proxy.size.width - (spacing * 4)) / 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(payload.calendarSchedule.days) { day in
                        ScheduleDayCard(day: day)
                            .frame(width: cardWidth)
                    }
                }
            }
            .focusSection()
        }
        .frame(height: 520)
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
