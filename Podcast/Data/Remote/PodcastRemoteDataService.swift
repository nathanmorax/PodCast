//
//  PodcastRemoteDataService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import FeedKit

final class PodcastRemoteDataService: PodcastRemoteDataSource {
    
    
    private let session: URLSession

    /// - Parameter session: tests pass a stubbed one.
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// GET the endpoint and decode its JSON. Plain URLSession (it used to be
    /// Alamofire, for this one call).
    func request<T: Decodable & Sendable>(_ endpoint: PodcastEndpoint) async throws -> T {
        guard let url = endpoint.url else { throw PodcastServiceError.invalidURL }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw PodcastServiceError.networkFailed(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw PodcastServiceError.networkFailed(URLError(.badServerResponse))
        }
        guard !data.isEmpty else { throw PodcastServiceError.emptyResponse }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
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
            throw PodcastServiceError.invalidURL
        }
        
        // Already off the main actor (nonisolated async). A detached task with
        // .background priority made the screen wait longer and couldn't be
        // cancelled when the user left.
        let feed = try await Feed(url: url)
        
        switch feed {
        case .rss(let rssFeed):
            return PodcastFeed(
                description: rssFeed.toPodcastDescription(),
                episodes: rssFeed.toEpisodes()
            )
        case .atom, .json:
            return PodcastFeed(description: nil, episodes: [])
        }
    }
}
