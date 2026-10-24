//
//  PodcastCellUI.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import SwiftUI

/// A podcast row: cover, name in serif and "author · genre". In a category
/// it's numbered (its ranking). In results the follow button sits next to it.
struct PodcastCellUI: View {

    let podcast: Podcast
    /// 1, 2, 3… in a category's ranking; nil elsewhere.
    var rank: Int? = nil
    var coverSide: CGFloat = 56

    var body: some View {
        HStack(spacing: 14) {
            if let rank {
                Text(rank, format: .number)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(minWidth: 22, alignment: .leading)
                    .accessibilityLabel(Text("Number \(rank)"))
            }

            ZoomSourceImage(podcast: podcast, cornerRadius: 6)
                .frame(width: coverSide, height: coverSide)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(podcast.trackName ?? "")
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                Text(Self.subtitle(for: podcast))
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    /// "Author · Genre".
    static func subtitle(for podcast: Podcast) -> String {
        [podcast.artistName, podcast.primaryGenreName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 0) {
        PodcastCellUI(podcast: .mock, rank: 2)
        PodcastCellUI(podcast: .mock, coverSide: 48)
    }
    .padding()
}
