//
//  PodcastRepositoryImpl.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//

import UIKit
import Combine

final class PodcastRepositoryImpl: SearchPodcastRepository {
    
    private let remoteDataSource: PodcastRemoteDataSource
    
    init(remoteDataSource: PodcastRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }
    func searchPodcast(query: String) async throws -> [Podcast] {
        try await remoteDataSource.searchPodcast(query: query)
    }

    func fetchEpisodes(feedURL: String) async throws -> [Episode] {
        try await remoteDataSource.fetchEpisodes(feedURL: feedURL)
    }
}
