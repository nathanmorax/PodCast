//
//  LibraryTab.swift
//  Podcast
//

import Foundation

/// The Library's tabs, and what each one lists. Pure, so it's tested.
enum LibraryTab: Hashable, CaseIterable, Identifiable {
    /// Recent episodes of the shows you follow (what the Inbox was).
    case new
    /// Episodes you saved (bookmarked).
    case saved
    /// Episodes on the phone, playable offline.
    case downloads
    /// Everything you played, the last one first (finished ones too: Home's
    /// "Continue listening" only keeps the unfinished).
    case history

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .new: "New"
        case .saved: "Saved"
        case .downloads: "Downloads"
        case .history: "History"
        }
    }
}

/// One episode in the Library: the episode and the show it's from, when
/// known (saved and downloaded ones only carry the author).
struct LibraryItem: Identifiable, Equatable {
    let episode: Episode
    /// The show's name, or the episode's author.
    let showName: String
    /// The episode's artwork, or its show's.
    let artwork: String?

    var id: String { episode.streamUrl }

    static func == (lhs: LibraryItem, rhs: LibraryItem) -> Bool { lhs.id == rhs.id }

    init(episode: Episode, podcast: Podcast? = nil) {
        self.episode = episode
        self.showName = podcast?.trackName ?? episode.author
        if let image = episode.imageUrl, !image.isEmpty {
            self.artwork = image
        } else {
            self.artwork = podcast?.artworkUrl600
        }
    }
}

extension LibraryTab {

    /// What this tab lists. `new` comes with its shows (InboxFeed); the
    /// others are bare episodes (their author stands for the show).
    func items(
        new: [PodcastEpisode],
        saved: [Episode],
        downloads: [Episode],
        history: [RecentlyPlayed]
    ) -> [LibraryItem] {
        switch self {
        case .new:
            return new.map { LibraryItem(episode: $0.episode, podcast: $0.podcast) }
        case .saved:
            return saved.sorted { $0.pubDate > $1.pubDate }.map { LibraryItem(episode: $0) }
        case .downloads:
            return downloads.sorted { $0.pubDate > $1.pubDate }.map { LibraryItem(episode: $0) }
        case .history:
            return history.sorted { $0.lastPlayedAt > $1.lastPlayedAt }.map { LibraryItem(episode: $0.episode) }
        }
    }
}
