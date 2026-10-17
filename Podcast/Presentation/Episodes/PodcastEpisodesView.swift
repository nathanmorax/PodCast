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
    let stretch: HeaderStretch
    /// Vertical scroll position (negative while pulled past the top).
    let onScroll: (CGFloat) -> Void
    let onShowInfo: (Episode) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                EpisodeHeaderView(
                    podcast: podcast,
                    isFavorite: viewModel.isFavorite(podcast),
                    podcastDescription: viewModel.podcastDescription,
                    isLoadingDescription: viewModel.isLoadingDescription,
                    actions: actions,
                    stretch: stretch
                )
                .padding(.bottom, 4)

                if viewModel.isLoadingEpisodes && viewModel.episodes.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                }

                ForEach(viewModel.episodes, id: \.streamUrl) { episode in
                    EpisodeRow(episode: episode) { onShowInfo(episode) }
                        .padding(.horizontal, 8)
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

/// One episode in the list: the existing EpisodeCell on a card. Tapping it
/// opens its details; only its play button plays.
private struct EpisodeRow: View {

    let episode: Episode
    let onShowInfo: () -> Void

    var body: some View {
        EpisodeCell(viewModel: EpisodeActionViewModel(episode: episode), onInfo: onShowInfo)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            // The play button and the ••• menu inside keep their own taps.
            .onTapGesture(perform: onShowInfo)
            .accessibilityAction(named: Text("Details"), onShowInfo)
    }
}
