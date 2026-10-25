//
//  InboxView.swift
//  Podcast
//

import SwiftUI

/// The Inbox: new episodes of the podcasts you follow. Those published since
/// it was last opened under "New", the rest of the month under "Earlier".
/// Each row says which podcast it's from. Hosted by InboxController.
struct InboxView: View {

    let items: [PodcastEpisode]
    /// Episodes after this are "New" (when the Inbox was opened before).
    let newSince: Date
    let onOpen: (PodcastEpisode) -> Void

    private var newItems: [PodcastEpisode] {
        items.filter { $0.episode.pubDate > newSince }
    }

    private var earlierItems: [PodcastEpisode] {
        items.filter { $0.episode.pubDate <= newSince }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("No new episodes", systemImage: "tray")
                } description: {
                    Text("New episodes from the podcasts you follow show up here.")
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        section("New", items: newItems)
                        section("Earlier", items: earlierItems)
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.screenBackground)
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, items: [PodcastEpisode]) -> some View {
        if !items.isEmpty {
            LibrarySectionHeader(title: title)
                .padding(.top, 12)
                .padding(.bottom, 4)
            ForEach(items) { item in
                InboxRow(
                    item: item,
                    showsSeparator: item.id != items.last?.id,
                    onOpen: { onOpen(item) }
                )
            }
        }
    }
}

/// The podcast's name over the usual episode row.
private struct InboxRow: View {

    let item: PodcastEpisode
    let showsSeparator: Bool
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.podcast.trackName ?? "")
                .overlineStyle()
                .lineLimit(1)
                .padding(.horizontal, 24)
                .padding(.top, 10)
            EpisodeRow(episode: item.episode, showsSeparator: showsSeparator, onShowInfo: onOpen)
        }
    }
}
