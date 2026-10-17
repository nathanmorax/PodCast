//
//  PodcastRemoteDataSource.swift
//  Podcast
//

import Foundation

protocol PodcastRemoteDataSource: Sendable {

    func searchPodcast(query: String) async throws -> [Podcast]

    /// Downloads and parses the podcast's RSS once.
    func fetchFeed(feedURL: String) async throws -> PodcastFeed

    func fetchGenres() async throws -> [Genre]
}
