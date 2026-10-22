import Foundation

/// One event from a server-sent events stream.
public struct ServerSentEvent: Hashable, Sendable {
    /// The name of the event.
    public var name: String
    /// The data of the event.
    public var data: String

    public init(name: String, data: String) {
        self.name = name
        self.data = data
    }
}

/// Reads server-sent events line by line.
///
/// The parser is separate from the transport so it can be tested without a
/// network.
public struct ServerSentEventParser {
    /// The name of the event being read.
    private var name = "message"
    /// The data lines of the event being read.
    private var dataLines: [String] = []

    public init() {}

    /// Feed one line to the parser.
    ///
    /// - Returns: the finished event, when the line ended one.
    public mutating func consume(line: String) -> ServerSentEvent? {
        // A blank line ends the event.
        if line.isEmpty {
            guard !dataLines.isEmpty || name != "message" else { return nil }
            let event = ServerSentEvent(name: name, data: dataLines.joined(separator: "\n"))
            name = "message"
            dataLines = []
            return event
        }

        // A line that starts with a colon is a comment, such as a keepalive.
        if line.hasPrefix(":") { return nil }

        guard let separator = line.firstIndex(of: ":") else {
            // A field with no value.
            set(field: line, value: "")
            return nil
        }
        let field = String(line[line.startIndex..<separator])
        var value = String(line[line.index(after: separator)...])
        if value.hasPrefix(" ") {
            value.removeFirst()
        }
        set(field: field, value: value)
        return nil
    }

    private mutating func set(field: String, value: String) {
        switch field {
        case "event":
            name = value
        case "data":
            dataLines.append(value)
        default:
            break
        }
    }
}

/// Something that arrived on the live update stream.
public enum StreamEvent: Sendable {
    /// The full dashboard, sent when the stream opens.
    case dashboard(DashboardPayload)
    /// An entity the dashboard displays changed.
    case state(entityID: String, state: String, attributes: [String: JSONValue])
    /// The dashboard configuration changed.
    case refresh

    /// The name of the event as it travels on the wire.
    public var name: String {
        switch self {
        case .dashboard: return "dashboard"
        case .state: return "state"
        case .refresh: return "refresh"
        }
    }
}

/// A change the stream reported.
public struct StateChange: Decodable, Hashable, Sendable {
    /// The entity that changed.
    public var entityID: String
    /// Its new state.
    public var state: String
    /// Its new attributes.
    public var attributes: [String: JSONValue]

    public init(entityID: String, state: String, attributes: [String: JSONValue] = [:]) {
        self.entityID = entityID
        self.state = state
        self.attributes = attributes
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case state
        case attributes
    }
}
