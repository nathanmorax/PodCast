//
//  StubURLProtocol.swift
//  PodcastTests
//

import Foundation

/// Serves canned responses for URLSession without touching the network.
/// Every test registers its own unique URL, so parallel tests never collide.
final class StubURLProtocol: URLProtocol {

    enum Response {
        case success(Data)
        case failure(URLError.Code)
        /// Never answers: useful to test cancellation of an in-flight download.
        case hang
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var responses: [URL: Response] = [:]

    /// Returns a unique URL that will answer with `response`.
    static func register(_ response: Response) -> URL {
        let url = URL(string: "https://stub.test/\(UUID().uuidString).mp3")!
        set(response, for: url)
        return url
    }

    static func set(_ response: Response, for url: URL) {
        lock.withLock { responses[url] = response }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = Self.lock.withLock({ Self.responses[url] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        switch response {
        case .success(let data):
            let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case .hang:
            break
        }
    }

    override func stopLoading() {}
}

extension URLSession {
    static let stubbed: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }()
}
