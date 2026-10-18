//
//  PodcastEndpoint.swift
//  Podcast
//

import Foundation

/// The iTunes Search API: shows and episodes.
enum PodcastEndpoint {
    case search(query: String)
    case searchEpisodes(query: String)

    var url: String {
        "https://itunes.apple.com/search"
    }

    var parameters: [String: Any] {
        switch self {
        case .search(let query):
            return ["term": query, "media": "podcast"]
        case .searchEpisodes(let query):
            return ["term": query, "media": "podcast", "entity": "podcastEpisode", "limit": 20]
        }
    }
}
