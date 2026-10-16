//
//  PodcastRepositoryImpl.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//

import Foundation

final class PodcastRepositoryImpl: SearchPodcastRepository {

    private let remoteDataSource: PodcastRemoteDataSource

    init(remoteDataSource: PodcastRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func searchPodcast(query: String) async throws -> [Podcast] {
        try await remoteDataSource.searchPodcast(query: query)
    }

    func fetchFeed(feedURL: String) async throws -> PodcastFeed {
        try await remoteDataSource.fetchFeed(feedURL: feedURL)
    }
}
