//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// Home, laid out like a film magazine's app (after MUBI's):
/// 1. Your shows (always on top): the podcasts you follow, as small square
///    covers with their names; new episodes peek out from behind them.
/// 2. The feed (HomeFeed): one column of cards edge to edge, the
///    Episode of the day first, then the followed shows' new episodes,
///    Continue listening in mustard, a show to follow and the picks from
///    your interests, mixed so nothing shows twice.
/// Following nothing yet: an invitation to search above the feed.
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.playerManager) private var playerManager
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.interestsManager) private var interests

    /// Owned by HomeController: the Library button in the navigation bar
    /// reads the same episodes. Loaded here, as follows change.
    let followingFeed: FollowingFeedViewModel
    /// Owned by the view: the picks stay while Home lives.
    @State private var forYou = ForYouViewModel(cache: .standard)

    let onOpenPodcast: (Podcast) -> Void
    /// The section says which card the episode zooms out of and back into.
    let onOpenEpisode: (Episode, Podcast, ZoomID.Section) -> Void
    /// An episode with no podcast at hand (Continue listening).
    let onOpenPlayedEpisode: (Episode) -> Void
    let onOpenLibrary: (LibraryTab) -> Void
    let onSearch: () -> Void
    let onOpenFollowing: () -> Void

    private var following: [Podcast] { favoritesManager.favorites }

    private var feedItems: [HomeFeedItem] {
        HomeFeed.build(
            newEpisodes: InboxFeed.items(following: following, episodes: followingFeed.episodesByPodcast),
            newSince: InboxSeen.shared.lastSeen,
            picks: forYou.visibleItems(excluding: Set(following.map(\.trackId))),
            unfinished: HomeFeed.unfinished(recentlyPlayed.items)
        )
    }

    var body: some View {
        let items = feedItems

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if following.isEmpty {
                    emptyState
                        .padding(.bottom, 28)
                } else {
                    showsStrip
                        .padding(.bottom, 18)
                }

                if items.isEmpty, forYou.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: EpisodeOfTheDayCard.minHeight)
                } else {
                    HomeFeedList(
                        items: items,
                        onOpenEpisode: { episode, podcast in onOpenEpisode(episode, podcast, .feed) },
                        // ▶ plays (or pauses) in the mini player, opening nothing.
                        onPlay: { episode in playerManager.playOrToggle(episode, presentation: .mini) },
                        onOpenPodcast: onOpenPodcast,
                        onOpenPlayed: { played in onOpenPlayedEpisode(played.episode) },
                        onResume: { played in resume(played) },
                        onRemovePlayed: { played in remove(played) }
                    )
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
        .animation(AppAnimation.listChange, value: items.map(\.id))
        // Reload when you follow or unfollow a podcast.
        .task(id: following.map(\.trackId)) {
            followingFeed.load(following: following)
        }
        // "Updating" in the status pill while the feeds are read.
        .onChange(of: followingFeed.isLoading, initial: true) { _, loading in
            StatusCenter.shared.isUpdating = loading
        }
        // The picks depend on the interests (and skip what you follow).
        .task(id: interests.genreIDs) {
            forYou.load(interests: interests.genres, following: following)
        }
    }

    // MARK: - Your shows

    /// The podcasts you follow, as small square covers with their names;
    /// the See All tile at the end (only when they overflow) opens Following.
    private var showsStrip: some View {
        LibraryCovers(
            podcasts: following,
            newEpisodes: NewEpisodeMarks.newEpisodes(
                podcasts: following,
                episodes: followingFeed.episodesByPodcast,
                inboxSeen: InboxSeen.shared.lastSeen,
                showSeen: ShowSeen.shared.lastSeen
            ),
            onOpen: onOpenPodcast,
            onSeeAll: onOpenFollowing
        )
    }

    // MARK: - Continue listening

    /// From where it was left; the one in the player pauses or goes on.
    private func resume(_ item: RecentlyPlayed) {
        if playerManager.currentEpisode?.streamUrl == item.episode.streamUrl {
            playerManager.togglePlayPause()
        } else {
            playerManager.play(item.episode, from: item.resumeProgress)
        }
    }

    private func remove(_ item: RecentlyPlayed) {
        withAnimation(AppAnimation.listChange) { recentlyPlayed.remove(item) }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColor.accentInk)
                .accessibilityHidden(true)
            Text("Nothing followed yet")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
            Text("Follow a podcast and its new episodes will show up here.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)
            Button(action: onSearch) {
                Label("Search podcasts", systemImage: "magnifyingglass")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.Text.inverse)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppColor.Accent.strong))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 24)
    }
}
