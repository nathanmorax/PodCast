//
//  SearchPodcastRepository.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//

protocol SearchPodcastRepository: Sendable {

    func searchPodcast(query: String) async throws -> [Podcast]

    /// One download of the podcast's RSS: description + episodes.
    func fetchFeed(feedURL: String) async throws -> PodcastFeed
}
