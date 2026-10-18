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

/// One episode in the list: the existing EpisodeCell on the page itself, no
/// card, with a hairline separator under it (inset like iOS lists). Tapping
/// it opens its details; only its play button plays.
private struct EpisodeRow: View {

    let episode: Episode
    let showsSeparator: Bool
    let onShowInfo: () -> Void

    /// For a true one-pixel hairline on any screen.
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        EpisodeCell(viewModel: EpisodeActionViewModel(episode: episode), onInfo: onShowInfo)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                if showsSeparator {
                    Rectangle()
                        .fill(AppColor.Text.tertiary.opacity(0.5))
                        .frame(height: 1 / displayScale)
                        .padding(.horizontal, 24)
                }
            }
            .contentShape(Rectangle())
            // The play button and the ••• menu inside keep their own taps.
            .onTapGesture(perform: onShowInfo)
            .accessibilityAction(named: Text("Details"), onShowInfo)
    }
}
