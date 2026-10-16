//
//  SearchResults.swift
//  Podcast
//

import Foundation

struct SearchResults: Codable {
    let resultCount: Int
    let results: [Podcast]
}
