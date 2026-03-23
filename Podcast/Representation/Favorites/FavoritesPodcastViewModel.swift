//
//  FavoritesPodcastViewModel.swift
//  Podcast
//
//  Created by Satori Tech 341 on 20/03/26.
//
import Combine

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
