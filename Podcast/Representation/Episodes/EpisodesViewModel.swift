//
//  EpisodesViewModel 2.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//
import Combine
import Foundation

class EpisodesViewModel {
    
    @Published private(set) var favorites: [Podcast] = []
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var errorMessage: String?
    
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
    
    // MARK: - Episodes
    
    private func bindFavorites() {
        favoritesManager.favoritesPublisher
            .assign(to: &$favorites)
    }
    
    func toggleFavorite(podcast: Podcast) {
        favoritesManager.toggleFavorite(podcast)
    }
    
//    func fecthFavorites() -> [Podcast] {
//        favoritesManager.fetchFavoritePodcasts()
//    }
    
    func isFavorite(_ podcast: Podcast) -> Bool {
        return favoritesManager.isFavorite(podcast)
    }
    
//    func loadEpisodes(feedURL: String) {
//        repository.fetchEpisodesPublisher(feedURL: feedURL)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                if case .failure(let error) = completion {
//                    self?.errorMessage = error.localizedDescription
//                }
//            } receiveValue: { [weak self] episodes in
//                self?.episodes = episodes
//            }
//            .store(in: &cancellables)
//    }
    
    func loadEpisodes(feedURL: String) {
        Task {
            do {
                let episodes = try await repository.fetchEpisodes(feedURL: feedURL)
                await MainActor.run {
                    
                    self.episodes = episodes
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
