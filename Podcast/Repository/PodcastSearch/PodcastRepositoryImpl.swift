//
//  PodcastRepositoryImpl.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//

import UIKit

final class PodcastRepositoryImpl: SearchPodcastRepository {
    
    private let remoteDataSource: PodcastRemoteDataSource

    
    init(remoteDataSource: PodcastRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }
    
    func searchPodcasts(searchPodcast: String, completion: @escaping (Result<[Podcast], any Error>) -> Void) {
        remoteDataSource.searchPodcasts(seacrhPodcast: searchPodcast, completion: completion)
    }
    
    func fetchEpisodes(feedURL: String, completion: @escaping (Result<[Episode], any Error>) -> Void) {
        remoteDataSource.fetchEpisodes(feedURL: feedURL, completion: completion)
    }
    
}
