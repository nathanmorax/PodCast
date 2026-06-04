//
//  Episode.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import Foundation
import FeedKit

struct Episode: Codable {
    
    let title: String
    let author: String
    let pubDate: Date
    let description: String
    let duration: String?
    let durationSeconds: TimeInterval?
    let streamUrl: String
    var imageUrl: String?
        
    init(feedItem: RSSFeedItem) {
        self.title = feedItem.title ?? ""
        self.author = feedItem.iTunes?.author ?? ""
        self.pubDate = feedItem.pubDate ?? Date()
        
        let rawDescription = feedItem.iTunes?.subtitle
            ?? feedItem.description
            ?? ""
        
        self.description = rawDescription.strippingHTML()
        
        let rawDuration = feedItem.iTunes?.duration?.description
        self.duration = rawDuration
        self.durationSeconds = Self.parseDuration(rawDuration)
        
        self.streamUrl = feedItem.enclosure?.attributes?.url ?? ""
        self.imageUrl = feedItem.iTunes?.image?.attributes?.href ?? ""
    }
    
    var durationDisplayText: String {
        guard let durationSeconds else { return duration ?? "--" }
        return Self.formatDuration(durationSeconds)
    }
    
    private static func parseDuration(_ value: String?) -> TimeInterval? {
        guard let value, !value.isEmpty else { return nil }
        
        if let seconds = TimeInterval(value) {
            return seconds
        }
        
        let parts = value
            .split(separator: ":")
            .compactMap { TimeInterval($0) }
        
        switch parts.count {
        case 3:
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        case 2:
            return parts[0] * 60 + parts[1]
        default:
            return nil
        }
    }
    
    private static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(ceil(seconds / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours) h \(minutes) min"
        }
        
        return "\(totalMinutes) min"
    }
}


extension Episode {
    init(
        title: String,
        author: String,
        pubDate: Date,
        description: String,
        duration: String? = nil,
        durationSeconds: TimeInterval? = nil,
        streamUrl: String,
        imageUrl: String? = nil
    ) {
        self.title = title
        self.author = author
        self.pubDate = pubDate
        self.description = description
        self.duration = duration
        self.durationSeconds = durationSeconds ?? Self.parseDuration(duration)
        self.streamUrl = streamUrl
        self.imageUrl = imageUrl
    }
}

// Mock
#if DEBUG
extension Episode {
    
    static let mock: Episode = .mocks.first!
    
    static let mocks: [Episode] = [
        Episode(
            title: "Global News Podcast Global News Podcast",
            author: "BBC World Service",
            pubDate: Date(timeIntervalSince1970: 1_745_000_000),
            description: "Noticias globales del día con análisis.",
            duration: "58 min",
            streamUrl: "https://example.com/episodes/1.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "Tech Talk",
            author: "Tech Daily",
            pubDate: Date(timeIntervalSince1970: 1_745_100_000),
            description: "Lo último en tecnología y desarrollo iOS.",
            duration: "58 min",
            streamUrl: "https://example.com/episodes/2.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "Startup Stories",
            author: "Founders Hub",
            pubDate: Date(timeIntervalSince1970: 1_745_200_000),
            description: "Historias de emprendedores exitosos.",
            duration: "58 min",
            streamUrl: "https://example.com/episodes/3.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "Design Matters",
            author: "UX Collective",
            pubDate: Date(timeIntervalSince1970: 1_745_300_000),
            description: "Diseño de productos digitales y UX.",
            duration: "58 min",
            streamUrl: "https://example.com/episodes/4.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "AI Today",
            author: "AI Lab",
            pubDate: Date(timeIntervalSince1970: 1_745_400_000),
            description: "Inteligencia artificial y su impacto real.",
            duration: "58 min",
            streamUrl: "https://example.com/episodes/5.mp3",
            imageUrl: "appicon"
        )
    ]
}
#endif
