//
//  PodcastEpisode+Display.swift
//  Podcast
//

import Foundation

extension PodcastEpisode {

    /// The episode's own artwork, or its show's.
    var feedArtwork: String? {
        if let image = episode.imageUrl, !image.isEmpty { return image }
        return podcast.artworkUrl600
    }

    var showName: String { podcast.trackName ?? episode.author }
}
