//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import UIKit
import SwiftUI

struct EpisodeCell: View {
    
    var episode: Episode
    
    var body: some View {
        HStack {
            
//            PodcastImage(source: episode.imageUrl)
//                .frame(width: 80, height: 80)
//                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            WaveformIcon()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(episode.pubDate, style: .date)
                    .foregroundStyle(AppColor.dustyBlue)
                    .font(.subheadline)
                Text(episode.description)
                    .font(.caption)
                
            }
        
            
            Spacer(minLength: 12)
        }
        .onAppear {
            PerformanceLogger.rendering.event("EpisodeCellUI appeared", "title: \(episode.title)")
        }
        .padding(.horizontal, 8)
    }
}

//#Preview {
//    VStack {
//        ForEach(Episode.mocks, id: \.title) { episode in
//            EpisodeCellUI(episode: episode)
//        }
//    }
//    .padding()
//    .background(Color.gray)
//}
