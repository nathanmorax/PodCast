//
//  InboxFeed.swift
//  Podcast
//

import Foundation

/// What the Inbox lists: every recent episode of the podcasts you follow,
/// newest first. Pure: it reads the episodes FollowingFeedViewModel already
/// downloaded.
enum InboxFeed {

    /// How far back the Inbox goes.
    static let window: TimeInterval = 30 * 24 * 60 * 60
    /// At most this many episodes in all.
    static let limit = 100

    static func items(following podcasts: [Podcast],
                      episodes: [Int: [Episode]],
                      now: Date = .now) -> [PodcastEpisode] {
        let oldest = now.addingTimeInterval(-window)
        let all = podcasts.flatMap { podcast in
            (episodes[podcast.trackId] ?? [])
                .filter { $0.pubDate >= oldest && $0.pubDate <= now }
                .map { PodcastEpisode(podcast: podcast, episode: $0) }
        }
        return Array(all.sorted { $0.episode.pubDate > $1.episode.pubDate }.prefix(limit))
    }

    /// The ones published after the Inbox was last opened.
    static func newCount(in items: [PodcastEpisode], since lastSeen: Date) -> Int {
        items.lazy.filter { $0.episode.pubDate > lastSeen }.count
    }
}
