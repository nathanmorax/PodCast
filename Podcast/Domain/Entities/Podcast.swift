//
//  Podcast.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import Foundation

/// Sendable: only value fields, so search results can cross from the network
/// code to the UI.
struct Podcast: Codable, Sendable {
    let trackId: Int
    let trackName: String?
    let artistName: String?
    let artworkUrl600: String?
    let primaryGenreName: String?
    let trackCount: Int?
    let feedUrl: String?
    
    var id: Int { trackId }
    
    var artworkURL: URL? {
        guard let urlString = artworkUrl600 else { return nil }
        let highRes = urlString.replacingOccurrences(of: "600x600bb", with: "1400x1400bb")
        return URL(string: highRes)
    }
    
}

#if DEBUG
extension Podcast {
    static let mock = Podcast(
        trackId: 1200361736,
        trackName: "The Daily",
        artistName: "The New York Times",
        artworkUrl600: "appicon",
        primaryGenreName: "News",
        trackCount: 1234,
        feedUrl: "https://feeds.simplecast.com/54nAGcIl"
    )
}
#endif
