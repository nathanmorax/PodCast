//
//  Untitled.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//
import Combine

protocol SearchPodcastRepository {

    func searchPodcast(query: String) async throws -> [Podcast]
    func fetchEpisodes(feedURL: String) async throws -> [Episode]

}
