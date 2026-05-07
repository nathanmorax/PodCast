//
//  FavoritesPodcastCell.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//
import SwiftUI

struct FavoritesPodcastCellUI: View {
    var podcast: Podcast
    
    var body: some View {
        VStack(spacing: 12) {
            PodcastImage(source: podcast.artworkUrl600)
                .frame(width: 95, height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-4))
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                .offset(y: -70)
                .padding(.bottom, -50)
             
            Text(podcast.trackName ?? "")
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
            
            Text(podcast.artistName ?? "")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.bottom, 30)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: 125)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .systemGray5))
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    FavoritesPodcastCellUI(podcast: .mock)
        .frame(width: 280)
        .padding(40)
}
