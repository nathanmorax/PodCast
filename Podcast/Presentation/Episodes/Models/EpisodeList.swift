//
//  EpisodeList.swift
//  Podcast
//

import Foundation

/// Which episodes a podcast's page lists.
enum EpisodeFilter: CaseIterable, Hashable {
    case all
    /// Not finished yet (never played, or left halfway).
    case unplayed
    /// On the phone.
    case downloaded

    var title: LocalizedStringResource {
        switch self {
        case .all: "All"
        case .unplayed: "Unplayed"
        case .downloaded: "Downloaded"
        }
    }
}

/// In which order.
enum EpisodeOrder: CaseIterable, Hashable {
    case newest
    case oldest

    var title: LocalizedStringResource {
        switch self {
        case .newest: "Newest first"
        case .oldest: "Oldest first"
        }
    }
}

/// The podcast page's list: filtered and ordered. Pure, so it's tested.
enum EpisodeList {

    /// - Parameters:
    ///   - finished: stream URLs of the episodes played to the end.
    ///   - downloaded: stream URLs of the episodes on the phone.
    /// Equal dates keep the feed's order.
    static func apply(
        _ episodes: [Episode],
        filter: EpisodeFilter,
        order: EpisodeOrder,
        finished: Set<String>,
        downloaded: Set<String>
    ) -> [Episode] {
        let kept = episodes.enumerated().filter { _, episode in
            switch filter {
            case .all: true
            case .unplayed: !finished.contains(episode.streamUrl)
            case .downloaded: downloaded.contains(episode.streamUrl)
            }
        }
        return kept.sorted { lhs, rhs in
            if lhs.element.pubDate != rhs.element.pubDate {
                return order == .newest
                    ? lhs.element.pubDate > rhs.element.pubDate
                    : lhs.element.pubDate < rhs.element.pubDate
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
    }
}
