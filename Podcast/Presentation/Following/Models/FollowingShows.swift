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

/// Following's order and its "Latest · Tue" labels. Pure, so it's tested.
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

    /// When an episode came out, short: "Today", "Yesterday", the weekday
    /// within the last week ("Tue"), otherwise the date ("Oct 14").
    static func whenLabel(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return String(localized: "Today")
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return String(localized: "Yesterday")
        }
        if let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)),
           date >= weekAgo, date <= now {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}
