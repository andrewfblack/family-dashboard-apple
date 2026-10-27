import Foundation
import XCTest

@testable import DashboardCore

/// Tests for reading the dashboard payload.
///
/// The fixture is a real payload from the Home Assistant integration, so these
/// tests fail when the contract changes.
final class PayloadTests: XCTestCase {
    private func fixture() throws -> DashboardPayload {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "payload", withExtension: "json"),
            "The payload fixture is missing."
        )
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DashboardPayload.self, from: data)
    }

    func testThePayloadDecodes() throws {
        let payload = try fixture()

        XCTAssertTrue(payload.ok)
        XCTAssertEqual(payload.schemaVersion, 3)
        XCTAssertEqual(payload.title, "Family Dashboard")
        XCTAssertNotNil(payload.serverTime)
    }

    func testTheThemeComesReadyToUse() throws {
        let payload = try fixture()

        XCTAssertTrue(payload.theme.accent.hasPrefix("#"))
        XCTAssertEqual(payload.theme.accent.count, 7)
        XCTAssertEqual(payload.theme.itemOpacity, 90)
        XCTAssertEqual(payload.theme.remoteButtonBackground, "#000000")
        XCTAssertEqual(payload.theme.remoteButtonText, "#FFFFFF")
    }

    func testTheEntitiesAreResolved() throws {
        let payload = try fixture()

        XCTAssertEqual(payload.resolvedEntities.inside, "sensor.inside")
        XCTAssertEqual(payload.resolvedEntities.outside, "weather.home")
        XCTAssertEqual(payload.states["sensor.inside"]?.state, "21.5")
    }

    func testTheMealPlanIsRead() throws {
        let payload = try fixture()

        XCTAssertEqual(payload.mealPlan, "Tacos")
        XCTAssertEqual(payload.weeklyMealPlan.count, 7)
        XCTAssertEqual(payload.weeklyMealPlan.first?.day, "Monday")
        XCTAssertEqual(payload.weeklyMealPlan.first?.meal, "Pasta")
        XCTAssertEqual(payload.weeklyMealPlan.first?.isToday, false)
        XCTAssertTrue(payload.weeklyMealPlan[2].isToday)
    }

    func testTheEventsAreRead() throws {
        let payload = try fixture()

        XCTAssertEqual(payload.calendarEvents.first?.title, "Soccer")
        XCTAssertEqual(payload.calendarEvents.first?.allDay, false)
        XCTAssertFalse(payload.calendarSchedule.days.isEmpty)
        XCTAssertTrue(payload.calendarSchedule.days.first?.isToday == true)
        XCTAssertEqual(payload.nextHoliday?.title, "Halloween")
        XCTAssertEqual(payload.nextHoliday?.start, "2026-10-31")
    }

    func testTheControlsAreRead() throws {
        let payload = try fixture()

        XCTAssertEqual(payload.lights.count, 1)
        XCTAssertEqual(payload.lights.first?.name, "Kitchen")
        XCTAssertEqual(payload.lights.first?.isOn, true)
        XCTAssertEqual(payload.lights.first?.brightness, 200)

        XCTAssertEqual(payload.scenes.first?.name, "Movie")

        XCTAssertEqual(payload.climates.first?.name, "Hall")
        XCTAssertEqual(payload.climates.first?.hvacModes, ["heat", "off"])
        XCTAssertEqual(payload.climates.first?.targetTempStep, 0.5)

        XCTAssertTrue(payload.tabs.remote)
        XCTAssertEqual(payload.remotes.first?.kind, "roku")
        XCTAssertEqual(payload.remotes.first?.remoteEntityID, "remote.living_room_roku")
        XCTAssertTrue(payload.remotes.first?.commands.contains("replay") == true)
    }

    func testTheCapabilitiesAreRead() throws {
        let payload = try fixture()

        XCTAssertTrue(payload.capabilities.stream)
        XCTAssertTrue(payload.capabilities.actions.contains("light_toggle"))
        XCTAssertTrue(payload.tabs.weather)
    }

    func testTheWeatherIsRead() throws {
        let payload = try fixture()

        XCTAssertTrue(payload.weather.enabled)
        XCTAssertEqual(payload.weather.condition, "sunny")
        XCTAssertEqual(payload.weather.temperature, 19.2)
        XCTAssertEqual(payload.weather.forecast.first?.condition, "sunny")
    }

    func testAMissingThemeValueFallsBack() throws {
        let json = """
        {"ok": true, "theme": {"accent": "#123456"}}
        """
        let payload = try JSONDecoder().decode(DashboardPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload.theme.accent, "#123456")
        XCTAssertEqual(payload.theme.bodyText, Theme().bodyText)
    }

    func testAPayloadWithoutOptionalFieldsStillDecodes() throws {
        let json = """
        {"ok": true, "title": "Family Dashboard"}
        """
        let payload = try JSONDecoder().decode(DashboardPayload.self, from: Data(json.utf8))

        XCTAssertTrue(payload.ok)
        XCTAssertEqual(payload.title, "Family Dashboard")
        XCTAssertTrue(payload.lights.isEmpty)
        XCTAssertEqual(payload.weeklyMealPlan.count, 0)
        XCTAssertNil(payload.nextHoliday)
        XCTAssertTrue(payload.remotes.isEmpty)
    }

    func testAnUnknownFieldIsIgnored() throws {
        let json = """
        {"ok": true, "title": "Family Dashboard", "something_new": {"a": 1}}
        """
        let payload = try JSONDecoder().decode(DashboardPayload.self, from: Data(json.utf8))

        XCTAssertEqual(payload.title, "Family Dashboard")
    }
}
