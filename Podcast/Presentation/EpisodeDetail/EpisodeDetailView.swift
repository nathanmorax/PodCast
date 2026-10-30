//
//  EpisodeDetailView.swift
//  Podcast
//

import SwiftUI

/// An episode, full screen, laid out like a film's page in a magazine app
/// (after MUBI's):
/// - EpisodeHero: the artwork edge to edge with the show, the title in tall
///   capitals and the date · length;
/// - EpisodeActionsBar: Listen, save, download, share;
/// - WhyListenBox: the notes' first sentence in an ink-bordered box;
/// - Show notes: the rest of them;
/// - ChaptersSection, when the notes list chapters;
/// - FromTheShowRow and MoreFromShowSection (dark), when the show is known.
/// Sections with nothing to show aren't drawn.
struct EpisodeDetailView: View {

    let viewModel: EpisodeDetailViewModel
    let pull: HeaderPull
    let onOpenPodcast: (Podcast) -> Void
    let onOpenEpisode: (Episode) -> Void
    /// Vertical scroll position (negative while pulled past the top).
    let onScroll: (CGFloat) -> Void

    @Environment(\.playerManager) private var playerManager
    @Environment(\.favoritesManager) private var favoritesManager

    private var episode: Episode { viewModel.episode }

    var body: some View {
        let notes = viewModel.notes
        let actions = EpisodeActionViewModel(episode: episode)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EpisodeHero(
                    episode: episode,
                    showName: viewModel.podcast?.trackName,
                    genre: viewModel.podcast?.genreName,
                    pull: pull
                )

                VStack(alignment: .leading, spacing: 24) {
                    EpisodeActionsBar(actions: actions) {
                        playerManager.playOrToggle(episode, presentation: .mini)
                    }

                    if let quote = notes.quote {
                        WhyListenBox(text: quote)
                    }

                    if !notes.rest.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            EpisodeSectionTitle(title: "Show notes")
                            Text(notes.rest)
                                .font(.subheadline)
                                .foregroundStyle(AppColor.Text.secondary)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if !viewModel.chapters.isEmpty {
                        ChaptersSection(
                            chapters: viewModel.chapters,
                            current: currentChapter,
                            onSelect: play
                        )
                    }

                    if let podcast = viewModel.podcast {
                        FromTheShowRow(
                            podcast: podcast,
                            isFollowing: favoritesManager.isFavorite(podcast),
                            onOpen: { onOpenPodcast(podcast) },
                            onToggleFollow: {
                                withAnimation(AppAnimation.selection) { favoritesManager.toggleFavorite(podcast) }
                            }
                        )
                    }
                }
                .foregroundStyle(AppColor.Text.primary)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)

                if !viewModel.moreEpisodes.isEmpty {
                    MoreFromShowSection(
                        showName: viewModel.podcast?.trackName ?? episode.author,
                        episodes: viewModel.moreEpisodes,
                        onOpen: onOpenEpisode,
                        onPlay: { playerManager.playOrToggle($0, presentation: .mini) }
                    )
                    .transition(.opacity)
                }
            }
            .animation(AppAnimation.listChange, value: viewModel.moreEpisodes.map(\.streamUrl))
        }
        .scrollIndicators(.hidden)
        // The artwork starts under the status bar and the (clear) navigation bar.
        .ignoresSafeArea(edges: .top)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            onScroll(offset)
        }
        .task { await viewModel.loadMoreEpisodes() }
    }

    // MARK: - Chapters

    private var isCurrentEpisode: Bool {
        playerManager.currentEpisode?.streamUrl == episode.streamUrl
    }

    /// The last chapter already started, while this episode is in the player.
    private var currentChapter: EpisodeChapter? {
        guard isCurrentEpisode else { return nil }
        let now = playerManager.viewModel.currentPlaybackSeconds
        return viewModel.chapters.last { $0.start <= now }
    }

    /// In the player: jump there. Otherwise: start it there, in the mini
    /// player (from the beginning when its length isn't known yet).
    private func play(_ chapter: EpisodeChapter) {
        if isCurrentEpisode {
            playerManager.viewModel.seek(toSeconds: chapter.start)
        } else {
            let progress = episode.durationSeconds.map { $0 > 0 ? chapter.start / $0 : 0 }
            playerManager.play(episode, presentation: .mini, from: progress)
        }
    }
}
