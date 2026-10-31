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

    /// The shows by their latest episode, the most recent first, so a show
    /// that just published moves to the front and stays there after you
    /// open it (until another one publishes). Shows whose feed hasn't
    /// loaded go last, as they were.
    static func latestFirst(_ podcasts: [Podcast], episodes: [Int: [Episode]]) -> [Podcast] {
        let latest = { (podcast: Podcast) in episodes[podcast.trackId]?.map(\.pubDate).max() }
        return podcasts.enumerated().sorted { lhs, rhs in
            switch (latest(lhs.element), latest(rhs.element)) {
            case let (a?, b?) where a != b: return a > b
            case (.some, nil): return true
            case (nil, .some): return false
            default: return lhs.offset < rhs.offset
            }
        }
        .map(\.element)
    }
}
