//
//  PodcastEpisodesView.swift
//  Podcast
//

import SwiftUI

/// The podcast page's content: the header (cover, Listen, ⓘ, share) and the
/// episodes, in one ScrollView. Hosted by EpisodesController.
///
/// LazyVStack: each row is as tall as its content and placed right below the
/// previous one, so rows can't overlap; only the rows on screen are built.
struct PodcastEpisodesView: View {

    let podcast: Podcast
    let viewModel: EpisodesViewModel
    let actions: EpisodeHeaderActions
    let pull: HeaderPull
    /// Vertical scroll position (negative while pulled past the top).
    let onScroll: (CGFloat) -> Void
    let onShowInfo: (Episode) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                EpisodeHeaderView(
                    podcast: podcast,
                    isFavorite: viewModel.isFavorite(podcast),
                    podcastDescription: viewModel.podcastDescription,
                    isLoadingDescription: viewModel.isLoadingDescription,
                    actions: actions,
                    pull: pull
                )
                .padding(.bottom, 8)

                if viewModel.isLoadingEpisodes && viewModel.episodes.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                }

                ForEach(viewModel.episodes, id: \.streamUrl) { episode in
                    EpisodeRow(
                        episode: episode,
                        showsSeparator: episode.streamUrl != viewModel.episodes.last?.streamUrl
                    ) { onShowInfo(episode) }
                    .onAppear { loadMoreIfLast(episode) }
                }
            }
            .padding(.bottom, 8)
        }
        // The cover starts under the status bar and the (clear) navigation bar.
        .ignoresSafeArea(edges: .top)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            onScroll(offset)
        }
    }

    /// The next page loads when the last row shows up.
    private func loadMoreIfLast(_ episode: Episode) {
        guard episode.streamUrl == viewModel.episodes.last?.streamUrl else { return }
        viewModel.loadMoreEpisodes()
    }
}
