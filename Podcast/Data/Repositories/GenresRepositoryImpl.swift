//
//  GenresRepositoryImpl.swift
//  Podcast
//
//  Created by Jonathan Mora on 20/03/26.
//

final class GenresRepositoryImpl: GenresRepository {

    private let remoteDataSource: PodcastRemoteDataSource

    init(remoteDataSource: PodcastRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchGenres() async throws -> [Genre] {
        try await remoteDataSource.fetchGenres()
    }
}
