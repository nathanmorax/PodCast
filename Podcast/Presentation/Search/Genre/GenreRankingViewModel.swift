//
//  GenreRankingViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// A category's ranking. For now it searches the category's name (the first
/// results are the top ones); when the API gives us each category's chart,
/// only `load()` changes.
@MainActor
@Observable
final class GenreRankingViewModel {

    let genre: Genre

    private(set) var podcasts: [Podcast] = []
    private(set) var isLoading = false
    private(set) var error: String?
    /// The podcast whose newest episode is being fetched to play.
    private(set) var preparingPodcastID: Int?

    @ObservationIgnored private let repository: any SearchPodcastRepository
    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    init(genre: Genre,
         repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.genre = genre
        self.repository = repository
    }

    func load() {
        guard !isLoading, podcasts.isEmpty else { return }
        isLoading = true
        error = nil
        let repository = repository
        let query = genre.name
        loadTask = Task {
            defer { isLoading = false }
            do {
                podcasts = try await repository.searchPodcast(query: query)
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
        }
    }

    /// "Listen" on the #1: its newest episode (one download of its feed).
    func newestEpisode(of podcast: Podcast) async -> Episode? {
        guard let feedURL = podcast.feedUrl else { return nil }
        preparingPodcastID = podcast.trackId
        defer { preparingPodcastID = nil }
        let feed = try? await repository.fetchFeed(feedURL: feedURL)
        return feed?.episodes.max { $0.pubDate < $1.pubDate }
    }
}
