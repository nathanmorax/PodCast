//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import UIKit
import SwiftUI

struct EpisodeCellUI: View {
    
    var episode: Episode
    
    var body: some View {
        HStack {
            
            PodcastImage(source: episode.imageUrl)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(episode.pubDate, style: .date)
                Text(episode.description)
                
            }
            
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    VStack {
        ForEach(Episode.mocks, id: \.title) { episode in
            EpisodeCellUI(episode: episode)
        }
    }
    .padding()
    .background(Color.gray)
}

extension Episode {
    init(
        title: String,
        author: String,
        pubDate: Date,
        description: String,
        streamUrl: String,
        imageUrl: String? = nil
    ) {
        self.title = title
        self.author = author
        self.pubDate = pubDate
        self.description = description
        self.streamUrl = streamUrl
        self.imageUrl = imageUrl
    }
}

// Mock
#if DEBUG
extension Episode {
    
    static let mocks: [Episode] = [
        Episode(
            title: "Global News Podcast",
            author: "BBC World Service",
            pubDate: Date(timeIntervalSince1970: 1_745_000_000),
            description: "Noticias globales del día con análisis.",
            streamUrl: "https://example.com/episodes/1.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "Tech Talk",
            author: "Tech Daily",
            pubDate: Date(timeIntervalSince1970: 1_745_100_000),
            description: "Lo último en tecnología y desarrollo iOS.",
            streamUrl: "https://example.com/episodes/2.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "Startup Stories",
            author: "Founders Hub",
            pubDate: Date(timeIntervalSince1970: 1_745_200_000),
            description: "Historias de emprendedores exitosos.",
            streamUrl: "https://example.com/episodes/3.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "Design Matters",
            author: "UX Collective",
            pubDate: Date(timeIntervalSince1970: 1_745_300_000),
            description: "Diseño de productos digitales y UX.",
            streamUrl: "https://example.com/episodes/4.mp3",
            imageUrl: "appicon"
        ),
        Episode(
            title: "AI Today",
            author: "AI Lab",
            pubDate: Date(timeIntervalSince1970: 1_745_400_000),
            description: "Inteligencia artificial y su impacto real.",
            streamUrl: "https://example.com/episodes/5.mp3",
            imageUrl: "appicon"
        )
    ]
}
#endif


import SwiftUI

/// Muestra una imagen desde una URL remota, un asset local, o un placeholder.
/// Detecta automáticamente el tipo de fuente según el string que recibe.
struct PodcastImage: View {
    
    let source: String?
    var contentMode: ContentMode = .fill
    var placeholder: Color = Color(uiColor: .secondarySystemFill)
    
    var body: some View {
        if let source, !source.isEmpty {
            if source.hasPrefix("http"), let url = URL(string: source) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } placeholder: {
                    placeholder
                }
            } else {
                Image(source)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        } else {
            placeholder
        }
    }
}
