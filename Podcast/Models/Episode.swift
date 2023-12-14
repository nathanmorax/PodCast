//
//  Episode.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import Foundation
import FeedKit

struct Episode {
    let title: String
    let author: String
    let pubDate: Date
    let description: String
    let streamUrl: String
    var imageUrl: String?
    
    init(feedItem: RSSFeedItem) {
        self.title = feedItem.title ?? ""
        self.author = feedItem.iTunes?.iTunesAuthor ?? ""
        self.pubDate = feedItem.pubDate ?? Date()
        self.description = feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? ""
        self.streamUrl = feedItem.enclosure?.attributes?.url ?? ""
        self.imageUrl = feedItem.iTunes?.iTunesImage?.attributes?.href ?? ""
    }
}
