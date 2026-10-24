//
//  InboxView.swift
//  Podcast
//

import SwiftUI

/// The Inbox: new episodes of the podcasts you follow. Those published since
/// it was last opened under "New", the rest of the month under "Earlier".
/// Each row says which podcast it's from. Hosted by InboxController.
struct InboxView: View {

    let items: [ForYouViewModel.Item]
    /// Episodes after this are "New" (when the Inbox was opened before).
    let newSince: Date
    let onOpen: (ForYouViewModel.Item) -> Void

    private var newItems: [ForYouViewModel.Item] {
        items.filter { $0.episode.pubDate > newSince }
    }

    private var earlierItems: [ForYouViewModel.Item] {
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
    private func section(_ title: LocalizedStringKey, items: [ForYouViewModel.Item]) -> some View {
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

    let item: ForYouViewModel.Item
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

#Preview("With episodes") {
    InboxView(
        items: Episode.mocks.map { ForYouViewModel.Item(podcast: .mock, episode: $0) },
        newSince: .distantPast,
        onOpen: { _ in }
    )
    .environment(\.playerManager, .preview)
}

#Preview("Empty") {
    InboxView(items: [], newSince: .now, onOpen: { _ in })
}
