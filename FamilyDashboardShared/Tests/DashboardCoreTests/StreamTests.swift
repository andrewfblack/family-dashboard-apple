import Foundation
import XCTest

@testable import DashboardCore

/// Tests for reading the live update stream.
final class StreamTests: XCTestCase {
    func testAnEventIsRead() {
        var parser = ServerSentEventParser()

        XCTAssertNil(parser.consume(line: "event: state"))
        XCTAssertNil(parser.consume(line: "data: {\"entity_id\":\"light.kitchen\"}"))

        let event = parser.consume(line: "")

        XCTAssertEqual(event?.name, "state")
        XCTAssertEqual(event?.data, "{\"entity_id\":\"light.kitchen\"}")
    }

    func testAMultiLineEventIsJoined() {
        var parser = ServerSentEventParser()

        _ = parser.consume(line: "event: dashboard")
        _ = parser.consume(line: "data: {\"ok\":true,")
        _ = parser.consume(line: "data: \"title\":\"Family Dashboard\"}")

        let event = parser.consume(line: "")

        XCTAssertEqual(event?.data, "{\"ok\":true,\n\"title\":\"Family Dashboard\"}")
    }

    func testACommentIsIgnored() {
        var parser = ServerSentEventParser()

        XCTAssertNil(parser.consume(line: ": keepalive"))
        XCTAssertNil(parser.consume(line: ""))
    }

    func testTheParserIsReadyForTheNextEvent() {
        var parser = ServerSentEventParser()

        _ = parser.consume(line: "event: state")
        _ = parser.consume(line: "data: one")
        _ = parser.consume(line: "")

        _ = parser.consume(line: "event: refresh")
        let event = parser.consume(line: "")

        XCTAssertEqual(event?.name, "refresh")
    }

    func testAValueWithoutASpaceIsRead() {
        var parser = ServerSentEventParser()

        _ = parser.consume(line: "event:refresh")
        let event = parser.consume(line: "")

        XCTAssertEqual(event?.name, "refresh")
    }

    func testTheDashboardEventBecomesAPayload() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "payload", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(DashboardPayload.self, from: data)
        let event = ServerSentEvent(name: "dashboard", data: String(decoding: data, as: UTF8.self))

        guard case let .dashboard(decoded) = LiveUpdates.decode(event) else {
            return XCTFail("Expected a dashboard event.")
        }
        XCTAssertEqual(decoded.title, payload.title)
        XCTAssertEqual(decoded.schemaVersion, payload.schemaVersion)
    }

    func testTheStateEventBecomesAChange() {
        let event = ServerSentEvent(
            name: "state",
            data: "{\"entity_id\":\"light.kitchen\",\"state\":\"on\",\"attributes\":{\"brightness\":128}}"
        )

        guard case let .state(entityID, state, attributes) = LiveUpdates.decode(event) else {
            return XCTFail("Expected a state event.")
        }
        XCTAssertEqual(entityID, "light.kitchen")
        XCTAssertEqual(state, "on")
        XCTAssertEqual(attributes["brightness"]?.numberValue, 128)
    }

    func testTheRefreshEventIsRead() {
        let event = ServerSentEvent(name: "refresh", data: "{\"reason\":\"options_changed\"}")

        guard case .refresh = LiveUpdates.decode(event) else {
            return XCTFail("Expected a refresh event.")
        }
    }

    func testAnUnknownEventIsIgnored() {
        XCTAssertNil(LiveUpdates.decode(ServerSentEvent(name: "nonsense", data: "{}")))
    }
}
