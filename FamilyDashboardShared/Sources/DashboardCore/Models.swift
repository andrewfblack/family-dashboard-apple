import Foundation

/// The theme the administrator picked in Home Assistant.
///
/// Every colour arrives as a `#RRGGBB` string, so no client has to convert a
/// colour itself. A missing value falls back to the built-in default rather
/// than failing the whole decode.
public struct Theme: Codable, Hashable, Sendable {
    /// The colour of the screen title.
    public var headerText: String
    /// The colour of a card heading.
    public var itemHeaderText: String
    /// The colour of body text.
    public var bodyText: String
    /// The colour of secondary text.
    public var mutedText: String
    /// The accent colour.
    public var accent: String
    /// The fallback background colour.
    public var background: String
    /// The colour behind a card.
    public var itemBackground: String
    /// The colour behind a selected card.
    public var selectedBackground: String
    /// The colour of a selected card's border.
    public var selectedBorder: String
    /// The colour of a card's border.
    public var itemBorder: String
    /// How solid the cards are, from 0 to 100.
    public var itemOpacity: Int
    /// How much the background is darkened, from 0 to 100.
    public var backgroundOverlay: Int

    public init(
        headerText: String = "#FFF7EA",
        itemHeaderText: String = "#EFB26C",
        bodyText: String = "#FFF7EA",
        mutedText: String = "#CDBDA9",
        accent: String = "#E18A45",
        background: String = "#17100B",
        itemBackground: String = "#1F1711",
        selectedBackground: String = "#9B542B",
        selectedBorder: String = "#FFD28C",
        itemBorder: String = "#59483C",
        itemOpacity: Int = 90,
        backgroundOverlay: Int = 48
    ) {
        self.headerText = headerText
        self.itemHeaderText = itemHeaderText
        self.bodyText = bodyText
        self.mutedText = mutedText
        self.accent = accent
        self.background = background
        self.itemBackground = itemBackground
        self.selectedBackground = selectedBackground
        self.selectedBorder = selectedBorder
        self.itemBorder = itemBorder
        self.itemOpacity = itemOpacity
        self.backgroundOverlay = backgroundOverlay
    }

    private enum CodingKeys: String, CodingKey {
        case headerText = "header_text"
        case itemHeaderText = "item_header_text"
        case bodyText = "body_text"
        case mutedText = "muted_text"
        case accent
        case background
        case itemBackground = "item_background"
        case selectedBackground = "selected_background"
        case selectedBorder = "selected_border"
        case itemBorder = "item_border"
        case itemOpacity = "item_opacity"
        case backgroundOverlay = "background_overlay"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Theme()
        headerText = try container.decodeIfPresent(String.self, forKey: .headerText) ?? defaults.headerText
        itemHeaderText = try container.decodeIfPresent(String.self, forKey: .itemHeaderText) ?? defaults.itemHeaderText
        bodyText = try container.decodeIfPresent(String.self, forKey: .bodyText) ?? defaults.bodyText
        mutedText = try container.decodeIfPresent(String.self, forKey: .mutedText) ?? defaults.mutedText
        accent = try container.decodeIfPresent(String.self, forKey: .accent) ?? defaults.accent
        background = try container.decodeIfPresent(String.self, forKey: .background) ?? defaults.background
        itemBackground = try container.decodeIfPresent(String.self, forKey: .itemBackground) ?? defaults.itemBackground
        selectedBackground = try container.decodeIfPresent(String.self, forKey: .selectedBackground) ?? defaults.selectedBackground
        selectedBorder = try container.decodeIfPresent(String.self, forKey: .selectedBorder) ?? defaults.selectedBorder
        itemBorder = try container.decodeIfPresent(String.self, forKey: .itemBorder) ?? defaults.itemBorder
        itemOpacity = try container.decodeIfPresent(Int.self, forKey: .itemOpacity) ?? defaults.itemOpacity
        backgroundOverlay = try container.decodeIfPresent(Int.self, forKey: .backgroundOverlay) ?? defaults.backgroundOverlay
    }
}

/// What this dashboard supports.
public struct Capabilities: Codable, Hashable, Sendable {
    /// The actions the server accepts.
    public var actions: [String]
    /// Whether the client can subscribe to live updates.
    public var stream: Bool
    /// Whether an uploaded background is available.
    public var background: Bool
    /// Whether the dashboard carries a theme.
    public var theme: Bool
    /// Whether the weekly meal plan can be edited.
    public var weeklyMeals: Bool
    /// Whether the rolling schedule is available.
    public var schedule: Bool

    public init(
        actions: [String] = [],
        stream: Bool = false,
        background: Bool = false,
        theme: Bool = false,
        weeklyMeals: Bool = false,
        schedule: Bool = false
    ) {
        self.actions = actions
        self.stream = stream
        self.background = background
        self.theme = theme
        self.weeklyMeals = weeklyMeals
        self.schedule = schedule
    }

    private enum CodingKeys: String, CodingKey {
        case actions
        case stream
        case background
        case theme
        case weeklyMeals = "weekly_meals"
        case schedule
    }
}

/// The state of one entity the dashboard displays.
public struct EntityState: Codable, Hashable, Sendable {
    /// The raw state of the entity.
    public var state: String
    /// The attributes of the entity.
    public var attributes: [String: JSONValue]

    public init(state: String, attributes: [String: JSONValue] = [:]) {
        self.state = state
        self.attributes = attributes
    }
}

/// The entity ids the dashboard resolved for its panels.
public struct ResolvedEntities: Codable, Hashable, Sendable {
    /// The indoor temperature entity.
    public var inside: String?
    /// The indoor humidity entity.
    public var insideHumidity: String?
    /// The outdoor weather entity.
    public var outside: String?

    public init(inside: String? = nil, insideHumidity: String? = nil, outside: String? = nil) {
        self.inside = inside
        self.insideHumidity = insideHumidity
        self.outside = outside
    }

    private enum CodingKeys: String, CodingKey {
        case inside
        case insideHumidity = "inside_humidity"
        case outside
    }
}

/// One day of the weekly meal plan.
public struct WeeklyMeal: Codable, Hashable, Identifiable, Sendable {
    /// The name of the day.
    public var day: String
    /// The meal for that day.
    public var meal: String
    /// Whether this is today.
    public var isToday: Bool

    public var id: String { day }

    public init(day: String, meal: String, isToday: Bool) {
        self.day = day
        self.meal = meal
        self.isToday = isToday
    }

    private enum CodingKeys: String, CodingKey {
        case day
        case meal
        case isToday = "is_today"
    }
}

/// One event on a calendar.
public struct CalendarEvent: Codable, Hashable, Identifiable, Sendable {
    /// The title of the event.
    public var title: String
    /// The start of the event.
    public var start: String
    /// Whether the event lasts all day.
    public var allDay: Bool
    /// The calendar the event came from.
    public var calendarID: String?
    /// The readable name of the calendar.
    public var calendarName: String?
    /// The colour of the event, as hex without a hash.
    public var color: String?

    public var id: String { "\(calendarID ?? "")-\(start)-\(title)" }

    public init(
        title: String,
        start: String,
        allDay: Bool = false,
        calendarID: String? = nil,
        calendarName: String? = nil,
        color: String? = nil
    ) {
        self.title = title
        self.start = start
        self.allDay = allDay
        self.calendarID = calendarID
        self.calendarName = calendarName
        self.color = color
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case start
        case allDay = "all_day"
        case calendarID = "calendar_id"
        case calendarName = "calendar_name"
        case color
    }

    /// The start of the event as a date.
    public var startDate: Date? {
        Self.parseDate(start)
    }

    /// The start time, or "All day" when the event lasts all day.
    public var timeLabel: String {
        guard !allDay, let date = startDate else { return "All day" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    static func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) { return date }
        let plain = DateFormatter()
        plain.dateFormat = "yyyy-MM-dd"
        plain.timeZone = TimeZone.current
        return plain.date(from: value)
    }
}

/// The month overview.
public struct MonthCalendar: Codable, Hashable, Sendable {
    /// The title of the month.
    public var title: String
    /// The year.
    public var year: Int
    /// The month, starting at one.
    public var month: Int
    /// The day of the month that is today.
    public var today: Int
    /// How many days the month has.
    public var daysInMonth: Int
    /// The weekday the month starts on.
    public var firstWeekday: Int
    /// The days of the month that hold an event.
    public var eventDays: [Int]
    /// Every event of the month.
    public var events: [CalendarEvent]

    public init(
        title: String = "",
        year: Int = 0,
        month: Int = 1,
        today: Int = 1,
        daysInMonth: Int = 30,
        firstWeekday: Int = 0,
        eventDays: [Int] = [],
        events: [CalendarEvent] = []
    ) {
        self.title = title
        self.year = year
        self.month = month
        self.today = today
        self.daysInMonth = daysInMonth
        self.firstWeekday = firstWeekday
        self.eventDays = eventDays
        self.events = events
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case year
        case month
        case today
        case daysInMonth = "days_in_month"
        case firstWeekday = "first_weekday"
        case eventDays = "event_days"
        case events
    }
}

/// One day column of the rolling schedule.
public struct CalendarDay: Codable, Hashable, Identifiable, Sendable {
    /// The date of the day.
    public var date: String
    /// The short weekday name.
    public var weekday: String
    /// The day of the month.
    public var day: Int
    /// The short month name.
    public var month: String
    /// Whether this is today.
    public var isToday: Bool
    /// Whether this is a weekend.
    public var isWeekend: Bool
    /// The events of the day.
    public var events: [CalendarEvent]
    /// How many more events the day holds.
    public var overflow: Int

    public var id: String { date }

    public init(
        date: String = "",
        weekday: String = "",
        day: Int = 0,
        month: String = "",
        isToday: Bool = false,
        isWeekend: Bool = false,
        events: [CalendarEvent] = [],
        overflow: Int = 0
    ) {
        self.date = date
        self.weekday = weekday
        self.day = day
        self.month = month
        self.isToday = isToday
        self.isWeekend = isWeekend
        self.events = events
        self.overflow = overflow
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case weekday
        case day
        case month
        case isToday = "is_today"
        case isWeekend = "is_weekend"
        case events
        case overflow
    }
}

/// The rolling schedule of the coming days.
public struct CalendarSchedule: Codable, Hashable, Sendable {
    /// The title of the schedule.
    public var title: String
    /// The day columns.
    public var days: [CalendarDay]

    public init(title: String = "", days: [CalendarDay] = []) {
        self.title = title
        self.days = days
    }
}

/// One forecast period.
public struct WeatherForecast: Codable, Hashable, Identifiable, Sendable {
    /// When the period starts.
    public var datetime: String
    /// The label the server calculated.
    public var label: String
    /// The condition, such as "sunny".
    public var condition: String
    /// The temperature.
    public var temperature: Double?
    /// The low temperature.
    public var templow: Double?
    /// The chance of rain, as a percentage.
    public var precipitationProbability: Double?
    /// The wind speed.
    public var windSpeed: Double?

    public var id: String { datetime }

    public init(
        datetime: String = "",
        label: String = "",
        condition: String = "unknown",
        temperature: Double? = nil,
        templow: Double? = nil,
        precipitationProbability: Double? = nil,
        windSpeed: Double? = nil
    ) {
        self.datetime = datetime
        self.label = label
        self.condition = condition
        self.temperature = temperature
        self.templow = templow
        self.precipitationProbability = precipitationProbability
        self.windSpeed = windSpeed
    }

    private enum CodingKeys: String, CodingKey {
        case datetime
        case label
        case condition
        case temperature
        case templow
        case precipitationProbability = "precipitation_probability"
        case windSpeed = "wind_speed"
    }
}

/// The current conditions and the forecast.
public struct Weather: Codable, Hashable, Sendable {
    /// Whether the weather tab is switched on.
    public var enabled: Bool
    /// Whether the weather entity answered.
    public var available: Bool
    /// The weather entity.
    public var entityID: String?
    /// The readable name of the weather entity.
    public var name: String?
    /// The current condition.
    public var condition: String?
    /// The current temperature.
    public var temperature: Double?
    /// The unit of the temperature.
    public var temperatureUnit: String?
    /// The humidity.
    public var humidity: Double?
    /// The pressure.
    public var pressure: Double?
    /// The wind speed.
    public var windSpeed: Double?
    /// The wind bearing.
    public var windBearing: Double?
    /// The visibility.
    public var visibility: Double?
    /// Whether the forecast is daily or hourly.
    public var forecastType: String?
    /// The forecast periods.
    public var forecast: [WeatherForecast]

    public init(
        enabled: Bool = false,
        available: Bool = false,
        entityID: String? = nil,
        name: String? = nil,
        condition: String? = nil,
        temperature: Double? = nil,
        temperatureUnit: String? = nil,
        humidity: Double? = nil,
        pressure: Double? = nil,
        windSpeed: Double? = nil,
        windBearing: Double? = nil,
        visibility: Double? = nil,
        forecastType: String? = nil,
        forecast: [WeatherForecast] = []
    ) {
        self.enabled = enabled
        self.available = available
        self.entityID = entityID
        self.name = name
        self.condition = condition
        self.temperature = temperature
        self.temperatureUnit = temperatureUnit
        self.humidity = humidity
        self.pressure = pressure
        self.windSpeed = windSpeed
        self.windBearing = windBearing
        self.visibility = visibility
        self.forecastType = forecastType
        self.forecast = forecast
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case available
        case entityID = "entity_id"
        case name
        case condition
        case temperature
        case temperatureUnit = "temperature_unit"
        case humidity
        case pressure
        case windSpeed = "wind_speed"
        case windBearing = "wind_bearing"
        case visibility
        case forecastType = "forecast_type"
        case forecast
    }
}

/// Which tabs the administrator switched on.
public struct Tabs: Codable, Hashable, Sendable {
    /// Whether the calendar tab is shown.
    public var calendar: Bool
    /// Whether the weather tab is shown.
    public var weather: Bool
    /// Whether the lights tab is shown.
    public var lights: Bool
    /// Whether the scenes tab is shown.
    public var scenes: Bool
    /// Whether the climate tab is shown.
    public var climate: Bool
    /// Whether the security tab is shown.
    public var security: Bool
    /// Whether the iOS-only remote tab is shown.
    public var remote: Bool

    public init(
        calendar: Bool = true,
        weather: Bool = true,
        lights: Bool = true,
        scenes: Bool = true,
        climate: Bool = true,
        security: Bool = false,
        remote: Bool = false
    ) {
        self.calendar = calendar
        self.weather = weather
        self.scenes = scenes
        self.lights = lights
        self.climate = climate
        self.security = security
        self.remote = remote
    }

    private enum CodingKeys: String, CodingKey {
        case calendar
        case weather
        case lights
        case scenes
        case climate
        case security
        case remote
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Tabs()
        calendar = try container.decodeIfPresent(Bool.self, forKey: .calendar) ?? defaults.calendar
        weather = try container.decodeIfPresent(Bool.self, forKey: .weather) ?? defaults.weather
        lights = try container.decodeIfPresent(Bool.self, forKey: .lights) ?? defaults.lights
        scenes = try container.decodeIfPresent(Bool.self, forKey: .scenes) ?? defaults.scenes
        climate = try container.decodeIfPresent(Bool.self, forKey: .climate) ?? defaults.climate
        security = try container.decodeIfPresent(Bool.self, forKey: .security) ?? defaults.security
        remote = try container.decodeIfPresent(Bool.self, forKey: .remote) ?? defaults.remote
    }
}

/// A security control exposed by the dashboard server.
public struct SecurityItem: Codable, Hashable, Identifiable, Sendable {
    public var entityID: String
    public var name: String
    public var state: String
    public var kind: String

    public var id: String { entityID }

    public init(entityID: String = "", name: String = "", state: String = "unknown", kind: String = "alarm") {
        self.entityID = entityID
        self.name = name
        self.state = state
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case name
        case state
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entityID = try container.decodeIfPresent(String.self, forKey: .entityID) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? "unknown"
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "alarm"
    }
}

/// One family member's presence state.
public struct FamilyPresence: Codable, Hashable, Identifiable, Sendable {
    public var name: String
    public var home: Bool

    public var id: String { name }

    public init(name: String = "", home: Bool = false) {
        self.name = name
        self.home = home
    }
}

/// Security controls and family presence.
public struct SecurityData: Codable, Hashable, Sendable {
    public var garageDoors: [SecurityItem]
    public var locks: [SecurityItem]
    public var alarm: SecurityItem?
    public var family: [FamilyPresence]

    public init(garageDoors: [SecurityItem] = [], locks: [SecurityItem] = [], alarm: SecurityItem? = nil, family: [FamilyPresence] = []) {
        self.garageDoors = garageDoors
        self.locks = locks
        self.alarm = alarm
        self.family = family
    }

    private enum CodingKeys: String, CodingKey {
        case garageDoors = "garage_doors"
        case locks
        case alarm
        case family
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        garageDoors = try container.decodeIfPresent([SecurityItem].self, forKey: .garageDoors) ?? []
        locks = try container.decodeIfPresent([SecurityItem].self, forKey: .locks) ?? []
        alarm = try container.decodeIfPresent(SecurityItem.self, forKey: .alarm)
        family = try container.decodeIfPresent([FamilyPresence].self, forKey: .family) ?? []
    }

    public var items: [SecurityItem] { garageDoors + locks + (alarm.map { [$0] } ?? []) }
}

/// A light the dashboard may control.
public struct LightCard: Codable, Hashable, Identifiable, Sendable {
    /// The entity id.
    public var entityID: String
    /// The readable name.
    public var name: String
    /// Whether the light is on.
    public var state: String
    /// The brightness, from 0 to 255.
    public var brightness: Int?
    /// The colour temperature in kelvin.
    public var colorTempKelvin: Int?

    public var id: String { entityID }
    /// Whether the light is on.
    public var isOn: Bool { state.lowercased() == "on" }

    public init(
        entityID: String,
        name: String,
        state: String = "off",
        brightness: Int? = nil,
        colorTempKelvin: Int? = nil
    ) {
        self.entityID = entityID
        self.name = name
        self.state = state
        self.brightness = brightness
        self.colorTempKelvin = colorTempKelvin
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case name
        case state
        case brightness
        case colorTempKelvin = "color_temp_kelvin"
    }
}

/// A scene or script the dashboard may activate.
public struct SceneCard: Codable, Hashable, Identifiable, Sendable {
    /// The entity id.
    public var entityID: String
    /// The readable name.
    public var name: String
    /// The state of the entity.
    public var state: String?

    public var id: String { entityID }

    public init(entityID: String, name: String, state: String? = nil) {
        self.entityID = entityID
        self.name = name
        self.state = state
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case name
        case state
    }
}

/// A thermostat the dashboard may control.
public struct ClimateCard: Codable, Hashable, Identifiable, Sendable {
    /// The entity id.
    public var entityID: String
    /// The readable name.
    public var name: String
    /// The current mode.
    public var state: String
    /// The temperature right now.
    public var currentTemperature: Double?
    /// The target temperature.
    public var temperature: Double?
    /// The low end of the target range.
    public var targetTempLow: Double?
    /// The high end of the target range.
    public var targetTempHigh: Double?
    /// The humidity.
    public var humidity: Double?
    /// What the thermostat is doing.
    public var hvacAction: String?
    /// The modes the thermostat supports.
    public var hvacModes: [String]
    /// The lowest temperature the thermostat allows.
    public var minTemp: Double?
    /// The highest temperature the thermostat allows.
    public var maxTemp: Double?
    /// How much one step changes the temperature.
    public var targetTempStep: Double

    public var id: String { entityID }

    public init(
        entityID: String,
        name: String,
        state: String = "off",
        currentTemperature: Double? = nil,
        temperature: Double? = nil,
        targetTempLow: Double? = nil,
        targetTempHigh: Double? = nil,
        humidity: Double? = nil,
        hvacAction: String? = nil,
        hvacModes: [String] = [],
        minTemp: Double? = nil,
        maxTemp: Double? = nil,
        targetTempStep: Double = 1
    ) {
        self.entityID = entityID
        self.name = name
        self.state = state
        self.currentTemperature = currentTemperature
        self.temperature = temperature
        self.targetTempLow = targetTempLow
        self.targetTempHigh = targetTempHigh
        self.humidity = humidity
        self.hvacAction = hvacAction
        self.hvacModes = hvacModes
        self.minTemp = minTemp
        self.maxTemp = maxTemp
        self.targetTempStep = targetTempStep
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case name
        case state
        case currentTemperature = "current_temperature"
        case temperature
        case targetTempLow = "target_temp_low"
        case targetTempHigh = "target_temp_high"
        case humidity
        case hvacAction = "hvac_action"
        case hvacModes = "hvac_modes"
        case minTemp = "min_temp"
        case maxTemp = "max_temp"
        case targetTempStep = "target_temp_step"
    }

    /// The temperature shown as the target, whichever field holds it.
    public var displayTarget: Double? {
        temperature ?? targetTempLow ?? currentTemperature
    }
}

/// A television or streaming player controlled by the iOS remote.
public struct RemoteCard: Codable, Hashable, Identifiable, Sendable {
    public var entityID: String
    public var remoteEntityID: String?
    public var name: String
    public var kind: String
    public var state: String
    public var volumeLevel: Double?
    public var isVolumeMuted: Bool
    public var mediaTitle: String?
    public var mediaArtist: String?
    public var source: String?
    public var sourceList: [String]
    public var commands: [String]

    public var id: String { entityID }

    public init(
        entityID: String,
        remoteEntityID: String? = nil,
        name: String,
        kind: String = "generic",
        state: String = "unknown",
        volumeLevel: Double? = nil,
        isVolumeMuted: Bool = false,
        mediaTitle: String? = nil,
        mediaArtist: String? = nil,
        source: String? = nil,
        sourceList: [String] = [],
        commands: [String] = []
    ) {
        self.entityID = entityID
        self.remoteEntityID = remoteEntityID
        self.name = name
        self.kind = kind
        self.state = state
        self.volumeLevel = volumeLevel
        self.isVolumeMuted = isVolumeMuted
        self.mediaTitle = mediaTitle
        self.mediaArtist = mediaArtist
        self.source = source
        self.sourceList = sourceList
        self.commands = commands
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case remoteEntityID = "remote_entity_id"
        case name
        case kind
        case state
        case volumeLevel = "volume_level"
        case isVolumeMuted = "is_volume_muted"
        case mediaTitle = "media_title"
        case mediaArtist = "media_artist"
        case source
        case sourceList = "source_list"
        case commands
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entityID = try container.decode(String.self, forKey: .entityID)
        remoteEntityID = try container.decodeIfPresent(String.self, forKey: .remoteEntityID)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? entityID
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "generic"
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? "unknown"
        volumeLevel = try container.decodeIfPresent(Double.self, forKey: .volumeLevel)
        isVolumeMuted = try container.decodeIfPresent(Bool.self, forKey: .isVolumeMuted) ?? false
        mediaTitle = try container.decodeIfPresent(String.self, forKey: .mediaTitle)
        mediaArtist = try container.decodeIfPresent(String.self, forKey: .mediaArtist)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        sourceList = try container.decodeIfPresent([String].self, forKey: .sourceList) ?? []
        commands = try container.decodeIfPresent([String].self, forKey: .commands) ?? []
    }
}

/// Everything a client needs to draw the dashboard.
public struct DashboardPayload: Codable, Hashable, Sendable {
    /// Whether the payload is valid.
    public var ok: Bool
    /// The version of the contract.
    public var schemaVersion: Int
    /// When the server built the payload.
    public var serverTime: String?
    /// The identifier of the dashboard.
    public var dashboardID: String?
    /// The network policy in force.
    public var accessMode: String?
    /// The name of the dashboard.
    public var title: String
    /// The colours.
    public var theme: Theme
    /// What the dashboard supports.
    public var capabilities: Capabilities
    /// The state of every entity the dashboard displays.
    public var states: [String: EntityState]
    /// The entity ids the dashboard resolved.
    public var resolvedEntities: ResolvedEntities
    /// The meal for today.
    public var mealPlan: String
    /// The plan for the whole week.
    public var weeklyMealPlan: [WeeklyMeal]
    /// The next events of today.
    public var calendarEvents: [CalendarEvent]
    /// Every event of today.
    public var todayEvents: [CalendarEvent]
    /// The month overview.
    public var monthCalendar: MonthCalendar
    /// The rolling schedule.
    public var calendarSchedule: CalendarSchedule
    /// The next configured holiday or observance.
    public var nextHoliday: CalendarEvent?
    /// Which background to use.
    public var background: String
    /// The address of a custom background.
    public var backgroundURL: String
    /// The version of the uploaded background.
    public var backgroundVersion: String
    /// Whether an image has been uploaded.
    public var hasUploadedBackground: Bool
    /// Which layout to use.
    public var layout: String
    /// The weather.
    public var weather: Weather
    /// Which tabs to show.
    public var tabs: Tabs
    /// The lights.
    public var lights: [LightCard]
    /// The scenes.
    public var scenes: [SceneCard]
    /// The thermostats.
    public var climates: [ClimateCard]
    /// Optional security controls and presence data.
    public var security: SecurityData
    /// Media players available to the iOS-only remote.
    public var remotes: [RemoteCard]
    /// The identifier of the device that asked.
    public var deviceID: String?

    public init(
        ok: Bool = true,
        schemaVersion: Int = 3,
        serverTime: String? = nil,
        dashboardID: String? = nil,
        accessMode: String? = nil,
        title: String = "Family Dashboard",
        theme: Theme = Theme(),
        capabilities: Capabilities = Capabilities(),
        states: [String: EntityState] = [:],
        resolvedEntities: ResolvedEntities = ResolvedEntities(),
        mealPlan: String = "",
        weeklyMealPlan: [WeeklyMeal] = [],
        calendarEvents: [CalendarEvent] = [],
        todayEvents: [CalendarEvent] = [],
        monthCalendar: MonthCalendar = MonthCalendar(),
        calendarSchedule: CalendarSchedule = CalendarSchedule(),
        nextHoliday: CalendarEvent? = nil,
        background: String = "fall",
        backgroundURL: String = "",
        backgroundVersion: String = "",
        hasUploadedBackground: Bool = false,
        layout: String = "home",
        weather: Weather = Weather(),
        tabs: Tabs = Tabs(),
        lights: [LightCard] = [],
        scenes: [SceneCard] = [],
        climates: [ClimateCard] = [],
        security: SecurityData = SecurityData(),
        remotes: [RemoteCard] = [],
        deviceID: String? = nil
    ) {
        self.ok = ok
        self.schemaVersion = schemaVersion
        self.serverTime = serverTime
        self.dashboardID = dashboardID
        self.accessMode = accessMode
        self.title = title
        self.theme = theme
        self.capabilities = capabilities
        self.states = states
        self.resolvedEntities = resolvedEntities
        self.mealPlan = mealPlan
        self.weeklyMealPlan = weeklyMealPlan
        self.calendarEvents = calendarEvents
        self.todayEvents = todayEvents
        self.monthCalendar = monthCalendar
        self.calendarSchedule = calendarSchedule
        self.nextHoliday = nextHoliday
        self.background = background
        self.backgroundURL = backgroundURL
        self.backgroundVersion = backgroundVersion
        self.hasUploadedBackground = hasUploadedBackground
        self.layout = layout
        self.weather = weather
        self.tabs = tabs
        self.lights = lights
        self.scenes = scenes
        self.climates = climates
        self.security = security
        self.remotes = remotes
        self.deviceID = deviceID
    }

    private enum CodingKeys: String, CodingKey {
        case ok
        case schemaVersion = "schema_version"
        case serverTime = "server_time"
        case dashboardID = "dashboard_id"
        case accessMode = "access_mode"
        case title
        case theme
        case capabilities
        case states
        case resolvedEntities = "resolved_entities"
        case mealPlan = "meal_plan"
        case weeklyMealPlan = "weekly_meal_plan"
        case calendarEvents = "calendar_events"
        case todayEvents = "today_events"
        case monthCalendar = "month_calendar"
        case calendarSchedule = "calendar_schedule"
        case nextHoliday = "next_holiday"
        case background
        case backgroundURL = "background_url"
        case backgroundVersion = "background_version"
        case hasUploadedBackground = "has_uploaded_background"
        case layout
        case weather
        case tabs
        case lights
        case scenes
        case climates
        case security
        case remotes
        case deviceID = "device_id"
    }

    /// Decode the payload, tolerating fields this version does not know.
    ///
    /// A client has to keep working when the server grows a field, and it
    /// should not fall over when an optional field is missing, so every
    /// value has a sensible default.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DashboardPayload()
        ok = try container.decodeIfPresent(Bool.self, forKey: .ok) ?? defaults.ok
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? defaults.schemaVersion
        serverTime = try container.decodeIfPresent(String.self, forKey: .serverTime)
        dashboardID = try container.decodeIfPresent(String.self, forKey: .dashboardID)
        accessMode = try container.decodeIfPresent(String.self, forKey: .accessMode)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? defaults.title
        theme = try container.decodeIfPresent(Theme.self, forKey: .theme) ?? defaults.theme
        capabilities = try container.decodeIfPresent(Capabilities.self, forKey: .capabilities) ?? defaults.capabilities
        states = try container.decodeIfPresent([String: EntityState].self, forKey: .states) ?? [:]
        resolvedEntities = try container.decodeIfPresent(ResolvedEntities.self, forKey: .resolvedEntities) ?? defaults.resolvedEntities
        mealPlan = try container.decodeIfPresent(String.self, forKey: .mealPlan) ?? defaults.mealPlan
        weeklyMealPlan = try container.decodeIfPresent([WeeklyMeal].self, forKey: .weeklyMealPlan) ?? []
        calendarEvents = try container.decodeIfPresent([CalendarEvent].self, forKey: .calendarEvents) ?? []
        todayEvents = try container.decodeIfPresent([CalendarEvent].self, forKey: .todayEvents) ?? []
        monthCalendar = try container.decodeIfPresent(MonthCalendar.self, forKey: .monthCalendar) ?? defaults.monthCalendar
        calendarSchedule = try container.decodeIfPresent(CalendarSchedule.self, forKey: .calendarSchedule) ?? defaults.calendarSchedule
        nextHoliday = try container.decodeIfPresent(CalendarEvent.self, forKey: .nextHoliday)
        background = try container.decodeIfPresent(String.self, forKey: .background) ?? defaults.background
        backgroundURL = try container.decodeIfPresent(String.self, forKey: .backgroundURL) ?? defaults.backgroundURL
        backgroundVersion = try container.decodeIfPresent(String.self, forKey: .backgroundVersion) ?? defaults.backgroundVersion
        hasUploadedBackground = try container.decodeIfPresent(Bool.self, forKey: .hasUploadedBackground) ?? defaults.hasUploadedBackground
        layout = try container.decodeIfPresent(String.self, forKey: .layout) ?? defaults.layout
        weather = try container.decodeIfPresent(Weather.self, forKey: .weather) ?? defaults.weather
        tabs = try container.decodeIfPresent(Tabs.self, forKey: .tabs) ?? defaults.tabs
        lights = try container.decodeIfPresent([LightCard].self, forKey: .lights) ?? []
        scenes = try container.decodeIfPresent([SceneCard].self, forKey: .scenes) ?? []
        climates = try container.decodeIfPresent([ClimateCard].self, forKey: .climates) ?? []
        security = try container.decodeIfPresent(SecurityData.self, forKey: .security) ?? defaults.security
        remotes = try container.decodeIfPresent([RemoteCard].self, forKey: .remotes) ?? []
        deviceID = try container.decodeIfPresent(String.self, forKey: .deviceID)
    }
}

/// A value in an entity's attributes.
public enum JSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case .null: try container.encodeNil()
        case let .array(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        }
    }

    /// The value as a number, when it is one.
    public var numberValue: Double? {
        switch self {
        case let .number(value): return value
        case let .string(value): return Double(value)
        default: return nil
        }
    }

    /// The value as a string, when it is one.
    public var stringValue: String? {
        switch self {
        case let .string(value): return value
        case let .number(value): return String(value)
        case let .bool(value): return String(value)
        default: return nil
        }
    }

    /// The value as a Boolean, when it is one.
    public var boolValue: Bool? {
        switch self {
        case let .bool(value): return value
        case let .string(value): return Bool(value)
        default: return nil
        }
    }
}
