//
//  PodcastRemoteDataSource.swift
//  Podcast
//

import Foundation

protocol PodcastRemoteDataSource: Sendable {

    func searchPodcast(query: String) async throws -> [Podcast]

    func searchEpisodes(query: String) async throws -> [EpisodeSearchResult]

    /// Downloads and parses the podcast's RSS once.
    func fetchFeed(feedURL: String) async throws -> PodcastFeed
}
