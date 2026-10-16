//
//  RecentlyPlayed.swift
//  Podcast
//

import Foundation

/// One episode the listener played, with when and how far they got.
struct RecentlyPlayed: Codable, Identifiable {
    let episode: Episode
    var lastPlayedAt: Date
    /// 0...1, saved when the listener switches to another episode.
    var progress: Double

    var id: String { episode.streamUrl }
}
