//
//  PodcastEpisode.swift
//  Podcast
//

import Foundation

/// An episode with the podcast it belongs to: what "For you" and the Inbox
/// list (each card or row shows both).
struct PodcastEpisode: Identifiable, Sendable {
    let podcast: Podcast
    let episode: Episode
    var id: String { episode.streamUrl }
}
