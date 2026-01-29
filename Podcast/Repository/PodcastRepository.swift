//
//  Untitled.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//

protocol PodcastRepository {
    func searchPodcasts(
        searchPodcast: String,
        completion: @escaping (Result<[Podcast], Error>) -> Void
    )

    func fetchEpisodes(
        feedURL: String,
        completion: @escaping (Result<[Episode], Error>) -> Void
    )
}
