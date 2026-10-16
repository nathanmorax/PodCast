//
//  PodcastRemoteDataSource.swift
//  Podcast
//

import Foundation

protocol PodcastRemoteDataSource {
    func searchPodcasts(
        seacrhPodcast: String,
        completion: @escaping (Result<[Podcast], Error>) -> Void
    )
    
    func fetchEpisodes(
        feedURL: String,
        completion: @escaping (Result<[Episode], Error>) -> Void
    )
    
    func fetchGenresPodcast(completion: @escaping (Result<[Genre], Error>) -> Void)
    
//    func fecthGenresPodcast() async throws -> [Genre]
    
    func searchPodcast(query: String) async throws -> [Podcast]
    
    func fetchEpisodes(feedURL: String) async throws -> [Episode]
    
}
