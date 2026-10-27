import Foundation
import XCTest

@testable import DashboardCore

/// Tests for folding a live update into the dashboard.
final class LiveUpdateTests: XCTestCase {
    private func fixture() throws -> DashboardPayload {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "payload", withExtension: "json"))
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DashboardPayload.self, from: data)
    }

    func testALightChangeIsFoldedIn() throws {
        let payload = try fixture()
        let change = StateChange(
            entityID: "light.kitchen",
            state: "off",
            attributes: ["brightness": JSONValue.number(0)]
        )

        let updated = payload.applying(change)

        XCTAssertEqual(updated.lights.first?.state, "off")
        XCTAssertFalse(updated.lights.first?.isOn ?? true)
        XCTAssertEqual(updated.states["light.kitchen"]?.state, "off")
        XCTAssertEqual(updated.states["light.kitchen"]?.attributes["brightness"]?.numberValue, 0)
    }

    func testAClimateChangeIsFoldedIn() throws {
        let payload = try fixture()
        let change = StateChange(
            entityID: "climate.hall",
            state: "cool",
            attributes: [
                "current_temperature": JSONValue.number(19.5),
                "temperature": JSONValue.number(20),
                "hvac_action": JSONValue.string("cooling"),
            ]
        )

        let updated = payload.applying(change)

        XCTAssertEqual(updated.climates.first?.state, "cool")
        XCTAssertEqual(updated.climates.first?.currentTemperature, 19.5)
        XCTAssertEqual(updated.climates.first?.temperature, 20)
        XCTAssertEqual(updated.climates.first?.hvacAction, "cooling")
    }

    func testAMealChangeIsFoldedIn() throws {
        let payload = try fixture()
        let change = StateChange(
            entityID: "input_text.meal",
            state: "Sushi",
            attributes: [:]
        )

        let updated = payload.applying(change)

        XCTAssertEqual(updated.states["input_text.meal"]?.state, "Sushi")
    }

    func testARemotePlayerChangeIsFoldedIn() throws {
        let payload = try fixture()
        let change = StateChange(
            entityID: "media_player.living_room_roku",
            state: "paused",
            attributes: [
                "volume_level": JSONValue.number(0.5),
                "is_volume_muted": JSONValue.bool(true),
                "media_title": JSONValue.string("Another Movie"),
            ]
        )

        let updated = payload.applying(change)

        XCTAssertEqual(updated.remotes.first?.state, "paused")
        XCTAssertEqual(updated.remotes.first?.volumeLevel, 0.5)
        XCTAssertEqual(updated.remotes.first?.isVolumeMuted, true)
        XCTAssertEqual(updated.remotes.first?.mediaTitle, "Another Movie")
    }

    func testTheOriginalPayloadIsNotChanged() throws {
        let payload = try fixture()
        let change = StateChange(entityID: "light.kitchen", state: "off", attributes: [:])

        _ = payload.applying(change)

        XCTAssertEqual(payload.lights.first?.state, "on")
    }

    func testTheTemperaturesAreRead() throws {
        let payload = try fixture()

        XCTAssertEqual(payload.insideTemperature, 21.5)
        XCTAssertEqual(payload.insideHumidity, 45)
        XCTAssertEqual(payload.outsideTemperature, 19.2)
        XCTAssertEqual(payload.outsideCondition, "sunny")
    }
}

/// Tests for the tabs.
final class TabTests: XCTestCase {
    func testTheHomeTabIsAlwaysThere() {
        let tabs = Tabs(
            calendar: false,
            weather: false,
            lights: false,
            scenes: false,
            climate: false,
            security: false,
            remote: false
        )

        XCTAssertEqual(DashboardTab.enabled(in: tabs), [.home])
    }

    func testEveryTabCanBeSwitchedOn() {
        let tabs = Tabs(
            calendar: true,
            weather: true,
            lights: true,
            scenes: true,
            climate: true,
            security: true,
            remote: true
        )

        XCTAssertEqual(DashboardTab.enabled(in: tabs), DashboardTab.allCases)
    }

    func testTheTabsKeepTheirOrder() {
        let tabs = Tabs(calendar: true, weather: false, lights: true, scenes: false, climate: true)

        XCTAssertEqual(DashboardTab.enabled(in: tabs), [.home, .calendar, .lights, .climate])
    }

    func testPreferredTabOrderAppendsNewlyAvailableTabs() {
        let ordered = DashboardTab.ordered(
            [.home, .calendar, .weather, .remote],
            preferred: [.remote, .home]
        )

        XCTAssertEqual(ordered, [.remote, .home, .calendar, .weather])
    }

    func testEveryTabHasANameAndASymbol() {
        for tab in DashboardTab.allCases {
            XCTAssertFalse(tab.title.isEmpty)
            XCTAssertFalse(tab.symbol.isEmpty)
        }
    }
}
