//
//  PodcastRemoteDataService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import FeedKit

final class PodcastRemoteDataService: PodcastRemoteDataSource {
    
    
    func request<T: Decodable & Sendable>(_ endpoint: PodcastEndpoint) async throws -> T {
        
        let response = await AF
            .request(endpoint.url, parameters: endpoint.parameters)
            .serializingDecodable(T.self)
            .response
        
        switch response.result {
        case .success(let value):
            return value
        case .failure(let error):
            throw PodcastServiceError.networkFailed(error)
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
