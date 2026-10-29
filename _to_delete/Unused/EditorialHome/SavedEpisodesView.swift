//
//  SavedEpisodesView.swift
//  Podcast
//

import SwiftUI

/// Favorites or Downloads: the same rows as a podcast's page (EpisodeRow),
/// so an episode looks the same wherever it is. Tapping one opens it full
/// screen.
struct SavedEpisodesView: View {

    enum Collection {
        case favorites
        case downloads
    }

    let collection: Collection
    let onOpen: (Episode) -> Void

    @Environment(\.bookmarks) private var bookmarks
    @Environment(\.downloadManager) private var downloads

    private var episodes: [Episode] {
        switch collection {
        case .favorites: bookmarks.episodes
        case .downloads: downloads.downloadedEpisodes
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(episodes, id: \.streamUrl) { episode in
                    EpisodeRow(
                        episode: episode,
                        showsSeparator: episode.streamUrl != episodes.last?.streamUrl,
                        onShowInfo: { onOpen(episode) }
                    )
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .overlay {
            if episodes.isEmpty { emptyState }
        }
        .animation(AppAnimation.listChange, value: episodes.map(\.streamUrl))
    }

    @ViewBuilder
    private var emptyState: some View {
        switch collection {
        case .favorites:
            ContentUnavailableView(
                "No favorites yet",
                systemImage: "bookmark",
                description: Text("Save an episode from its ••• menu and it'll be here.")
            )
        case .downloads:
            ContentUnavailableView(
                "No downloads yet",
                systemImage: "arrow.down.circle",
                description: Text("Downloaded episodes play without internet.")
            )
        }
    }
}
