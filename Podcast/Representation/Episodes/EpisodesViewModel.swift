//
//  EpisodesViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import Combine
import Foundation
import FeedKit

@MainActor
class EpisodesViewModel {
    
    @Published private(set) var favorites: [Podcast] = []
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    
    @Published private(set) var podcastDescription: String?
    @Published private(set) var isLoadingDescription = false
    
    private var allEpisodes: [Episode] = []
    private var currentPage = 0
    private let pageSize = 20
    private var isLoadingMore = false
    
    private var hasMorePages: Bool {
        return episodes.count < allEpisodes.count
    }
    
    private let repository: SearchPodcastRepository
    private let favoritesManager: FavoritesPodcastManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(repository: SearchPodcastRepository,
         favoritesManager: FavoritesPodcastManager = .shared) {
        self.repository = repository
        self.favoritesManager = favoritesManager
        self.bindFavorites()
    }
    
    // MARK: - Favorites
    
    private func bindFavorites() {
        favoritesManager.favoritesPublisher
            .assign(to: &$favorites)
    }
    
    func toggleFavorite(podcast: Podcast) {
        favoritesManager.toggleFavorite(podcast)
    }
    
    func isFavorite(_ podcast: Podcast) -> Bool {
        return favoritesManager.isFavorite(podcast)
    }
    
    // MARK: - Episodes
    
    func loadEpisodes(feedURL: String) {
        Task {
            do {
                let episodes = try await repository.fetchEpisodes(feedURL: feedURL)
                await MainActor.run {
                    self.allEpisodes = episodes
                    self.currentPage = 0
                    self.episodes = []
                    self.loadMoreEpisodes()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadMoreEpisodes() {
        guard !isLoadingMore else { return }
        guard hasMorePages else { return }

        isLoadingMore = true

        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allEpisodes.count)

        guard startIndex < endIndex else {
            isLoadingMore = false
            return
        }

        let newEpisodes = Array(allEpisodes[startIndex..<endIndex])

        DispatchQueue.main.async {
            self.episodes.append(contentsOf: newEpisodes)
            self.currentPage += 1
            self.isLoadingMore = false
        }

    }
    
    // MARK: - Podcast Description
    /// Carga la descripción del podcast desde el feed RSS.
    /// Se llama desde el controller cuando se setea el podcast.
    func loadPodcastDescription(feedURL: String?) {
        guard let feedURL else { return }

        guard podcastDescription == nil, !isLoadingDescription else { return }

        let secureFeedUrl = feedURL.contains("https")
            ? feedURL
            : feedURL.replacingOccurrences(of: "http", with: "https")

        guard let url = URL(string: secureFeedUrl) else { return }

        isLoadingDescription = true

        Task { [weak self] in
            guard let self else { return }

            do {
                let feed = try await Feed(url: url)

                switch feed {
                case .rss(let rssFeed):
                    let desc = rssFeed.toPodcastDescription()
                    self.podcastDescription = desc
                    self.isLoadingDescription = false

                case .atom, .json:
                    self.isLoadingDescription = false
                }

            } catch {
                self.isLoadingDescription = false
                print("❌ Error loading description:", error)
            }
        }
    }
}
