//
//  ForYouViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// "For you" in Library: the latest episodes of the podcasts you follow,
/// newest first, in one row.
///
/// Each followed podcast's RSS is read once and kept in memory, so going
/// back to Library (or following one more) only downloads what's missing.
@MainActor
@Observable
final class ForYouViewModel {

    struct Item: Identifiable, Sendable {
        let podcast: Podcast
        let episode: Episode
        var id: String { episode.streamUrl }
    }

    /// How many episodes Library shows.
    static let shownCount = 10
    /// At most this many from one podcast, so a daily show doesn't fill the row.
    static let perPodcast = 2

    private(set) var items: [Item] = []
    private(set) var isLoading = false

    @ObservationIgnored private let repository: any SearchPodcastRepository
    /// Episodes per podcast (trackId), newest first.
    @ObservationIgnored private var episodesByPodcast: [Int: [Episode]] = [:]
    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    func load(following: [Podcast]) {
        loadTask?.cancel()
        // What's cached shows right away.
        items = Self.latest(from: following, episodes: episodesByPodcast)

        let missing = following.filter { episodesByPodcast[$0.trackId] == nil && $0.feedUrl != nil }
        guard !missing.isEmpty else {
            isLoading = false
            return
        }

        isLoading = true
        let repository = self.repository
        loadTask = Task {
            // All feeds at once; a failed one just adds nothing.
            let fetched = await withTaskGroup(of: (Int, [Episode]?).self) { group in
                for podcast in missing {
                    guard let feedURL = podcast.feedUrl else { continue }
                    group.addTask {
                        let feed = try? await repository.fetchFeed(feedURL: feedURL)
                        return (podcast.trackId, feed?.episodes.sorted { $0.pubDate > $1.pubDate })
                    }
                }
                var results: [Int: [Episode]] = [:]
                for await (id, episodes) in group {
                    if let episodes { results[id] = episodes }
                }
                return results
            }
            guard !Task.isCancelled else { return }
            episodesByPodcast.merge(fetched) { _, new in new }
            items = Self.latest(from: following, episodes: episodesByPodcast)
            isLoading = false
        }
    }

    /// Pure: the newest episodes across these podcasts (at most `perPodcast`
    /// each, `shownCount` in all), newest first.
    static func latest(from podcasts: [Podcast], episodes: [Int: [Episode]]) -> [Item] {
        let all = podcasts.flatMap { podcast in
            (episodes[podcast.trackId] ?? [])
                .sorted { $0.pubDate > $1.pubDate }
                .prefix(perPodcast)
                .map { Item(podcast: podcast, episode: $0) }
        }
        return Array(all.sorted { $0.episode.pubDate > $1.episode.pubDate }.prefix(shownCount))
    }
}
