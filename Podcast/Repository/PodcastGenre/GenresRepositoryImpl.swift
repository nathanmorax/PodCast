//
//  GenresRepositoryImpl.swift
//  Podcast
//
//  Created by Satori Tech 341 on 20/03/26.
//

protocol GenresRepository {
    func fetchGenresPodcast(completion: @escaping (Result<[Genre], Error>) -> Void)
}

final class GenresRepositoryImpl: GenresRepository {
    
    private let remoteDataSource: PodcastRemoteDataSource
    
    
    init(remoteDataSource: PodcastRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }
    
    
    func fetchGenresPodcast(completion: @escaping (Result<[Genre], any Error>) -> Void) {
        remoteDataSource.fetchGenresPodcast(completion: completion)
    }
}
