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

    /// The shows with new episodes first (the one with the newest episode
    /// leading), then the rest as they were.
    static func newFirst(_ podcasts: [Podcast], newEpisodes: [Int: [Episode]]) -> [Podcast] {
        let newest = { (podcast: Podcast) in newEpisodes[podcast.trackId]?.first?.pubDate }
        return podcasts.enumerated().sorted { lhs, rhs in
            switch (newest(lhs.element), newest(rhs.element)) {
            case let (a?, b?) where a != b: return a > b
            case (.some, nil): return true
            case (nil, .some): return false
            default: return lhs.offset < rhs.offset
            }
        }
        .map(\.element)
    }
}
