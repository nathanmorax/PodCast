//
//  FollowingFeedViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// The episodes of the podcasts you follow: what the Inbox lists (and
/// counts for its badge).
///
/// What was read last time is saved (FollowingFeedCache) and is there at
/// once, even right after the app was closed; meanwhile each followed
/// podcast's RSS is read again, once per launch. Following one more only
/// downloads what's missing.
@MainActor
@Observable
final class FollowingFeedViewModel {

    /// Episodes per podcast (trackId), newest first.
    private(set) var episodesByPodcast: [Int: [Episode]] = [:]
    private(set) var isLoading = false

    @ObservationIgnored private let repository: any SearchPodcastRepository
    /// Podcasts whose feed was read in this launch (the rest come from the
    /// saved copy and get refreshed).
    @ObservationIgnored private var refreshed: Set<Int> = []
    @ObservationIgnored private let cache: FollowingFeedCache?
    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    /// - Parameter cache: where the episodes are saved between launches.
    ///   Nil (tests): memory only.
    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService()),
         cache: FollowingFeedCache? = nil) {
        self.repository = repository
        self.cache = cache
        self.episodesByPodcast = cache?.load() ?? [:]
    }

    func load(following: [Podcast]) {
        loadTask?.cancel()
        // Unfollowed ones leave right away.
        let followed = Set(following.map(\.trackId))
        episodesByPodcast = episodesByPodcast.filter { followed.contains($0.key) }

        // Not read yet in this launch: new follows, and what came from the
        // saved copy (shown already, refreshed quietly).
        let missing = following.filter { !refreshed.contains($0.trackId) && $0.feedUrl != nil }
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
            // Failed ones stay as saved and are tried again next time.
            refreshed.formUnion(fetched.keys)
            isLoading = false
            cache?.save(episodesByPodcast)
        }
    }
}
