//
//  BookMarkView.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//

import SwiftUI

struct BookMarkView: View {
    
    let viewModel: EpisodeActionViewModel
    
    let state: DownloadState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            PodcastImage(source: viewModel.episode.imageUrl)
                .frame(width: 95, height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.episode.author)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                
                Text(viewModel.episode.title)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                
                Text(viewModel.episode.description)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2) // was unlimited: long descriptions made the row grow without end
                

                
                HStack {
                    
                    Button {
                        
                        viewModel.playOrPause()
                        
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .semibold))

                            Text(viewModel.episode.durationDisplayText)
                                .font(AppFont.captionStrong)
                        }
                        .foregroundStyle(AppColor.Text.primary)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        viewModel.toggleBookmark()
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(AppFont.itemTitle)
                            .frame(width: 36, height: 36)
                    }
                    .foregroundStyle(AppColor.Text.primary)
                    
                    DownloadButton(episode: viewModel.episode)
                    
                }
                
            }
        }
    }
}
