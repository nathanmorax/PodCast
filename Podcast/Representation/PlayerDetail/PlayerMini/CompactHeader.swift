//
//  CompactHeader.swift
//  Podcast
//
//  Created by Satori Tech 341 on 13/05/26.
//
import SwiftUI

struct CompactHeader: View {
    
    var episode: Episode
    @Binding var playerMode: PlayerMode
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                PodcastImage(source: episode.imageUrl)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(episode.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    
                    Text(episode.author)
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button {
                    playerMode = .normal
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.gray)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.gray.opacity(0.15)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }
}

#Preview {
    CompactHeader(episode: .mock, playerMode: .constant(.normal))
}
