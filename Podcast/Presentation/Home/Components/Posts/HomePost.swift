//
//  HomePost.swift
//  Podcast
//

import Foundation

/// Home's three tabs.
enum HomeTab: Hashable, CaseIterable, Identifiable {
    /// Episodes picked from your interests.
    case forYou
    /// New episodes from the shows you follow.
    case following
    /// What you started and didn't finish.
    case continueListening

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .forYou: "For You"
        case .following: "Following"
        case .continueListening: "Continue"
        }
    }
}

/// One post in Home's feed, like a social feed's: who it's from (the show,
/// its cover as the avatar, its category as a chip) and the episode in a
/// big rounded image.
struct HomePost: Identifiable {
    let episode: Episode
    /// The show, when known (not for half-listened ones).
    let podcast: Podcast?
    let showName: String
    let showArtwork: String?
    /// The episode's own artwork, or its show's.
    let artwork: String?
    /// Its category, in the app's language.
    let genre: String?
    /// How far along (0…1), for half-listened ones.
    let progress: Double?
    /// The card its image zooms out of.
    let section: ZoomID.Section

    var id: String { episode.streamUrl }
}

/// What each tab lists. Pure, so it's tested.
enum HomePosts {

    /// Each tab's length (the rest: Library).
    static let limit = 20

    /// For You and Following: episodes with their shows.
    static func posts(_ items: [PodcastEpisode]) -> [HomePost] {
        items.prefix(limit).map { item in
            HomePost(
                episode: item.episode,
                podcast: item.podcast,
                showName: item.showName,
                showArtwork: item.podcast.artworkUrl600,
                artwork: item.feedArtwork,
                genre: item.podcast.genreName,
                progress: nil,
                section: .feed
            )
        }
    }

    /// Continue: started and not finished, last played first.
    static func continuePosts(_ played: [RecentlyPlayed]) -> [HomePost] {
        unfinished(played).prefix(limit).map { item in
            HomePost(
                episode: item.episode,
                podcast: nil,
                showName: item.episode.author,
                showArtwork: item.artworkSource,
                artwork: item.artworkSource,
                genre: nil,
                progress: item.progress,
                section: .recentlyPlayed
            )
        }
    }

    static func unfinished(_ items: [RecentlyPlayed]) -> [RecentlyPlayed] {
        items
            .filter { $0.progress > 0 && $0.progress < RecentlyPlayed.finishedThreshold }
            .sorted { $0.lastPlayedAt > $1.lastPlayedAt }
    }
}

extension PodcastEpisode {

    /// The episode's own artwork, or its show's.
    var feedArtwork: String? {
        if let image = episode.imageUrl, !image.isEmpty { return image }
        return podcast.artworkUrl600
    }

    var showName: String { podcast.trackName ?? episode.author }
}
