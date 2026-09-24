import Foundation

/// Role: Pack. Number or numeric string; missing stays nil. Never a domain field.
struct LooseFigure: Sendable, Equatable, Decodable {
    var value: Double?

    init(value: Double?) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if box.decodeNil() {
            value = nil
            return
        }
        if let number = try? box.decode(Double.self) {
            value = number
            return
        }
        if let whole = try? box.decode(Int.self) {
            value = Double(whole)
            return
        }
        if let text = try? box.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Pack. Wire DTO. Mirrors JSON keys exactly; domain types never decode this payload.
struct ParcelDTO: Decodable, Sendable {
    var status: Int
    var count: LooseFigure?
}

/// Role: Pack. Typed hop failures. This product has no remote catalog.
enum RunnerFault: Error, Equatable, Sendable {
    case vacant
    case unreadable
    case lostHop
    case cutShort
    case notHTTP
}

/// Role: Pack. Injected hop so tests never leave the process.
protocol HopChannel: Sendable {
    func hop(_ request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Pack. URLSession hop with a 15 s timeout and the app User-Agent.
struct SessionHop: HopChannel {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": CardRunner.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func hop(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Pack. Owns the session. Contact URL is opened by Settings, not decoded here.
actor CardRunner {
    static let userAgent = "Amerce/1.0 (iOS; +https://amerce-gage.pro)"
    static let contactURL = URL(string: "https://amerce-gage.pro/contact-us")!

    private let channel: any HopChannel

    init(channel: any HopChannel) {
        self.channel = channel
    }

    init() {
        self.channel = SessionHop()
    }

    func decodeParcel<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await haul(ticket(for: url))
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw RunnerFault.cutShort
        } catch {
            throw RunnerFault.unreadable
        }
    }

    func readStatus(from url: URL) async throws -> Int {
        let slip = try await decodeParcel(ParcelDTO.self, from: url)
        if slip.status == 0 {
            throw RunnerFault.vacant
        }
        return slip.status
    }

    private func ticket(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func haul(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as RunnerFault {
            throw fault
        } catch is CancellationError {
            throw RunnerFault.cutShort
        } catch {
            if Self.cutShort(error) {
                throw RunnerFault.cutShort
            }
            guard Self.transient(error) else { throw RunnerFault.lostHop }
            do {
                return try await send(request)
            } catch let fault as RunnerFault {
                throw fault
            } catch is CancellationError {
                throw RunnerFault.cutShort
            } catch {
                if Self.cutShort(error) { throw RunnerFault.cutShort }
                throw RunnerFault.lostHop
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (body, reply) = try await channel.hop(request)
        guard let http = reply as? HTTPURLResponse else {
            throw RunnerFault.notHTTP
        }
        if http.statusCode == 404 {
            throw RunnerFault.vacant
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw RunnerFault.lostHop
        }
        return body
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cutShort(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
