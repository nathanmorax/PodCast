//
//  FavoritesPodcastViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 20/03/26.
//
import Combine
import Observation

class DownloadEpisodeViewModel {
    
    var episode: [Episode] { downloadManager.downloadedEpisodes }

    private let downloadManager: DownloadManager
    
    init(downloadManager: DownloadManager = .shared) {
        self.downloadManager = downloadManager
    }
    
}
