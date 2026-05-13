//
//  MiniPlayerView.swift
//  Podcast
//
//  Created by Satori Tech 341 on 12/05/26.
//
import SwiftUI

struct MiniPlayerView: View {
    
    let episode: Episode
    let viewModel: AVPlayerViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            
            PodcastImage(source: episode.imageUrl)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.black)
                
                Text(episode.author)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            AppButton(
                style: .icon,
                tone: .neutral,
                size: .compact,
                icon: .toggle(
                    selected: Image(systemName: "pause.fill"),
                    unselected: Image(systemName: "play.fill")
                ),
                title: "Play/Pause",
                isSelected: viewModel.isPlaying
            ) {
                viewModel.togglePlayPause()
            }
            
            AppButton(
                style: .icon,
                tone: .neutral,
                size: .compact,
                icon: .only(Image(systemName: "15.arrow.trianglehead.clockwise")),
                title: "Forward"
            ) {
                viewModel.seekForward()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
    }
}


#Preview {
    MiniPlayerView(episode: Episode.mock, viewModel: AVPlayerViewModel())
}
