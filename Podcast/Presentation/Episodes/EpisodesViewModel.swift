//
//  EpisodesViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class EpisodesViewModel {

    private(set) var episodes: [Episode] = []
    private(set) var errorMessage: String?

    private(set) var podcastDescription: String?
    private(set) var isLoadingDescription = false
    private(set) var isLoadingEpisodes = false

    /// Which episodes, in which order (the controls over the list).
    private(set) var filter: EpisodeFilter = .all
    private(set) var order: EpisodeOrder = .newest
    /// How often the show publishes, from its episodes' dates.
    private(set) var cadence: ShowCadence?

    /// Read through to the manager, so observers of `favorites` here see its
    /// changes (Observation tracks the nested read).
    var favorites: [Podcast] { favoritesManager.favorites }

    @ObservationIgnored private var allEpisodes: [Episode] = []
    /// `allEpisodes` filtered and ordered: what the pages come from.
    @ObservationIgnored private var listed: [Episode] = []
    @ObservationIgnored private var currentPage = 0
    @ObservationIgnored private let pageSize = 20
    @ObservationIgnored private var isLoadingMore = false

    private var hasMorePages: Bool {
        episodes.count < listed.count
    }

    @ObservationIgnored private let repository: SearchPodcastRepository
    @ObservationIgnored private let favoritesManager: FavoritesPodcastManager
    @ObservationIgnored private let recentlyPlayed: RecentlyPlayedManager
    @ObservationIgnored private let downloads: DownloadManager

    /// Internal read access so tests can `await viewModel.loadEpisodesTask?.value`.
    @ObservationIgnored private(set) var loadEpisodesTask: Task<Void, Never>?

    // MARK: - Init

    init(repository: SearchPodcastRepository,
         favoritesManager: FavoritesPodcastManager = .shared,
         recentlyPlayed: RecentlyPlayedManager = .shared,
         downloads: DownloadManager = .shared) {
        self.repository = repository
        self.favoritesManager = favoritesManager
        self.recentlyPlayed = recentlyPlayed
        self.downloads = downloads
    }

    // MARK: - Continue

    /// The last episode of this show started and not finished: the mustard
    /// strip over the list.
    var inProgress: RecentlyPlayed? {
        let urls = Set(allEpisodesSnapshot)
        return recentlyPlayed.items
            .filter { $0.progress < RecentlyPlayed.finishedThreshold && urls.contains($0.id) }
            .max { $0.lastPlayedAt < $1.lastPlayedAt }
    }

    /// The feed's stream URLs, observable (set with each load).
    private var allEpisodesSnapshot: [String] = []

    // MARK: - Filter and order

    func setFilter(_ filter: EpisodeFilter) {
        guard filter != self.filter else { return }
        self.filter = filter
        rebuildList()
    }

    func setOrder(_ order: EpisodeOrder) {
        guard order != self.order else { return }
        self.order = order
        rebuildList()
    }

    /// Filters and orders again, from the first page.
    private func rebuildList() {
        let finished = Set(recentlyPlayed.items
            .filter { $0.progress >= RecentlyPlayed.finishedThreshold }
            .map(\.id))
        let downloaded = Set(downloads.downloadedEpisodes.map(\.streamUrl))
        listed = EpisodeList.apply(allEpisodes, filter: filter, order: order,
                                   finished: finished, downloaded: downloaded)
        episodes = []
        currentPage = 0
        loadMoreEpisodes()
    }

    // MARK: - Favorites

    func toggleFavorite(podcast: Podcast) {
        favoritesManager.toggleFavorite(podcast)
    }

    func isFavorite(_ podcast: Podcast) -> Bool {
        favoritesManager.isFavorite(podcast)
    }

    // MARK: - Feed (episodes + description, one download)

    func loadEpisodes(feedURL: String) {
        loadEpisodesTask?.cancel()
        isLoadingEpisodes = true
        isLoadingDescription = podcastDescription == nil
        errorMessage = nil

        // Captured as a value: the timeout closure runs off the main actor and
        // must not reach back into `self` (Swift 6 data-race safety).
        let repository = self.repository

        // The Task inherits @MainActor from this class: the state updates
        // below need no MainActor.run.
        loadEpisodesTask = Task {
            do {
                let feed = try await withTimeout(seconds: 15) {
                    try await repository.fetchFeed(feedURL: feedURL)
                }

                guard !Task.isCancelled else { return }

                self.podcastDescription = feed.description ?? self.podcastDescription
                self.allEpisodes = feed.episodes
                self.allEpisodesSnapshot = feed.episodes.map(\.streamUrl)
                self.cadence = ShowCadence(dates: feed.episodes.map(\.pubDate))
                // A reload replaces the list (never appends to the old one).
                self.rebuildList()
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = error.localizedDescription
            }
            self.isLoadingEpisodes = false
            self.isLoadingDescription = false
        }
    }

    func loadMoreEpisodes() {
        guard !isLoadingMore, hasMorePages else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, listed.count)
        guard startIndex < endIndex else { return }

        episodes.append(contentsOf: listed[startIndex..<endIndex])
        currentPage += 1
    }
}
