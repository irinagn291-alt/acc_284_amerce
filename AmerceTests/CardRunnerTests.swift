import XCTest
@testable import Amerce

private struct ProbeDTO: Decodable {
    var count: LooseFigure
}

private actor ScriptedHop: HopChannel {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func hop(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class CardRunnerTests: XCTestCase {
    private let url = URL(string: "https://amerce-gage.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let channel = ScriptedHop(results: [
            .success((Data("{\"count\":1}".utf8), http(200))),
        ])
        let runner = CardRunner(channel: channel)
        _ = try await runner.decodeParcel(ProbeDTO.self, from: url)
        let request = await channel.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), CardRunner.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(CardRunner.userAgent, "Amerce/1.0 (iOS; +https://amerce-gage.pro)")
        XCTAssertEqual(CardRunner.contactURL.absoluteString, "https://amerce-gage.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let channel = ScriptedHop(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"count\":\"4.5\"}".utf8), http(200))),
        ])
        let runner = CardRunner(channel: channel)
        let dto = try await runner.decodeParcel(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.count.value, 4.5)
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let channel = ScriptedHop(results: [
            .success((Data(), http(404))),
            .success((Data("{\"count\":1}".utf8), http(200))),
        ])
        let runner = CardRunner(channel: channel)
        do {
            _ = try await runner.decodeParcel(ProbeDTO.self, from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? RunnerFault, .vacant)
        }
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsUnreadable() async {
        let channel = ScriptedHop(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let runner = CardRunner(channel: channel)
        do {
            _ = try await runner.decodeParcel(ProbeDTO.self, from: url)
            XCTFail("expected unreadable")
        } catch {
            XCTAssertEqual(error as? RunnerFault, .unreadable)
        }
    }

    func test_statusZeroMapsToVacant() async {
        let channel = ScriptedHop(results: [
            .success((Data("{\"status\":0}".utf8), http(200))),
        ])
        let runner = CardRunner(channel: channel)
        do {
            _ = try await runner.readStatus(from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? RunnerFault, .vacant)
        }
    }

    func test_looseFigureAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"count\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"count\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"count\":null}".utf8))
        XCTAssertEqual(number.count.value, 12.5)
        XCTAssertEqual(string.count.value, 12.5)
        XCTAssertNil(missing.count.value)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
