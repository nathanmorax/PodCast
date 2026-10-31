//
//  EpisodeDetailView.swift
//  Podcast
//

import SwiftUI

/// An episode, full screen, like its show's page (the same look as Home and
/// the player):
/// - EpisodeHero: the artwork rounded and centered on a wash of its color,
///   the date, the title, the show in the accent, genre · length;
/// - EpisodeActionsBar: Listen, save, download, share, centered;
/// - WhyListenBox: the notes' first sentence in a soft box;
/// - Show notes: the rest of them;
/// - ChaptersSection, when the notes list chapters;
/// - FromTheShowRow and MoreFromShowSection, when the show is known.
/// Sections with nothing to show aren't drawn.
struct EpisodeDetailView: View {

    let viewModel: EpisodeDetailViewModel
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
                    onOpenShow: viewModel.podcast.map { podcast in { onOpenPodcast(podcast) } }
                )

                VStack(alignment: .leading, spacing: 28) {
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
                                .font(.body)
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

                    if !viewModel.moreEpisodes.isEmpty {
                        MoreFromShowSection(
                            showName: viewModel.podcast?.trackName ?? episode.author,
                            showArtwork: viewModel.podcast?.artworkUrl600,
                            episodes: viewModel.moreEpisodes,
                            onOpen: onOpenEpisode
                        )
                        .transition(.opacity)
                    }
                }
                .foregroundStyle(AppColor.Text.primary)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 32)
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
