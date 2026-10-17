//
//  PodcastCellUI.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import SDWebImage
import SwiftUI

struct PodcastCellUI: View {
    
    let podcast: Podcast?
    
    @State private var isFollow: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            
            PodcastImage(source: podcast?.artworkUrl600)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
//            artworkView
//                .frame(width: 80, height: 80)
//                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(podcast?.trackName ?? "")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                
                Text(podcast?.artistName ?? "")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
                
                Text("\(podcast?.trackCount ?? 0) episodes")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.Text.tertiary)
            }
            
            Spacer()

            
            Button {
                print("Follow")
                isFollow.toggle()
            } label: {
                Image(systemName: isFollow ? "checkmark.circle.fill" : "plus")
                    .foregroundStyle(AppColor.Text.primary)
            }
            
        }
        .background(Color.clear)
        .padding(.vertical, 8)
        // Cells are reused: a new identity per podcast resets @State
        // so the follow state doesn't leak to another row.
        .id(podcast?.trackId)
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

//#Preview(traits: .sizeThatFitsLayout) {
//    PodcastCellUI(podcast: .mock)
//        .padding()
//}
