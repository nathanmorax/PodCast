//
//  HomeFeed.swift
//  Podcast
//

import Foundation

/// One card in Home's feed.
enum HomeFeedItem: Identifiable {
    /// The big card on top: today's pick.
    case episodeOfTheDay(PodcastEpisode)
    /// An episode card, with an optional label on it (NEW, SHORT LISTEN…).
    case episode(PodcastEpisode, tag: FeedTag?)
    /// The mustard card: the last episode started and not finished.
    case continueListening(RecentlyPlayed)
    /// A show you don't follow yet, with a line from it and Follow.
    case showSpotlight(PodcastEpisode)

    var id: String {
        switch self {
        case .episodeOfTheDay(let item): "day-\(item.id)"
        case .episode(let item, _): "episode-\(item.id)"
        case .continueListening(let item): "continue-\(item.id)"
        case .showSpotlight(let item): "show-\(item.podcast.trackId)"
        }
    }
}

/// The small white label on an episode card.
enum FeedTag: Equatable {
    /// Published since the Library was last opened.
    case new
    /// Shorter than `HomeFeed.shortListen`.
    case shortListen
    /// From your interests (a show you don't follow).
    case forYou

    var title: LocalizedStringResource {
        switch self {
        case .new: "New"
        case .shortListen: "Short listen"
        case .forYou: "For you"
        }
    }
}

/// Builds Home's feed: one vertical column of cards, like a film
/// magazine, mixing what you follow and what's picked for you, so nothing
/// shows twice. Pure, so it's tested.
///
/// The order: Episode of the day · a new episode · Continue listening ·
/// two more new ones · a show to follow · then new episodes and picks
/// taking turns.
enum HomeFeed {

    /// Below this, an episode is a "short listen".
    static let shortListen: TimeInterval = 20 * 60
    /// At most this many new episodes (the rest: Library › New).
    static let newLimit = 6
    /// At most this many picks.
    static let pickLimit = 6

    static func build(
        newEpisodes: [PodcastEpisode],
        newSince: Date,
        picks: [PodcastEpisode],
        unfinished: [RecentlyPlayed]
    ) -> [HomeFeedItem] {
        var used = Set<String>()
        var feed: [HomeFeedItem] = []

        let resume = unfinished.first
        if let resume { used.insert(resume.id) }

        var news = newEpisodes.filter { !used.contains($0.id) }.prefix(newLimit).map { $0 }
        var picks = picks.filter { !used.contains($0.id) }.prefix(pickLimit).map { $0 }

        // 1. Episode of the day: today's pick, or the newest episode.
        if let hero = picks.first ?? news.first {
            feed.append(.episodeOfTheDay(hero))
            used.insert(hero.id)
            news.removeAll { $0.id == hero.id }
            picks.removeAll { $0.id == hero.id }
        }

        // A show to follow: the next pick's show (its episode is the quote).
        let spotlight = picks.first
        if let spotlight { picks.removeFirst(); used.insert(spotlight.id) }

        func card(_ item: PodcastEpisode, isPick: Bool) -> HomeFeedItem {
            .episode(item, tag: tag(for: item, isPick: isPick, newSince: newSince))
        }
        var newCards = news.map { card($0, isPick: false) }[...]
        var pickCards = picks.map { card($0, isPick: true) }[...]

        if let first = newCards.popFirst() { feed.append(first) }
        if let resume { feed.append(.continueListening(resume)) }
        feed.append(contentsOf: newCards.prefix(2))
        newCards = newCards.dropFirst(2)
        if let spotlight { feed.append(.showSpotlight(spotlight)) }

        // The rest: one of each, taking turns.
        while !newCards.isEmpty || !pickCards.isEmpty {
            if let next = newCards.popFirst() { feed.append(next) }
            if let next = pickCards.popFirst() { feed.append(next) }
        }
        return feed
    }

    /// NEW when it came out since the Library was last opened; else SHORT
    /// LISTEN when it's short; else FOR YOU for picks; none otherwise.
    static func tag(for item: PodcastEpisode, isPick: Bool, newSince: Date) -> FeedTag? {
        if !isPick, item.episode.pubDate > newSince { return .new }
        if let seconds = item.episode.durationSeconds, seconds > 0, seconds < shortListen { return .shortListen }
        return isPick ? .forYou : nil
    }

    /// Started and not finished, last played first.
    static func unfinished(_ items: [RecentlyPlayed]) -> [RecentlyPlayed] {
        items
            .filter { $0.progress < RecentlyPlayed.finishedThreshold }
            .sorted { $0.lastPlayedAt > $1.lastPlayedAt }
    }
}
