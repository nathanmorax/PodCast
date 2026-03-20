//
//  Untitled.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//
import Combine

protocol SearchPodcastRepository {
    func searchPodcasts(
        searchPodcast: String,
        completion: @escaping (Result<[Podcast], Error>) -> Void
    )

    func fetchEpisodes(
        feedURL: String,
        completion: @escaping (Result<[Episode], Error>) -> Void
    )
    
    func searchPodcastsPublisher(searchPodcast: String) -> AnyPublisher<[Podcast], Error>
    func fetchEpisodesPublisher(feedURL: String) -> AnyPublisher<[Episode], Error>
}
