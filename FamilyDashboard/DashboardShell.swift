import DashboardCore
import DashboardUI
import SwiftUI

/// The dashboard itself: a list of tabs and the screen that is open.
struct DashboardShell: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingSettings = false

    /// The selection of the tab list, which is optional so a tab can be
    /// picked out of a list.
    private var selection: Binding<DashboardTab?> {
        Binding(
            get: { model.selectedTab },
            set: { if let value = $0 { model.selectedTab = value } }
        )
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                NavigationSplitView {
                    List(model.tabs, selection: selection) { tab in
                        Label(tab.title, systemImage: tab.symbol)
                            .tag(tab)
                    }
                    .navigationTitle("Family Dashboard")
                } detail: {
                    TabContent(tab: model.selectedTab)
                }
            } else {
                TabView(selection: selection) {
                    ForEach(model.tabs) { tab in
                        TabContent(tab: tab)
                            .tabItem { Label(tab.title, systemImage: tab.symbol) }
                            .tag(tab)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await model.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(model.isLoading)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

/// The screen for one tab.
struct TabContent: View {
    @Environment(DashboardViewModel.self) private var model

    let tab: DashboardTab

    var body: some View {
        let payload = model.payload
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let payload {
                    switch tab {
                    case .home: HomeTab(payload: payload)
                    case .calendar: CalendarTab(payload: payload)
                    case .weather: WeatherTab(payload: payload)
                    case .lights: LightsTab(payload: payload)
                    case .scenes: ScenesTab(payload: payload)
                    case .climate: ClimateTab(payload: payload)
                    }
                } else {
                    VStack(spacing: 16) {
                        if let errorMessage = model.errorMessage {
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await model.refresh() }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            ProgressView()
                            Text("Connecting to Home Assistant…")
                        }
                        Button("Forget this device and pair again", role: .destructive) {
                            Task { await model.unpair() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                }
            }
            .padding(20)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await model.refresh()
        }
        .background(BackgroundView())
    }
}

/// Today's events, the meal and the climate.
struct HomeTab: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme
    @State private var showingMeals = false
    let payload: DashboardPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DashboardCard("Today", symbol: "calendar") {
                if payload.calendarEvents.isEmpty {
                    Text("No events today")
                        .font(.subheadline)
                        .foregroundStyle(theme.muted)
                } else {
                    VStack(spacing: 6) {
                        ForEach(payload.calendarEvents) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }

            DashboardCard("Meal plan", symbol: "fork.knife") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(payload.mealPlan.isEmpty ? "No meal planned" : payload.mealPlan)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.body)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(theme.muted)
                    Button("Edit weekly plan") {
                        showingMeals = true
                    }
                    .buttonStyle(.bordered)
                    .tint(theme.accentColor)
                }
            }

            DashboardCard("Climate", symbol: "thermometer.medium") {
                HStack(spacing: 16) {
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
        .sheet(isPresented: $showingMeals) {
            MealPlanView(meals: payload.weeklyMealPlan)
        }
    }
}

/// The rolling family schedule.
struct CalendarTab: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let payload: DashboardPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if sizeClass == .compact {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(payload.calendarSchedule.days) { day in
                        ScheduleDayCard(day: day)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(payload.calendarSchedule.days) { day in
                            ScheduleDayCard(day: day)
                                .frame(width: 180)
                        }
                    }
                    .padding(.horizontal, 1)
                }
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }
}

/// The current conditions and the forecast.
struct WeatherTab: View {
    let payload: DashboardPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DashboardCard(payload.weather.name ?? "Weather", symbol: "cloud.sun.fill") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        Image(systemName: WeatherSymbols.symbol(for: payload.weather.condition))
                            .font(.system(size: 56))
                            .foregroundStyle(Theme().accentColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(WeatherSymbols.temperature(payload.weather.temperature))
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(Theme().body)
                            Text(WeatherSymbols.condition(payload.weather.condition))
                                .font(.subheadline)
                                .foregroundStyle(Theme().muted)
                        }
                    }
                    if let humidity = payload.weather.humidity {
                        Text("Humidity \(Int(humidity))%")
                            .font(.caption)
                            .foregroundStyle(Theme().muted)
                    }
                }
            }

            if !payload.weather.forecast.isEmpty {
                DashboardCard(
                    "\((payload.weather.forecastType ?? "daily").capitalized) forecast",
                    symbol: "chart.bar"
                ) {
                    HStack(spacing: 12) {
                        ForEach(payload.weather.forecast) { forecast in
                            ForecastTile(forecast: forecast)
                        }
                    }
                }
            }
        }
    }
}

/// The lights that may be toggled and dimmed.
struct LightsTab: View {
    @Environment(DashboardViewModel.self) private var model
    let payload: DashboardPayload

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 16) {
            ForEach(payload.lights) { light in
                LightTile(light: light) { action in
                    Task { await model.run(action) }
                }
            }
        }
    }
}

/// The scenes and scripts that may be activated.
struct ScenesTab: View {
    @Environment(DashboardViewModel.self) private var model
    let payload: DashboardPayload

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
            ForEach(payload.scenes) { scene in
                SceneTile(scene: scene) { action in
                    Task { await model.run(action) }
                }
            }
        }
    }
}

/// The thermostats that may be adjusted.
struct ClimateTab: View {
    @Environment(DashboardViewModel.self) private var model
    let payload: DashboardPayload

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: 16) {
            ForEach(payload.climates) { climate in
                ClimateTile(climate: climate) { action in
                    Task { await model.run(action) }
                }
            }
        }
    }
}
