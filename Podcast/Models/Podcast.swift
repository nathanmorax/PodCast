//
//  Podcast.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import Foundation

struct SearchResults: Decodable {
   let resultCount: Int
   let results: [Podcast]
}

struct Podcast: Decodable {
   let trackName: String?
   let artistName: String?
   let artworkUrl600: String?
   let trackCount: Int?
   let feedUrl: String?
}
