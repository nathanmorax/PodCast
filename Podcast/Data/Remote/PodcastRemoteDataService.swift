//
//  PodcastRemoteDataService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import FeedKit
import OSLog

final class PodcastRemoteDataService: PodcastRemoteDataSource {
    
    
    private let session: URLSession

    /// - Parameter session: tests pass a stubbed one.
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// GET the endpoint and decode its JSON. Plain URLSession (it used to be
    /// Alamofire, for this one call).
    func request<T: Decodable & Sendable>(_ endpoint: PodcastEndpoint) async throws -> T {
        guard let url = endpoint.url else {
            Logger.network.error("Invalid URL for \(String(describing: endpoint), privacy: .private)")
            throw PodcastServiceError.invalidURL
        }

        let started = ContinuousClock.now
        Logger.network.debug("→ GET \(url.logDescription, privacy: .public) \(url.query() ?? "", privacy: .private)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            Logger.network.error("✕ GET \(url.logDescription, privacy: .public) failed after \(Self.elapsed(since: started), privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw PodcastServiceError.networkFailed(error)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        Logger.network.info("← \(status, privacy: .public) \(url.logDescription, privacy: .public) · \(data.count, privacy: .public) bytes · \(Self.elapsed(since: started), privacy: .public)")

        if response is HTTPURLResponse, !(200..<300).contains(status) {
            throw PodcastServiceError.networkFailed(URLError(.badServerResponse))
        }
        guard !data.isEmpty else {
            Logger.network.error("Empty response from \(url.logDescription, privacy: .public)")
            throw PodcastServiceError.emptyResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            Logger.network.error("Couldn't decode \(String(describing: T.self), privacy: .public) from \(url.logDescription, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw PodcastServiceError.decodingFailed(error)
        }
    }
    
    
    func searchPodcast(query: String) async throws -> [Podcast] {
        let result: SearchResults = try await request(.search(query: query))
        return result.results
    }

    func searchEpisodes(query: String) async throws -> [EpisodeSearchResult] {
        let result: EpisodeSearchResults = try await request(.searchEpisodes(query: query))
        return result.results.compactMap { $0.toDomain() }
    }
    
    func fetchFeed(feedURL: String) async throws -> PodcastFeed {
        let secureURL = feedURL.replacingOccurrences(of: "http://", with: "https://")
        
        guard let url = URL(string: secureURL) else {
            Logger.network.error("Invalid feed URL")
            throw PodcastServiceError.invalidURL
        }

        let started = ContinuousClock.now
        Logger.network.debug("→ Feed \(url.logDescription, privacy: .public)")

        // Already off the main actor (nonisolated async). A detached task with
        // .background priority made the screen wait longer and couldn't be
        // cancelled when the user left.
        let feed: Feed
        do {
            feed = try await Feed(url: url)
        } catch {
            Logger.network.error("✕ Feed \(url.logDescription, privacy: .public) failed after \(Self.elapsed(since: started), privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }

        switch feed {
        case .rss(let rssFeed):
            let episodes = rssFeed.toEpisodes()
            Logger.network.info("← Feed \(url.logDescription, privacy: .public) · \(episodes.count, privacy: .public) episodes · \(Self.elapsed(since: started), privacy: .public)")
            return PodcastFeed(
                description: rssFeed.toPodcastDescription(),
                episodes: episodes
            )
        case .atom, .json:
            Logger.network.notice("← Feed \(url.logDescription, privacy: .public) isn't RSS: no episodes")
            return PodcastFeed(description: nil, episodes: [])
        }
    }

    /// "320 ms" since a start, for the logs.
    private static func elapsed(since start: ContinuousClock.Instant) -> String {
        let duration = ContinuousClock.now - start
        let ms = duration.components.seconds * 1000 + duration.components.attoseconds / 1_000_000_000_000_000
        return "\(ms) ms"
    }
}
