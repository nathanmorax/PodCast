//
//  PodcastCell.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import SDWebImage
import SwiftUI

struct PodcastCellUI: View {
    
    let podcast: Podcast?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            PodcastImage(source: podcast?.artworkUrl600)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//            artworkView
//                .frame(width: 80, height: 80)
//                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(podcast?.trackName ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(podcast?.artistName ?? "")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("\(podcast?.trackCount ?? 0) episodios")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer(minLength: 0)
        }
        .background(Color.clear)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var artworkView: some View {
        if let urlString = podcast?.artworkUrl600,
           let url = URL(string: urlString),
           urlString.hasPrefix("http") {
            // Es una URL real → AsyncImage
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(uiColor: .secondarySystemFill)
            }
        } else if let urlString = podcast?.artworkUrl600, !urlString.isEmpty {
            // Es nombre de un asset local
            Image(urlString)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Sin imagen
            Color(uiColor: .secondarySystemFill)
        }
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


//#Preview(traits: .sizeThatFitsLayout) {
//    PodcastCellUI(podcast: .mock)
//        .padding()
//}
