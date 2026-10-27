//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import SwiftUI

/// One episode in a list (a podcast's page, Favorites, Downloads, the
/// Inbox), like a magazine's audio list: the show in serif capitals in the
/// accent, the title in bold, the date (· length, ↓ when downloaded);
/// the artwork on the right with ▶ on its corner.
struct EpisodeCell: View {
    let viewModel: EpisodeActionViewModel

    private var episode: Episode { viewModel.episode }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                RowOverline(text: episode.author)
                RowTitle(text: episode.title)

                // "October 25, 2026 · 41 min ↓". No •••: save, download
                // and share are in the details (tap the row).
                HStack(spacing: 6) {
                    Text(episode.pubDate, format: .dateTime.day().month(.wide).year())
                    Text(verbatim: "·")
                    Text(episode.durationDisplayText)
                    DownloadedBadge(episode: episode)
                }
                .font(.system(.callout, weight: .medium))
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            RowArtwork {
                PodcastImage(source: episode.imageUrl)
            }
            .overlay(alignment: .bottomTrailing) {
                RowPlayButton(isPlaying: viewModel.isPlaying) {
                    viewModel.playOrPause()
                }
                .offset(x: 8, y: 8)
            }
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
