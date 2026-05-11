//
//  EpisodesViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import Combine
import Foundation
import FeedKit

class EpisodesViewModel {
    
    @Published private(set) var favorites: [Podcast] = []
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    
    @Published private(set) var podcastDescription: String?
    @Published private(set) var isLoadingDescription = false
    
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
                    self.episodes = episodes
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Podcast Description
    
    /// Carga la descripción del podcast desde el feed RSS.
    /// Se llama desde el controller cuando se setea el podcast.
    func loadPodcastDescription(feedURL: String?) {
        guard let feedURL else { return }
        
        // Evita recargar si ya tenemos descripción
        guard podcastDescription == nil, !isLoadingDescription else { return }
        
        let secureFeedUrl = feedURL.contains("https")
            ? feedURL
            : feedURL.replacingOccurrences(of: "http", with: "https")
        
        guard let url = URL(string: secureFeedUrl) else { return }
        
        isLoadingDescription = true
        
        Task.detached(priority: .background) { [weak self] in
            do {
                let feed = try await Feed(url: url)
                
                switch feed {
                case .rss(let rssFeed):
                    let desc = rssFeed.toPodcastDescription()
                    await MainActor.run {
                        self?.podcastDescription = desc
                        self?.isLoadingDescription = false
                    }
                case .atom, .json:
                    await MainActor.run {
                        self?.isLoadingDescription = false
                    }
                }
            } catch {
                await MainActor.run {
                    self?.isLoadingDescription = false
                    print("❌ Error loading description:", error)
                }
            }
        }
    }
}
