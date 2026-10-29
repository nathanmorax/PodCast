//
//  HomeFeedList.swift
//  Podcast
//

import SwiftUI

/// Home's feed drawn: the cards (HomeFeed) edge to edge, one under the
/// other with a thin gap, like a film magazine's app. Each image card is
/// what its episode zooms out of and back into.
struct HomeFeedList: View {

    let items: [HomeFeedItem]
    let onOpenEpisode: (Episode, Podcast) -> Void
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void
    let onOpenPlayed: (RecentlyPlayed) -> Void
    let onResume: (RecentlyPlayed) -> Void
    let onRemovePlayed: (RecentlyPlayed) -> Void

    /// The gap between cards.
    static let spacing: CGFloat = 6

    @Environment(\.playerManager) private var playerManager
    @Environment(\.favoritesManager) private var favoritesManager

    var body: some View {
        LazyVStack(spacing: Self.spacing) {
            ForEach(items) { item in
                card(item)
            }
        }
    }

    @ViewBuilder
    private func card(_ item: HomeFeedItem) -> some View {
        switch item {
        case .episodeOfTheDay(let episode):
            ZoomSourceHost(id: .episode(episode.episode.streamUrl, section: .feed)) {
                EpisodeOfTheDayCard(
                    item: episode,
                    isPlaying: isPlaying(episode.episode),
                    onOpen: { onOpenEpisode(episode.episode, episode.podcast) },
                    onListen: { onPlay(episode.episode) }
                )
            }

        case .episode(let episode, let tag):
            ZoomSourceHost(id: .episode(episode.episode.streamUrl, section: .feed)) {
                FeedEpisodeCard(
                    item: episode,
                    tag: tag,
                    onOpen: { onOpenEpisode(episode.episode, episode.podcast) },
                    onPlay: { onPlay(episode.episode) },
                    onOpenPodcast: { onOpenPodcast(episode.podcast) }
                )
            }

        case .continueListening(let played):
            ZoomSourceHost(id: .episode(played.episode.streamUrl, section: .recentlyPlayed)) {
                ContinueListeningCard(
                    item: played,
                    onResume: { onResume(played) },
                    onOpen: { onOpenPlayed(played) },
                    onRemove: { onRemovePlayed(played) }
                )
            }

        case .showSpotlight(let episode):
            ShowSpotlightCard(
                item: episode,
                isFollowing: favoritesManager.isFavorite(episode.podcast),
                onOpenPodcast: { onOpenPodcast(episode.podcast) },
                onToggleFollow: {
                    withAnimation(AppAnimation.selection) {
                        favoritesManager.toggleFavorite(episode.podcast)
                    }
                }
            )
        }
    }

    private func isPlaying(_ episode: Episode) -> Bool {
        playerManager.currentEpisode?.streamUrl == episode.streamUrl && playerManager.viewModel.isPlaying
    }
}
