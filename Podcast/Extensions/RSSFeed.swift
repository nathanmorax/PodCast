//
//  RSSFeed.swift
//  Podcast
//
//  Created by Xcaret Mora on 17/11/23.
//

import FeedKit

extension RSSFeed {
    func toEpisodes() -> [Episode] {
        
        // Imagen del feed (canal)
        let feedImageUrl = self.channel?.image?.url
        let feedItunesUrl = self.channel?.iTunes?.image?.attributes?.href
        
        var episodes = [Episode]()
        
        self.channel?.items?.forEach { feedItem in
            var episode = Episode(feedItem: feedItem)
            
            if episode.imageUrl == nil || episode.imageUrl?.isEmpty == true {
                
                // 1) Imagen iTunes del item
                if let itemImage = feedItem.iTunes?.image?.attributes?.href {
                    episode.imageUrl = itemImage
                    
                    // 3) Imagen iTunes del canal
                } else if let feedItunes = feedItunesUrl {
                    episode.imageUrl = feedItunes
                    
                    // 4) Imagen estándar del canal
                } else if let feedImg = feedImageUrl {
                    episode.imageUrl = feedImg
                }
            }
            
            episodes.append(episode)
        }
        
        return episodes
    }
}
