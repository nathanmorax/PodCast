//
//  NewEpisodesViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// The pile at the top of Library: the newest episode of each podcast you
/// follow, when it's recent and you haven't started it. Newest first.
///
/// Each followed podcast's RSS is read once per session (in memory), so
/// coming back to Library, or starting an episode, doesn't download again.
@MainActor
@Observable
final class NewEpisodesViewModel {

    struct Item: Identifiable, Sendable {
        let podcast: Podcast
        let episode: Episode
        var id: Int { podcast.trackId }
    }

    /// How old an episode can be and still count as new.
    static let window: TimeInterval = 7 * 24 * 60 * 60
    static let maxItems = 10

    private(set) var items: [Item] = []
    private(set) var isLoading = false

    @ObservationIgnored private let repository: any SearchPodcastRepository
    /// Newest episode per podcast (trackId).
    @ObservationIgnored private var latest: [Int: Episode] = [:]
    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    /// `played`: stream URLs of episodes already started (recently played).
    func load(following: [Podcast], played: Set<String>, now: Date = .now) {
        loadTask?.cancel()
        // What's cached shows right away.
        items = Self.pick(following: following, latest: latest, played: played, now: now)

        let missing = following.filter { latest[$0.trackId] == nil && $0.feedUrl != nil }
        guard !missing.isEmpty else {
            isLoading = false
            return
        }

        isLoading = true
        let repository = self.repository
        loadTask = Task {
            // All feeds at once; a failed one just isn't in the pile.
            let fetched = await withTaskGroup(of: (Int, Episode?).self) { group in
                for podcast in missing {
                    guard let feedURL = podcast.feedUrl else { continue }
                    group.addTask {
                        let feed = try? await repository.fetchFeed(feedURL: feedURL)
                        return (podcast.trackId, feed?.episodes.max { $0.pubDate < $1.pubDate })
                    }
                }
                var results: [Int: Episode] = [:]
                for await (id, episode) in group {
                    if let episode { results[id] = episode }
                }
                return results
            }
            guard !Task.isCancelled else { return }
            latest.merge(fetched) { _, new in new }
            items = Self.pick(following: following, latest: latest, played: played, now: now)
            isLoading = false
        }
    }

    /// Pure: which episodes go in the pile, newest first.
    static func pick(following: [Podcast], latest: [Int: Episode], played: Set<String>, now: Date) -> [Item] {
        let items: [Item] = following.compactMap { podcast in
            guard let episode = latest[podcast.trackId],
                  now.timeIntervalSince(episode.pubDate) <= window,
                  !played.contains(episode.streamUrl) else { return nil }
            return Item(podcast: podcast, episode: episode)
        }
        return Array(items.sorted { $0.episode.pubDate > $1.episode.pubDate }.prefix(maxItems))
    }
}
