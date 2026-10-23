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
                TabContent(tab: model.selectedTab)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        IOSScrollableTabBar()
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

/// A compact, horizontally scrollable tab rail for iPhone.
///
/// SwiftUI's TabView creates a More menu once there are more than five tabs.
/// Keeping the rail in the app gives every enabled dashboard tab a direct,
/// swipeable destination instead.
private struct IOSScrollableTabBar: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.tabs) { tab in
                    Button {
                        model.selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image("Tab\(tab.title)")
                                .renderingMode(.template)
                                .font(.system(size: 21, weight: .medium))
                            Text(tab.title)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(
                            model.selectedTab == tab ? theme.accentColor : theme.body
                        )
                        .frame(minWidth: 70, minHeight: 52)
                        .padding(.horizontal, 4)
                        .background(
                            model.selectedTab == tab
                                ? theme.selectedBackgroundColor
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(model.selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.itemBorderColor)
                .frame(height: 1)
        }
    }
}

/// The screen for one tab.
struct TabContent: View {
    @Environment(DashboardViewModel.self) private var model

    let tab: DashboardTab

    var body: some View {
        let payload = model.payload
        ZStack {
            BackgroundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                DashboardHeader(title: payload?.title ?? "Family Dashboard")
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
            .background(Color.clear)
        }
        .refreshable {
            await model.refresh()
        }
        .background(BackgroundView())
    }
}

/// The Roku-style dashboard heading.
struct DashboardHeader: View {
    @Environment(\.dashboardTheme) private var theme
    let title: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(theme.header)
            Spacer()
            Text(Date.now.formatted(date: .complete, time: .shortened))
                .font(.caption)
                .foregroundStyle(theme.muted)
        }
        .padding(.horizontal, 4)
    }
}

/// Today's events, the meal and the climate.
struct HomeTab: View {
    @Environment(DashboardViewModel.self) private var model
    @Environment(\.dashboardTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingMeals = false
    let payload: DashboardPayload

    var body: some View {
        Group {
            if sizeClass == .regular {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        todayCard
                        MonthCalendarView(month: payload.monthCalendar)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        mealCard
                        climateCard
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    todayCard
                    MonthCalendarView(month: payload.monthCalendar)
                    mealCard
                    climateCard
                }
            }
        }
        .sheet(isPresented: $showingMeals) {
            MealPlanView(meals: payload.weeklyMealPlan)
        }
    }

    @ViewBuilder
    private var todayCard: some View {
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
    }

    @ViewBuilder
    private var mealCard: some View {
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
    }

    @ViewBuilder
    private var climateCard: some View {
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

}

/// The rolling family schedule.
struct CalendarTab: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let payload: DashboardPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MonthCalendarView(month: payload.monthCalendar)

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

/// A compact month overview matching the Roku calendar's event-day view.
struct MonthCalendarView: View {
    @Environment(\.dashboardTheme) private var theme
    let month: MonthCalendar

    private let weekdayNames = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        DashboardCard(month.title.isEmpty ? "Calendar" : month.title, symbol: "calendar") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(weekdayNames, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.muted)
                }
                ForEach(Array(slots.enumerated()), id: \.offset) { _, day in
                    if day == 0 {
                        Color.clear.frame(minHeight: 30)
                    } else {
                        Text("\(day)")
                            .font(.subheadline.weight(day == month.today ? .bold : .regular))
                            .foregroundStyle(day == month.today ? theme.backgroundColor : theme.body)
                            .frame(maxWidth: .infinity, minHeight: 30)
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
    }

    private var slots: [Int] {
        Array(repeating: 0, count: max(0, month.firstWeekday))
            + Array(1...max(1, month.daysInMonth))
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
