//
//  FavoritesPodcastViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 20/03/26.
//
import Combine
import Observation

class DownloadEpisodeViewModel {
    
    var episodes: [Episode] { downloadManager.downloadedEpisodes }

    private let downloadManager: DownloadManager
    private var cancellables = Set<AnyCancellable>()
    
    init(downloadManager: DownloadManager = .shared) {
        self.downloadManager = downloadManager
//        favoritesManager.favoritesPublisher
//            .assign(to: &$favorites)
    }
    
}
