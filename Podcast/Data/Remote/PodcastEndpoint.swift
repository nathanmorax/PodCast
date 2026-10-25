//
//  PodcastEndpoint.swift
//  Podcast
//

import Foundation

/// The iTunes Search API: shows and episodes.
enum PodcastEndpoint {
    case search(query: String)
    case searchEpisodes(query: String)

    private static let baseURL = "https://itunes.apple.com/search"

    /// Query values as text: what goes in the URL.
    var parameters: [String: String] {
        switch self {
        case .search(let query):
            return ["term": query, "media": "podcast"]
        case .searchEpisodes(let query):
            return ["term": query, "media": "podcast", "entity": "podcastEpisode", "limit": "20"]
        }
    }

    /// The full URL, query included ("term" is percent-encoded here). Keys
    /// sorted, so the same search is always the same URL (URLCache hits).
    var url: URL? {
        var components = URLComponents(string: Self.baseURL)
        components?.queryItems = parameters
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url
    }
}
