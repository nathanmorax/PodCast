//
//  PodcastFeed.swift
//  Podcast
//

import Foundation

/// Everything the podcast screen needs from one RSS download: the show's
/// description and its episodes. Before, the same feed was downloaded and
/// parsed twice (once for each).
struct PodcastFeed: Sendable {
    let description: String?
    let episodes: [Episode]
}
