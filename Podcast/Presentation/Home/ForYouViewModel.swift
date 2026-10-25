//
//  ForYouViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// "For you · Based on your interests": the newest episode of podcasts you
/// DON'T follow yet, from the categories you chose. Discovery: what you
/// follow already has the Inbox, and what you started has Recently played,
/// so nothing here repeats them.
///
/// For each interest, the top shows of that category (the same search the
/// category page uses), skipping the ones you follow; then each one's
/// newest episode. Loaded once per set of interests while Library lives.
@MainActor
@Observable
final class ForYouViewModel {

    /// Shows taken from each category.
    static let perGenre = 2
    /// Categories used (the first interests).
    static let maxGenres = 4
    /// With no interests chosen: the catalog's first categories.
    static let fallbackGenres = 3

    private(set) var items: [PodcastEpisode] = []
    private(set) var isLoading = false

    @ObservationIgnored private let repository: any SearchPodcastRepository
    /// What the current items were made for (interests + followed).
    @ObservationIgnored private var loadedKey: String?
    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    /// What's shown: following one of them takes it out right away (it's in
    /// the Inbox from then on).
    func visibleItems(excluding followed: Set<Int>) -> [PodcastEpisode] {
        items.filter { !followed.contains($0.podcast.trackId) }
    }

    func load(interests: [Genre], following: [Podcast]) {
        let genres = Array((interests.isEmpty
            ? Array(Genre.podcastCatalog.prefix(Self.fallbackGenres))
            : interests).prefix(Self.maxGenres))
        let followed = Set(following.map(\.trackId))
        let key = genres.map(\.id).joined(separator: ",")
        // Same interests: keep what's there (a new follow is filtered out
        // by visibleItems, no new download).
        guard key != loadedKey || (items.isEmpty && !isLoading) else { return }
        loadedKey = key

        loadTask?.cancel()
        isLoading = true
        let repository = self.repository
        loadTask = Task {
            // 1. Each category's top shows, all at once.
            let rankings = await withTaskGroup(of: (Int, [Podcast]).self) { group in
                for (index, genre) in genres.enumerated() {
                    group.addTask {
                        (index, (try? await repository.searchPodcast(query: genre.name)) ?? [])
                    }
                }
                var results: [[Podcast]] = Array(repeating: [], count: genres.count)
                for await (index, podcasts) in group { results[index] = podcasts }
                return results
            }
            guard !Task.isCancelled else { return }
            let picked = Self.pick(from: rankings, excluding: followed, perGenre: Self.perGenre)

            // 2. Each picked show's newest episode, all at once.
            let newest = await withTaskGroup(of: (Int, Episode?).self) { group in
                for podcast in picked {
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
            // In the picked order: categories take turns.
            items = picked.compactMap { podcast in
                newest[podcast.trackId].map { PodcastEpisode(podcast: podcast, episode: $0) }
            }
            isLoading = false
        }
    }

    /// Pure: from each category's ranking, the first `perGenre` shows you
    /// don't follow and that no other category took; categories take turns
    /// (1st of each, then 2nd of each…), so one doesn't fill the row.
    static func pick(from rankings: [[Podcast]], excluding followed: Set<Int>, perGenre: Int) -> [Podcast] {
        var taken = followed
        let candidates: [[Podcast]] = rankings.map { ranking in
            var mine: [Podcast] = []
            for podcast in ranking where mine.count < perGenre
                && podcast.feedUrl != nil
                && !taken.contains(podcast.trackId) {
                mine.append(podcast)
                taken.insert(podcast.trackId)
            }
            return mine
        }
        var result: [Podcast] = []
        for round in 0..<perGenre {
            for list in candidates where round < list.count {
                result.append(list[round])
            }
        }
        return result
    }
}
