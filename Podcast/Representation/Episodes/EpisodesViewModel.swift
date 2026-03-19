//
//  EpisodesViewModel 2.swift
//  Podcast
//
//  Created by Satori Tech 341 on 19/03/26.
//


class EpisodesViewModel {
    
    private let repository: SearchPodcastRepository
    private let favoritesManager: FavoritesPodcastManager
    
    private(set) var episodes: [Episode] = []
    
    var onDataUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Init
    init(repository: SearchPodcastRepository,
         favoritesManager: FavoritesPodcastManager = FavoritesPodcastManager()) {
        self.repository = repository
        self.favoritesManager = favoritesManager
    }
    
    // MARK: - Episodes
    func loadEpisodes(feedURL: String) {
        repository.fetchEpisodes(feedURL: feedURL) { [weak self] result in
            switch result {
            case .success(let episodes):
                self?.episodes = episodes
                self?.onDataUpdated?()
            case .failure(let error):
                self?.onError?(error)
            }
        }
    }
    
    func toggleFavorite(podcast: Podcast) {
        favoritesManager.toggleFavorite(podcast)
//        onDataUpdated?()
    }
    
    func fecthFavorites() -> [Podcast] {
        favoritesManager.fetchFavoritePodcasts()
    }
    
    func isFavorite(_ podcast: Podcast) -> Bool {
        return favoritesManager.isFavorite(podcast)
    }
}
