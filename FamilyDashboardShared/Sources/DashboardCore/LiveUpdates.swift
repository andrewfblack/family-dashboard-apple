import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The live update stream.
///
/// The client never needs a Home Assistant long-lived access token: the
/// stream only carries the entities the dashboard already shows.
public enum LiveUpdates {
    /// Open the stream and return the events as they arrive.
    ///
    /// The stream closes when the consumer cancels it, or when the
    /// connection drops.
    public static func events(
        configuration: ServerConfiguration,
        session: URLSession = .shared
    ) -> AsyncStream<StreamEvent> {
        AsyncStream { continuation in
            let reader = StreamReader(continuation: continuation)
            reader.start(configuration: configuration)
            continuation.onTermination = { _ in reader.cancel() }
        }
    }

    /// Build the request for the stream.
    static func makeRequest(configuration: ServerConfiguration) -> URLRequest? {
        let url = configuration.serverURL.appending(path: "/api/family_dashboard/stream")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 0
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        if let credential = configuration.credential, !credential.isEmpty {
            request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// Turn a raw event into a value.
    static func decode(_ event: ServerSentEvent) -> StreamEvent? {
        switch event.name {
        case "dashboard":
            guard let data = event.data.data(using: .utf8),
                  let payload = try? JSONDecoder().decode(DashboardPayload.self, from: data)
            else { return nil }
            return .dashboard(payload)
        case "state":
            guard let data = event.data.data(using: .utf8),
                  let change = try? JSONDecoder().decode(StateChange.self, from: data)
            else { return nil }
            return .state(entityID: change.entityID, state: change.state, attributes: change.attributes)
        case "refresh":
            return .refresh
        default:
            return nil
        }
    }
}

/// Reads a server-sent events stream and hands the events on.
///
/// A delegate is used instead of `URLSession.bytes(for:)` because that
/// method is missing from the Linux Foundation, and the parsing should be
/// the same everywhere.
final class StreamReader: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let continuation: AsyncStream<StreamEvent>.Continuation
    private let lock = NSLock()
    private var parser = ServerSentEventParser()
    private var buffer = Data()
    private var session: URLSession?
    private var task: URLSessionDataTask?

    init(continuation: AsyncStream<StreamEvent>.Continuation) {
        self.continuation = continuation
    }

    /// Open the connection.
    func start(configuration: ServerConfiguration) {
        guard let request = LiveUpdates.makeRequest(configuration: configuration) else {
            continuation.finish()
            return
        }
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 0
        sessionConfiguration.timeoutIntervalForResource = 0
        let session = URLSession(
            configuration: sessionConfiguration,
            delegate: self,
            delegateQueue: nil
        )
        self.session = session
        let task = session.dataTask(with: request)
        self.task = task
        task.resume()
    }

    /// Close the connection.
    func cancel() {
        task?.cancel()
        session?.invalidateAndCancel()
        session = nil
        task = nil
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        lock.lock()
        buffer.append(data)
        var lines: [String] = []
        while let index = buffer.firstIndex(of: UInt8(ascii: "\n")) {
            let lineData = buffer[buffer.startIndex..<index]
            buffer.removeSubrange(buffer.startIndex...index)
            lines.append(String(decoding: lineData, as: UTF8.self))
        }
        var events: [ServerSentEvent] = []
        for line in lines {
            if let event = parser.consume(line: line) {
                events.append(event)
            }
        }
        lock.unlock()

        for event in events {
            if let value = LiveUpdates.decode(event) {
                continuation.yield(value)
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        continuation.finish()
        session.finishTasksAndInvalidate()
    }
}
