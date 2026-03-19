//
//  Podcast.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import Foundation

struct SearchResults: Codable {
    let resultCount: Int
    let results: [Podcast]
}

struct Podcast: Codable {
    let trackId: Int
    let trackName: String?
    let artistName: String?
    let artworkUrl600: String?
    let primaryGenreName: String?
    let trackCount: Int?
    let feedUrl: String?
}

