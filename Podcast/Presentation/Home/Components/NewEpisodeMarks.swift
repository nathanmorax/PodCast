//
//  NewEpisodeMarks.swift
//  Podcast
//

import Foundation

/// Which followed shows have new episodes, for their covers in Home. Pure,
/// so it's tested.
enum NewEpisodeMarks {

    /// At most this many new episodes peek out from behind a cover.
    static let maxPeeking = 2

    /// trackId → its new episodes, newest first. New = published after the
    /// later of: the Inbox's last visit, and this show's page's last visit.
    /// Shows with none are left out.
    static func newEpisodes(
        podcasts: [Podcast],
        episodes: [Int: [Episode]],
        inboxSeen: Date,
        showSeen: [Int: Date],
        now: Date = .now
    ) -> [Int: [Episode]] {
        var result: [Int: [Episode]] = [:]
        for podcast in podcasts {
            let since = max(inboxSeen, showSeen[podcast.trackId] ?? .distantPast)
            let new = (episodes[podcast.trackId] ?? [])
                .filter { $0.pubDate > since && $0.pubDate <= now }
                .sorted { $0.pubDate > $1.pubDate }
            if !new.isEmpty { result[podcast.trackId] = new }
        }
        return result
    }
}
