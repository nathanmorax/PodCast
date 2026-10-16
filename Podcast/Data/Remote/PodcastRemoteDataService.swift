//
//  PodcastRemoteDataService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import Alamofire
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
    
    
    /// The podcast categories (iTunes genre 26's subgenres), sorted by name.
    /// Before: a callback that never fired when the response had no data
    /// (the screen loaded forever) and a random order on every launch.
    func fetchGenres() async throws -> [Genre] {
        let result: [String: GenreResponse] = try await request(.genres)
        guard let subgenres = result.values.first?.subgenres?.values else { return [] }
        return subgenres
            .map { Genre(id: $0.id, name: $0.name) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .prefix(15)
            .map { $0 }
    }
}
