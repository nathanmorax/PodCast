//
//  LibraryEpisodeLine.swift
//  Podcast
//

import SwiftUI

/// One episode in the Library's list: its cover, date · length in small capitals,
/// the title in tall capitals (a hairline under it while it downloads)
/// and ▶ in a thin ring. The line opens the episode; ▶ plays it; touch
/// and hold for save, download and share.
struct LibraryEpisodeLine: View {

    let item: LibraryItem
    let onOpen: () -> Void

    var body: some View {
        let actions = EpisodeActionViewModel(episode: item.episode)

        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                Color.clear
                    .frame(width: 56, height: 56)
                    .overlay { PodcastImage(source: item.artwork) }
                    .clipped()
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    LibraryEpisodeMeta(episode: item.episode, isPlaying: actions.isPlaying)

                    Text(item.episode.title)
                        .font(.system(.title3, weight: .bold).width(.compressed))
                        .textCase(.uppercase)
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    DownloadProgressLine(episode: item.episode)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            LibraryPlayButton(actions: actions)
        }
        .padding(.vertical, 10)
        .contextMenu {
            EpisodeActionsMenuItems(actions: actions)
        }
    }
}
