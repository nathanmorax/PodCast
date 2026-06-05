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

    
    private var iconName: String {
        switch state {
        case .idle:         return "arrow.down"
        case .downloading:  return "pause.fill"
        case .downloaded:    return "play.fill"
        case .failed:        return "checkmark"
        }
    }


    var body: some View {
        HStack(spacing: 12) {
            
            PodcastImage(source: viewModel.episode.imageUrl)
                .frame(width: 95, height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.episode.author)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.gray)
                
                Text(viewModel.episode.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(viewModel.episode.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                

                
                HStack {
                    
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
                    
                    Spacer()
                    
                    Button {
                        viewModel.toggleBookmark()
                    } label: {
                        Image(systemName: "bookmark.fill")
                    }
                    .foregroundStyle(.black)


                    Button {
                        
                        switch viewModel.downloadState {
                        case .idle:
                            viewModel.download()
                        case .downloading:
                            viewModel.cancelDownload()
                        case .downloaded:
                            viewModel.deleteDownload()
                        case .failed:
                            viewModel.download()

                        }
                        
                    } label: {
                        
                        Image(systemName: viewModel.downloadState.iconName)
                    }
                    .foregroundStyle(.black)

                    
                }
                
            }
        }
    }
}
