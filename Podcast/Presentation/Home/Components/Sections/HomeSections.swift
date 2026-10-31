//
//  HomeSections.swift
//  Podcast
//

import Foundation

/// What Home's lists show. Pure, so it's tested.
enum HomeSections {

    /// "Latest Episodes" shows this many (the rest: See All, the Library).
    static let latestLimit = 8
    /// "For You" shows this many.
    static let picksLimit = 8

    /// The newest episodes of the shows you follow.
    static func latest(_ newEpisodes: [PodcastEpisode]) -> [PodcastEpisode] {
        Array(newEpisodes.prefix(latestLimit))
    }

    /// Picks not already in Latest Episodes.
    static func picks(_ picks: [PodcastEpisode], excluding latest: [PodcastEpisode]) -> [PodcastEpisode] {
        let shown = Set(latest.map(\.id))
        return Array(picks.filter { !shown.contains($0.id) }.prefix(picksLimit))
    }
}
