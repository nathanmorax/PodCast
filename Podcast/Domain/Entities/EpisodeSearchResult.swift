//
//  EpisodeSearchResult.swift
//  Podcast
//

import Foundation

/// An episode found by Search, with the name of the show it belongs to
/// (the episode alone only knows its author).
struct EpisodeSearchResult: Sendable, Identifiable {
    let episode: Episode
    let podcastName: String

    var id: String { episode.streamUrl }
}
