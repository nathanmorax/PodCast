//
//  FollowingShows.swift
//  Podcast
//

import Foundation

/// One show in Following: the show, its newest episode (when its feed has
/// loaded) and how many episodes are new.
struct FollowingShow: Identifiable {
    let podcast: Podcast
    let latest: Episode?
    let newCount: Int

    var id: Int { podcast.trackId }
}

/// Following's order. Pure, so it's tested.
enum FollowingShows {

    /// Shows with new episodes first, then by their newest episode (newest
    /// first), then the ones whose feed hasn't loaded, as followed.
    static func rows(
        podcasts: [Podcast],
        episodes: [Int: [Episode]],
        newEpisodes: [Int: [Episode]]
    ) -> [FollowingShow] {
        let shows = podcasts.map { podcast in
            FollowingShow(
                podcast: podcast,
                latest: episodes[podcast.trackId]?.max { $0.pubDate < $1.pubDate },
                newCount: newEpisodes[podcast.trackId]?.count ?? 0
            )
        }
        // enumerated + index: a stable sort (equal shows keep their order).
        return shows.enumerated().sorted { lhs, rhs in
            let (a, b) = (lhs.element, rhs.element)
            if (a.newCount > 0) != (b.newCount > 0) { return a.newCount > 0 }
            switch (a.latest?.pubDate, b.latest?.pubDate) {
            case let (x?, y?) where x != y: return x > y
            case (.some, nil): return true
            case (nil, .some): return false
            default: return lhs.offset < rhs.offset
            }
        }
        .map(\.element)
    }
}
