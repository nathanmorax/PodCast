//
//  PodcastCellUI.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import SwiftUI

/// A podcast row, like a magazine's audio list: its category in serif
/// capitals in the accent, the name in bold, who makes it; the cover on the
/// right. In a category it's numbered (its ranking). In results the follow
/// button sits next to it.
struct PodcastCellUI: View {

    let podcast: Podcast
    /// 1, 2, 3… in a category's ranking; nil elsewhere.
    var rank: Int? = nil
    var coverSide: CGFloat = 72

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let rank {
                Text(rank, format: .number)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(minWidth: 22, alignment: .leading)
                    .accessibilityLabel(Text("Number \(rank)"))
            }

            VStack(alignment: .leading, spacing: 5) {
                RowOverline(text: podcast.genreName ?? "")
                RowTitle(text: podcast.trackName ?? "")
                if let artist = podcast.artistName, !artist.isEmpty {
                    Text(artist)
                        .font(.system(.callout, weight: .medium))
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RowArtwork(side: coverSide) {
                ZoomSourceImage(podcast: podcast, cornerRadius: 6)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
