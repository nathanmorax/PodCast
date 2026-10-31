//
//  PodcastEpisodesView.swift
//  Podcast
//

import SwiftUI

/// A podcast's page, like a classic podcast app's (the same look as Home
/// and the player). Hosted by EpisodesController:
/// - PodcastHero: the cover rounded and centered on a wash of its color,
///   the name, the host in the accent, the details;
/// - PodcastActionsBar: Follow, Latest, share, centered;
/// - AboutShowBox: the description in a soft box (whole in the About sheet);
/// - ContinueShowStrip: an episode of it left halfway, when there's one;
/// - EpisodeListControls and the episodes (EpisodeListRow, like Home's).
///
/// LazyVStack: each row is as tall as its content and placed right below the
/// previous one; only the rows on screen are built. Dragging down from the
/// top closes the page: the system's zoom transition does it.
struct PodcastEpisodesView: View {

    let podcast: Podcast
    let viewModel: EpisodesViewModel
    let actions: EpisodeHeaderActions
    /// Vertical scroll position (0 at rest, negative while pulled down).
    let onScroll: (CGFloat) -> Void
    let onOpenEpisode: (Episode) -> Void
    let onResume: (RecentlyPlayed) -> Void

    @Environment(\.recentlyPlayed) private var recentlyPlayed

    var body: some View {
        let played = Dictionary(recentlyPlayed.items.map { ($0.id, $0) }) { first, _ in first }

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                PodcastHero(podcast: podcast, cadence: viewModel.cadence)

                VStack(alignment: .leading, spacing: 20) {
                    PodcastActionsBar(
                        podcast: podcast,
                        isFollowing: viewModel.isFavorite(podcast),
                        onFollow: { actions.send(.follow) },
                        onLatest: { actions.send(.play) }
                    )

                    if let description = viewModel.podcastDescription, !description.isEmpty {
                        AboutShowBox(description: description) { actions.send(.about) }
                    } else if viewModel.isLoadingDescription {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                if let inProgress = viewModel.inProgress {
                    ContinueShowStrip(
                        item: inProgress,
                        onResume: { onResume(inProgress) },
                        onOpen: { onOpenEpisode(inProgress.episode) }
                    )
                    .padding(.bottom, 22)
                    .transition(.opacity)
                }

                EpisodeListControls(
                    filter: viewModel.filter,
                    order: viewModel.order,
                    onFilter: viewModel.setFilter,
                    onOrder: viewModel.setOrder
                )
                .padding(.horizontal, 20)

                if viewModel.isLoadingEpisodes && viewModel.episodes.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.episodes.isEmpty {
                    Text("No episodes here")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }

                ForEach(viewModel.episodes, id: \.streamUrl) { episode in
                    VStack(spacing: 0) {
                        Divider()
                        EpisodeListRow(
                            episode: episode,
                            artwork: (episode.imageUrl ?? "").isEmpty ? podcast.artworkUrl600 : episode.imageUrl,
                            played: played[episode.streamUrl],
                            zoomSection: .show
                        ) { onOpenEpisode(episode) }
                    }
                    .padding(.horizontal, 20)
                    .onAppear { loadMoreIfLast(episode) }
                }
            }
            .padding(.bottom, 8)
            .animation(AppAnimation.listChange, value: viewModel.episodes.map(\.streamUrl))
        }
        .scrollIndicators(.hidden)
        // The cover starts at the very top, under the clear bar.
        .ignoresSafeArea(edges: .top)
        .background(AppColor.screenBackground.ignoresSafeArea())
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
