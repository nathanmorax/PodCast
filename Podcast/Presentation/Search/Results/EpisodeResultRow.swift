//
//  EpisodeResultRow.swift
//  Podcast
//

import SwiftUI

/// An episode found by Search, like a magazine's audio list: the show in
/// serif capitals in the accent, the title in bold, the date · length (↓
/// when downloaded); its artwork on the right.
struct EpisodeResultRow: View {

    let result: EpisodeSearchResult
    /// Tapping the row (not its ▶): the details.
    let onOpen: () -> Void

    @Environment(\.playerManager) private var playerManager

    private var episode: Episode { result.episode }

    private var isPlaying: Bool {
        playerManager.currentEpisode?.streamUrl == episode.streamUrl && playerManager.viewModel.isPlaying
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                RowOverline(text: result.podcastName)
                RowTitle(text: episode.title)
                HStack(spacing: 6) {
                    Text(meta)
                        .lineLimit(1)
                    DownloadedBadge(episode: episode)
                }
                .font(.system(.callout, weight: .medium))
                .foregroundStyle(AppColor.Text.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RowArtwork(side: 80) {
                PodcastImage(source: episode.imageUrl)
            }
            // Plays in the mini player, without opening anything (the row
            // itself opens the details).
            .overlay(alignment: .bottomTrailing) {
                RowPlayButton(isPlaying: isPlaying) {
                    playerManager.playOrToggle(episode, presentation: .mini)
                }
                .offset(x: 8, y: 8)
            }
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        // A tap, not a Button: a Button around the row would take the ▶'s
        // tap too. The ▶ keeps its own.
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text("Details"), onOpen)
    }

    /// "October 25, 2026 · 24 min" (parts that are missing are left out).
    private var meta: String {
        var parts: [String] = []
        if episode.pubDate != .distantPast {
            parts.append(episode.pubDate.formatted(.dateTime.day().month(.wide).year()))
        }
        if episode.durationSeconds != nil {
            parts.append(episode.durationDisplayText)
        }
        return parts.joined(separator: " · ")
    }
}
