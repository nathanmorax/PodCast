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

@Observable
class BookMarkEpisodeViewModel {
    
    private let bookmarkManager: BookMarkEpisodeManager
    private let playerManager: PlayerManager
    
    var episodes: [Episode] { bookmarkManager.episodes }
    
    init(
        bookmarkManagerEpisode: BookMarkEpisodeManager = .shared,
        playerManager: PlayerManager = .shared
    ) {
        self.bookmarkManager = bookmarkManagerEpisode
        self.playerManager = playerManager
    }
    
    func remove(_ episode: Episode) {
        bookmarkManager.delete(episode)
    }
    
    func playOrToggle(_ episode: Episode, presentation: PlayerManager.PlayerPresentation = .mini) {
        playerManager.playOrToggle(episode, presentation: presentation)
    }
    
    func isPlaying(_ episode: Episode) -> Bool {
        playerManager.currentEpisode?.streamUrl == episode.streamUrl &&
        playerManager.viewModel.isPlaying
    }
}
