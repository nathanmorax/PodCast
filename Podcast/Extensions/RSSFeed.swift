//
//  RSSFeed.swift
//  Podcast
//
//  Created by Xcaret Mora on 17/11/23.
//

import UIKit
import FeedKit

extension RSSFeed {
    func toEpisodes() -> [Episode] {
        var imageUrl = iTunes?.iTunesImage?.attributes?.href
        
        var episodes = [Episode]()
        items?.forEach({ (feedItem) in
            var episode = Episode(feedItem: feedItem)
            
            if episode.imageUrl == nil {
                episode.imageUrl = imageUrl ?? ""
            }
            
            episodes.append(episode)
        })
        return episodes
    }
}
