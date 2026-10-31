//
//  PodcastCellUI.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import SwiftUI

/// A podcast row: its rounded cover, the name in bold, who makes it and
/// its category. In a category it's numbered (its ranking). In results the
/// follow button sits next to it.
struct PodcastCellUI: View {

    let podcast: Podcast
    /// 1, 2, 3… in a category's ranking; nil elsewhere.
    var rank: Int? = nil
    var coverSide: CGFloat = 64

    var body: some View {
        HStack(spacing: 14) {
            if let rank {
                Text(rank, format: .number)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(minWidth: 26, alignment: .leading)
                    .accessibilityLabel(Text("Number \(rank)"))
            }

            Color.clear
                .frame(width: coverSide, height: coverSide)
                .overlay { ZoomSourceImage(podcast: podcast, cornerRadius: 12) }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(podcast.trackName ?? "")
                    .font(.headline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let artist = podcast.artistName, !artist.isEmpty {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
                if let genre = podcast.genreName {
                    Text(genre)
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
