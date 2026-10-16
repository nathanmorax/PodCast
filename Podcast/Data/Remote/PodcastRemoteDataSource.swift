//
//  PodcastRemoteDataSource.swift
//  Podcast
//

import Foundation

protocol PodcastRemoteDataSource {

    func searchPodcast(query: String) async throws -> [Podcast]

    func fetchEpisodes(feedURL: String) async throws -> [Episode]

    /// Still callback-based (GenresRepository uses it); candidate for async.
    func fetchGenresPodcast(completion: @escaping (Result<[Genre], Error>) -> Void)
}
