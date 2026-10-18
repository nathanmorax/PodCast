//
//  EpisodeSearchResults.swift
//  Podcast
//

import Foundation

/// iTunes search with `entity=podcastEpisode`.
struct EpisodeSearchResults: Decodable, Sendable {
    let results: [EpisodeSearchItem]
}

struct EpisodeSearchItem: Decodable, Sendable {
    let trackName: String?
    let collectionName: String?
    let artistName: String?
    /// ISO 8601, e.g. "2026-10-16T10:00:00Z".
    let releaseDate: String?
    let trackTimeMillis: Int?
    let shortDescription: String?
    let description: String?
    let episodeUrl: String?
    let artworkUrl600: String?
}
