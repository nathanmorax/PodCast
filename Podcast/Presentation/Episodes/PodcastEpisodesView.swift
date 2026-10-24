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
///
/// Dragging down from the top closes the page: the system's zoom transition
/// does it (EpisodesController+Zoom), shrinking the page back into the cover
/// it was opened from. Nothing custom here: a second pull-to-close fought
/// the system's gesture and made the landing jump.
struct PodcastEpisodesView: View {

    let podcast: Podcast
    let viewModel: EpisodesViewModel
    let actions: EpisodeHeaderActions
    /// Vertical scroll position (0 at rest, negative while pulled down).
    let onScroll: (CGFloat) -> Void
    let onShowInfo: (Episode) -> Void

    /// The artwork's color, read once it loads. Already known (opened
    /// before): the page starts painted, no fade.
    @State private var loadedTint: ArtworkTint?

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: podcast.artworkUrl600)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                EpisodeHeaderView(
                    podcast: podcast,
                    isFavorite: viewModel.isFavorite(podcast),
                    podcastDescription: viewModel.podcastDescription,
                    isLoadingDescription: viewModel.isLoadingDescription,
                    tint: tint,
                    actions: actions
                )
                .padding(.bottom, 12)

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
        // The page starts below the navigation bar, so the cover never sits
        // under the status bar or touches the top edge.
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            onScroll(offset)
        }
        // The cells' 600 px artwork: usually in memory already.
        .task(id: podcast.id) {
            let tint = await ArtworkTintLoader.tint(for: podcast.artworkUrl600)
            withAnimation(.easeInOut(duration: 0.35)) { loadedTint = tint }
        }
    }

    /// The next page loads when the last row shows up.
    private func loadMoreIfLast(_ episode: Episode) {
        guard episode.streamUrl == viewModel.episodes.last?.streamUrl else { return }
        viewModel.loadMoreEpisodes()
    }
}

#Preview {
    let viewModel = EpisodesViewModel(repository: PreviewSearchRepository(), favoritesManager: .preview)
    NavigationStack {
        PodcastEpisodesView(
            podcast: .mock,
            viewModel: viewModel,
            actions: EpisodeHeaderActions(),
            onScroll: { _ in },
            onShowInfo: { _ in }
        )
        .task { viewModel.loadEpisodes(feedURL: "preview") }
    }
    .environment(\.playerManager, .preview)
}
