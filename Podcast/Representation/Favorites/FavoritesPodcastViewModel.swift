//
//  FavoritesPodcastViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 20/03/26.
//
import Combine
import Observation

class FavoritesViewModel {
    
    @Published private(set) var favorites: [Podcast] = []
    
    private let favoritesManager: FavoritesPodcastManager
    private var cancellables = Set<AnyCancellable>()
    
    init(favoritesManager: FavoritesPodcastManager = .shared) {
        self.favoritesManager = favoritesManager
        favoritesManager.favoritesPublisher
            .assign(to: &$favorites)
    }
    
    func remove(_ podcast: Podcast) {
        favoritesManager.deleteFavorite(podcast)
    }
}
