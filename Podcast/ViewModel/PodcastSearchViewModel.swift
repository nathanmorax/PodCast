//
//  PodcastSearchViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//
import UIKit

class PodcastSearchViewModel {
    
    private let repository: PodcastRepository
    
    private(set) var podcasts: [Podcast] = []
    private(set) var episodes: [Episode] = []

    
    var onDataUpdated: (() -> Void)?
       var onError: ((String) -> Void)?
    
    init(repository: PodcastRepository) {
        self.repository = repository
    }
    
    
    func loadEpisodes(feedURL: String) {
        repository.fetchEpisodes(feedURL: feedURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let episodes):
                    self?.episodes = episodes
                    self?.onDataUpdated?()
                    print(episodes)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func seacrhPodcast(searchPodcast: String) {
        repository.searchPodcasts(searchPodcast: searchPodcast) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let podcasts):
                    self?.podcasts = podcasts
                    self?.onDataUpdated?()
                    print(podcasts)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}
