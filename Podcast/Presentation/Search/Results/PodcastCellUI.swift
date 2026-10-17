//
//  PodcastCellUI.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import SwiftUI

/// A podcast in search results or in a category: cover, name in serif,
/// author and episode count. In a category it's numbered (its ranking).
struct PodcastCellUI: View {

    let podcast: Podcast
    /// 1, 2, 3… in a category's ranking; nil in search results.
    var rank: Int? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if let rank {
                Text(rank, format: .number)
                    .font(AppFont.editorialItem)
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(minWidth: 24, alignment: .leading)
                    .accessibilityLabel(Text("Number \(rank)"))
            }

            PodcastImage(source: podcast.artworkUrl600)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.trackName ?? "")
                    .font(AppFont.editorialItem)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    /// "Author · 128 episodes".
    private var subtitle: String {
        var parts: [String] = []
        if let artist = podcast.artistName, !artist.isEmpty { parts.append(artist) }
        if let count = podcast.trackCount {
            parts.append(String(localized: "\(count) episodes"))
        }
        return parts.joined(separator: " · ")
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PodcastCellUI(podcast: .mock, rank: 1)
        .padding()
}
