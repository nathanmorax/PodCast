//
//  EpisodeDetailViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// What the episode page needs besides the episode itself: its chapters
/// (from the show notes) and the show's other episodes (one read of its
/// feed, only when the show is known).
@MainActor
@Observable
final class EpisodeDetailViewModel {

    let episode: Episode
    /// The show, when the screen that opened it knew it (nil: no "From the
    /// show" nor "More from…").
    let podcast: Podcast?
    let chapters: [EpisodeChapter]

    /// The show's latest episodes, this one left out.
    private(set) var moreEpisodes: [Episode] = []

    /// How many "More from…" lists.
    static let moreLimit = 5

    @ObservationIgnored private let repository: any SearchPodcastRepository

    init(episode: Episode,
         podcast: Podcast?,
         repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.episode = episode
        self.podcast = podcast
        self.repository = repository
        self.chapters = EpisodeChapter.parse(showNotes: episode.chapterSource)
    }

    /// The first sentence of the notes ("Why listen") and the rest.
    var notes: EpisodeNotes {
        let full = episode.showNotes ?? ""
        return EpisodeNotes(full.isEmpty ? episode.description : full)
    }

    func loadMoreEpisodes() async {
        guard moreEpisodes.isEmpty, let feedURL = podcast?.feedUrl else { return }
        guard let feed = try? await repository.fetchFeed(feedURL: feedURL) else { return }
        moreEpisodes = Self.more(from: feed.episodes, excluding: episode)
    }

    /// Pure: the newest episodes but this one.
    static func more(from episodes: [Episode], excluding current: Episode) -> [Episode] {
        Array(
            episodes
                .filter { $0.streamUrl != current.streamUrl }
                .sorted { $0.pubDate > $1.pubDate }
                .prefix(moreLimit)
        )
    }
}
