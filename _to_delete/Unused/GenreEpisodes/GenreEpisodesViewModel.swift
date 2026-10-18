//
//  GenreEpisodesViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// Search's genre pages: the top episodes of each genre — the newest
/// episode of each of the genre's top podcasts, in the podcasts' order.
///
/// A genre loads the first time its page shows, and stays in memory while
/// Search lives (swiping back doesn't download again). For now the top
/// podcasts come from searching the genre's name; when we use a "top by
/// genre" API, only that call changes.
@MainActor
@Observable
final class GenreEpisodesViewModel {

    struct Item: Identifiable, Sendable {
        let podcast: Podcast
        let episode: Episode
        var id: String { episode.streamUrl }
    }

    /// Top podcasts read per genre (one RSS each).
    static let podcastsPerGenre = 8

    private(set) var items: [String: [Item]] = [:]
    private(set) var loading: Set<String> = []
    private(set) var failed: Set<String> = []

    @ObservationIgnored private let repository: any SearchPodcastRepository

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    func items(for genre: Genre) -> [Item] { items[genre.id] ?? [] }
    func isLoading(_ genre: Genre) -> Bool { loading.contains(genre.id) }
    func hasFailed(_ genre: Genre) -> Bool { failed.contains(genre.id) }

    /// Loads a genre once. Called from its page's `.task`: if the page goes
    /// away before it finishes, nothing is saved and it loads next time.
    func load(_ genre: Genre) async {
        guard items[genre.id] == nil, !loading.contains(genre.id) else { return }
        loading.insert(genre.id)
        failed.remove(genre.id)
        defer { loading.remove(genre.id) }

        let repository = self.repository
        guard let found = try? await repository.searchPodcast(query: genre.name) else {
            if !Task.isCancelled { failed.insert(genre.id) }
            return
        }
        let top = Array(found.filter { $0.feedUrl != nil }.prefix(Self.podcastsPerGenre))

        // All feeds at once; a failed one just isn't shown.
        let newest = await withTaskGroup(of: (Int, Episode?).self) { group in
            for podcast in top {
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
        items[genre.id] = Self.rank(top, newest: newest)
    }

    /// Pure: one episode per podcast, in the podcasts' (ranking) order.
    static func rank(_ podcasts: [Podcast], newest: [Int: Episode]) -> [Item] {
        podcasts.compactMap { podcast in
            newest[podcast.trackId].map { Item(podcast: podcast, episode: $0) }
        }
    }
}
