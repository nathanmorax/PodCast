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

    /// From here on an episode counts as finished.
    static let finishedThreshold = 0.98

    /// Where to start it again: where it was left, or the beginning once
    /// it was finished.
    var resumeProgress: Double {
        progress < Self.finishedThreshold ? progress : 0
    }
}
