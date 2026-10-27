import Foundation
import XCTest

@testable import DashboardCore

/// Tests for the address the app talks to.
final class ServerConfigurationTests: XCTestCase {
    func testTheDefaultAddressIsTheLocalHostName() {
        let configuration = ServerConfiguration.default

        XCTAssertEqual(configuration.address, "http://homeassistant.local:8123")
        XCTAssertNil(configuration.credential)
    }

    func testAMissingSchemeBecomesHttp() throws {
        let configuration = try ServerConfiguration.make(from: "192.168.1.50:8123")

        XCTAssertEqual(configuration.address, "http://192.168.1.50:8123")
    }

    func testAnHttpsAddressIsKept() throws {
        let configuration = try ServerConfiguration.make(from: "https://home.example.com")

        XCTAssertEqual(configuration.address, "https://home.example.com")
    }

    func testATrailingSlashIsRemoved() throws {
        let configuration = try ServerConfiguration.make(from: "http://homeassistant.local:8123/")

        XCTAssertEqual(configuration.address, "http://homeassistant.local:8123")
    }

    func testSpacesAreTrimmed() throws {
        let configuration = try ServerConfiguration.make(from: "  homeassistant.local:8123  ")

        XCTAssertEqual(configuration.address, "http://homeassistant.local:8123")
    }

    func testAnEmptyAddressIsRefused() {
        XCTAssertThrowsError(try ServerConfiguration.make(from: "   ")) { error in
            guard case .invalidServerAddress = error as? DashboardError else {
                return XCTFail("Expected an invalid address error.")
            }
        }
    }

    func testAnAddressWithoutAHostIsRefused() {
        XCTAssertThrowsError(try ServerConfiguration.make(from: "http://"))
    }
}

/// Tests for the commands the app sends.
final class ActionTests: XCTestCase {
    func testTheLightToggleNamesTheEntity() {
        let action = DashboardAction.lightToggle(entityID: "light.kitchen")

        XCTAssertEqual(action.name, "light_toggle")
        XCTAssertEqual(action.body["entity_id"] as? String, "light.kitchen")
    }

    func testTheBrightnessIsAPercentage() {
        let action = DashboardAction.lightBrightness(entityID: "light.kitchen", percent: 40)

        XCTAssertEqual(action.body["value"] as? Int, 40)
    }

    func testTheBrightnessIsKeptInRange() {
        let tooHigh = DashboardAction.lightBrightness(entityID: "light.kitchen", percent: 400)
        let tooLow = DashboardAction.lightBrightness(entityID: "light.kitchen", percent: -5)

        XCTAssertEqual(tooHigh.body["value"] as? Int, 100)
        XCTAssertEqual(tooLow.body["value"] as? Int, 1)
    }

    func testTheMealPlanCarriesSevenDays() {
        let meals = ["Pasta", "Tacos", "", "", "", "", ""]
        let action = DashboardAction.mealWeek(meals)

        XCTAssertEqual(action.name, "meal_week")
        XCTAssertEqual((action.body["value"] as? [String])?.count, 7)
    }

    func testTheClimateModeCarriesTheMode() {
        let action = DashboardAction.climateMode(entityID: "climate.hall", mode: "heat")

        XCTAssertEqual(action.body["value"] as? String, "heat")
    }

    func testARemoteCommandCarriesThePlayerAndSemanticCommand() {
        let action = DashboardAction.remoteCommand(
            entityID: "media_player.living_room_roku",
            command: "select"
        )

        XCTAssertEqual(action.name, "remote_command")
        XCTAssertEqual(action.body["entity_id"] as? String, "media_player.living_room_roku")
        XCTAssertEqual(action.body["command"] as? String, "select")
    }

    func testPreferredRemoteOrderAppendsNewPlayersStably() {
        let players = [
            RemoteCard(entityID: "media_player.den", name: "Den"),
            RemoteCard(entityID: "media_player.bedroom", name: "Bedroom"),
            RemoteCard(entityID: "media_player.kitchen", name: "Kitchen"),
        ]

        let ordered = RemoteCard.ordered(
            players,
            preferredIDs: ["media_player.bedroom", "media_player.den"]
        )

        XCTAssertEqual(ordered.map(\.entityID), [
            "media_player.bedroom",
            "media_player.den",
            "media_player.kitchen",
        ])
    }

}

/// Tests for the errors the server reports.
final class ErrorTests: XCTestCase {
    func testTheServerCodesBecomeErrors() {
        XCTAssertEqual(DashboardError.fromServer(code: "invalid_token"), .invalidToken)
        XCTAssertEqual(DashboardError.fromServer(code: "network_access_denied"), .networkAccessDenied)
        XCTAssertEqual(DashboardError.fromServer(code: "not_allowed"), .notAllowed)
    }

    func testAnUnknownCodeKeepsItsText() {
        guard case let .unknown(code) = DashboardError.fromServer(code: "something_new") else {
            return XCTFail("Expected an unknown error.")
        }
        XCTAssertEqual(code, "something_new")
    }

    func testEveryErrorHasAMessage() {
        let errors: [DashboardError] = [
            .invalidToken,
            .invalidPairingCode,
            .networkAccessDenied,
            .notAllowed,
            .pairingDenied,
            .pairingExpired,
        ]

        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
}
