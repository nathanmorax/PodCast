//
//  EpisodesViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import Combine
import Foundation
import FeedKit
import Observation

@Observable
@MainActor
class EpisodesViewModel {
    
    private(set) var favorites: [Podcast] = []
    private(set) var episodes: [Episode] = []
    private(set) var errorMessage: String?
    
    private(set) var podcastDescription: String?
    private(set) var isLoadingDescription = false
    private(set) var isLoadingEpisodes = false
    
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
    
    private var loadEpisodesTask: Task<Void, Never>?
    private var loadDescriptionTask: Task<Void, Never>?
    
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favorites in
                self?.favorites = favorites
            }
            .store(in: &cancellables)
    }
    
    func toggleFavorite(podcast: Podcast) {
        favoritesManager.toggleFavorite(podcast)
    }
    
    func isFavorite(_ podcast: Podcast) -> Bool {
        return favoritesManager.isFavorite(podcast)
    }
    
    // MARK: - Episodes
    
    func loadEpisodes(feedURL: String) {
        
        loadEpisodesTask?.cancel()
        isLoadingEpisodes = true
        
        Task {
            do {
                let episodes = try await withTimeout(seconds: 15) {
                    try await self.repository.fetchEpisodes(feedURL: feedURL)
                }
                
                guard !Task.isCancelled else { return }

                
                await MainActor.run {
                    self.allEpisodes = episodes
                    self.currentPage = 0
                    self.loadMoreEpisodes()
                    self.isLoadingEpisodes = false
                }
            } catch {
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingEpisodes = false
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
        
        self.episodes.append(contentsOf: newEpisodes)
        self.currentPage += 1
        self.isLoadingMore = false
        
    }
    
    // MARK: - Podcast Description
    /// Carga la descripción del podcast desde el feed RSS.
    /// Se llama desde el controller cuando se setea el podcast.
    func loadPodcastDescription(feedURL: String?) {
            // Cancela cualquier carga anterior
            loadDescriptionTask?.cancel()
            
            guard let feedURL else { return }
            guard podcastDescription == nil, !isLoadingDescription else { return }
            
            let secureFeedUrl = feedURL.contains("https")
                ? feedURL
                : feedURL.replacingOccurrences(of: "http", with: "https")
            
            guard let url = URL(string: secureFeedUrl) else { return }
            
            isLoadingDescription = true
            
            loadDescriptionTask = Task { [weak self] in
                guard let self else { return }
                
                do {
                    let feed = try await withTimeout(seconds: 15) {
                        try await Feed(url: url)
                    }
                    
                    guard !Task.isCancelled else { return }
                    
                    switch feed {
                    case .rss(let rssFeed):
                        let desc = rssFeed.toPodcastDescription()
                        self.podcastDescription = desc
                        self.isLoadingDescription = false
                        
                    case .atom, .json:
                        self.isLoadingDescription = false
                    }
                    
                } catch {
                    guard !Task.isCancelled else { return }
                    
                    self.isLoadingDescription = false
                    print("❌ Error loading description:", error)
                }
            }
        }
    
//    deinit {
//        loadEpisodesTask?.cancel()
//        loadDescriptionTask?.cancel()
//    }
}

