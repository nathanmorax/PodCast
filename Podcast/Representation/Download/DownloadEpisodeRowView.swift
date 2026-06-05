//
//  DownloadEpisodeRowView.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//
import SwiftUI

struct DownloadEpisodeRowView: View {
    let viewModel: EpisodeActionViewModel

//    var episode: Episode
    
    var body: some View {
        HStack(spacing: 12) {
            PodcastImage(source: viewModel.episode.imageUrl)
                .frame(width: 95, height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-4))
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                .offset(y: -70)
                .padding(.bottom, -50)
             
            VStack {
                Text(viewModel.episode.title)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text(viewModel.episode.author)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Button {
                    
                    viewModel.playOrPause()
                    
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .semibold))

                        Text(viewModel.episode.durationDisplayText)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }

            
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

//#Preview(traits: .sizeThatFitsLayout) {
//    FavoritesPodcastCellUI(podcast: .mock)
//        .frame(width: 280)
//        .padding(40)
//}
