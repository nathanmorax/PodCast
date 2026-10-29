//
//  LibraryEpisodeTile.swift
//  Podcast
//

import SwiftUI

/// One episode in the Library's grid: the square cover with a small ▶ on
/// its corner (a hairline along its bottom while it downloads), the title
/// in tall capitals and the meta line. Smaller type when three go across.
/// Touch and hold for save, download and share.
struct LibraryEpisodeTile: View {

    let item: LibraryItem
    /// Three across: smaller title, only the length.
    var isCompact = false
    let onOpen: () -> Void

    var body: some View {
        let actions = EpisodeActionViewModel(episode: item.episode)

        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                Button(action: onOpen) { cover }
                    .buttonStyle(.plain)
                    // The title below opens it too; one stop for VoiceOver.
                    .accessibilityHidden(true)

                LibraryPlayButton(actions: actions, style: .onCover)
                    .padding(isCompact ? 0 : 2)
            }

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.episode.title)
                        .font(
                            isCompact
                                ? .system(.footnote, weight: .bold).width(.compressed)
                                : .system(.callout, weight: .bold).width(.compressed)
                        )
                        .textCase(.uppercase)
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(isCompact ? 2 : 3)
                        .multilineTextAlignment(.leading)

                    LibraryEpisodeMeta(
                        episode: item.episode,
                        isPlaying: actions.isPlaying,
                        showsDate: !isCompact
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")
        }
        .contextMenu {
            EpisodeActionsMenuItems(actions: actions)
        }
    }

    private var cover: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { PodcastImage(source: item.artwork) }
            .clipped()
            .overlay(alignment: .bottom) {
                DownloadProgressLine(episode: item.episode, track: .white.opacity(0.35))
            }
            .contentShape(Rectangle())
    }
}
