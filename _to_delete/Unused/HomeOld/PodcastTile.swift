//
//  PodcastTile.swift
//  Podcast
//

import SwiftUI

struct PodcastTile: View {
    let podcast: Podcast

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .frame(width: 132, height: 132)
                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(podcast.trackName ?? "")
                .font(AppFont.itemTitle)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(podcast.artistName ?? "")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(1)
        }
        .frame(width: 132, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
