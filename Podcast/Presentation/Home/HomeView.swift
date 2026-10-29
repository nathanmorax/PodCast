//
//  HomeView.swift
//  Podcast
//

import SwiftUI

<<<<<<< Updated upstream
/// "Library", the main screen (no title on top: the first section's name,
/// "Library", is the title):
/// 1. Library: the podcasts you follow, as square covers with their names.
/// 2. Today's date, and Following · Favorites · Downloads as three rows.
/// 3. Recently played: big cards, one per page, the one playing now first
///    (its artwork moves while it plays).
/// 4. For you: the latest episodes of the podcasts you follow.
/// 5. Browse podcasts: category chips and a row of shows; "Show all" opens
///    the interests picker.
=======
/// Home, laid out like a film magazine's app (after MUBI's):
/// 1. Your shows (always on top): the podcasts you follow, as small square
///    covers with their names; new episodes peek out from behind them.
/// 2. The feed (HomeFeed): one column of cards edge to edge, the
///    Episode of the day first, then the followed shows' new episodes,
///    Continue listening in mustard, a show to follow and the picks from
///    your interests, mixed so nothing shows twice.
/// Following nothing yet: an invitation to search above the feed.
>>>>>>> Stashed changes
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.playerManager) private var playerManager
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.bookmarks) private var bookmarks
    @Environment(\.downloadManager) private var downloadManager
    @Environment(\.interestsManager) private var interests

    /// Owned by HomeController: the Inbox button in the navigation bar reads
    /// the same episodes. Loaded here, as follows change.
    let followingFeed: FollowingFeedViewModel
<<<<<<< Updated upstream
    /// Owned by the view: "For you" stays while Library lives.
=======
    /// Owned by the view: the picks stay while Home lives.
>>>>>>> Stashed changes
    @State private var forYou = ForYouViewModel(cache: .standard)
    /// Owned by the view: each category's shows stay while Library lives.
    @State private var browse = BrowseViewModel()

    let onOpenPodcast: (Podcast) -> Void
    let onOpenEpisode: (Episode, Podcast) -> Void
    /// An episode with no podcast at hand (Recently played).
    let onOpenPlayedEpisode: (Episode) -> Void
    let onSearch: () -> Void
    let onOpenFollowing: () -> Void
    let onOpenFavorites: () -> Void
    let onOpenDownloads: () -> Void

    private var following: [Podcast] { favoritesManager.favorites }

<<<<<<< Updated upstream
    /// Recently played, the one in the player included (its card shows it
    /// playing).
    private var played: [RecentlyPlayed] {
        recentlyPlayed.items
=======
    private var feed: [HomeFeedItem] {
        HomeFeed.build(
            newEpisodes: InboxFeed.items(following: following, episodes: followingFeed.episodesByPodcast),
            newSince: InboxSeen.shared.lastSeen,
            picks: forYou.visibleItems(excluding: Set(following.map(\.trackId))),
            unfinished: HomeFeed.unfinished(recentlyPlayed.items)
        )
>>>>>>> Stashed changes
    }

    var body: some View {
        let feed = self.feed

        ScrollView {
<<<<<<< Updated upstream
            VStack(alignment: .leading, spacing: 32) {
                if !following.isEmpty {
                    librarySection
                }


                if !played.isEmpty {
                    recentlyPlayedSection
                        .transition(.opacity)
                }

                if following.isEmpty {
                    emptyState
                }

                forYouSection

//                BrowsePodcastsSection(
//                    viewModel: browse,
//                    interests: interests.genres,
//                    onOpenPodcast: onOpenPodcast,
//                    onShowAll: { interests.edit() }
//                )
=======
            VStack(alignment: .leading, spacing: 0) {
                if following.isEmpty {
                    emptyState
                        .padding(.bottom, 28)
                } else {
                    showsStrip
                        .padding(.bottom, 18)
                }

                if feed.isEmpty, forYou.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: EpisodeOfTheDayCard.minHeight)
                } else {
                    HomeFeedList(
                        items: feed,
                        onOpenEpisode: { onOpenEpisode($0, $1, .feed) },
                        // ▶ plays (or pauses) in the mini player, opening nothing.
                        onPlay: { playerManager.playOrToggle($0, presentation: .mini) },
                        onOpenPodcast: onOpenPodcast,
                        onOpenPlayed: { onOpenPlayedEpisode($0.episode) },
                        onResume: resume,
                        onRemovePlayed: remove
                    )
                }
>>>>>>> Stashed changes
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
<<<<<<< Updated upstream
        .animation(AppAnimation.listChange, value: played.map(\.id))
=======
        .animation(AppAnimation.listChange, value: feed.map(\.id))
>>>>>>> Stashed changes
        // Reload when you follow or unfollow a podcast.
        .task(id: following.map(\.trackId)) {
            followingFeed.load(following: following)
        }
        // "Updating" in the status pill while the feeds are read.
        .onChange(of: followingFeed.isLoading, initial: true) { _, loading in
            StatusCenter.shared.isUpdating = loading
        }
<<<<<<< Updated upstream
        // "For you" depends on the interests (and skips what you follow).
=======
        // The picks depend on the interests (and skip what you follow).
>>>>>>> Stashed changes
        .task(id: interests.genreIDs) {
            forYou.load(interests: interests.genres, following: following)
        }
    }

<<<<<<< Updated upstream
    // MARK: - Recently played

    /// Every episode played as a big card, one per page (newest first).
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LibrarySectionHeader(title: "Recently played")

            RecentlyPlayedCarousel(
                items: played,
                onResume: resume,
                onOpen: { onOpenPlayedEpisode($0.episode) },
                onRemove: remove
            )
        }
    }

    /// From where it was left (finished ones start over).
    private func resume(_ item: RecentlyPlayed) {
        playerManager.play(item.episode, from: item.resumeProgress)
    }

    private func remove(_ item: RecentlyPlayed) {
        withAnimation(AppAnimation.listChange) { recentlyPlayed.remove(item) }
    }

    // MARK: - Library

    /// The podcasts you follow, as square covers; the See All tile at the
    /// end (only when they overflow) opens Following.
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // No "Show all" up here: the row ends with a See All tile when
            // the covers don't all fit.
            LibrarySectionHeader(title: "Library")
            LibraryCovers(podcasts: following, onOpen: onOpenPodcast, onSeeAll: onOpenFollowing)
        }
=======
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
>>>>>>> Stashed changes
    }

    // MARK: - For you

    /// Podcasts you don't follow yet, from your interests: discovery. What
    /// you follow is in the Inbox; what you started, in Recently played.
    @ViewBuilder
    private var forYouSection: some View {
        let items = forYou.visibleItems(excluding: Set(following.map(\.trackId)))
        if !items.isEmpty || forYou.isLoading {
            forYouContent(items)
        }
    }

    private func forYouContent(_ items: [PodcastEpisode]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            LibrarySectionHeader(title: "For you", subtitle: "Based on your interests")

            if items.isEmpty && forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: ForYouCard.placeholderHeight)
                    .padding(.horizontal, 20)
            } else {
                ForYouRow(
                    items: items,
                    onOpen: { onOpenEpisode($0.episode, $0.podcast) },
                    // ▶ plays (or pauses) in the mini player, opening nothing.
                    onPlay: { playerManager.playOrToggle($0, presentation: .mini) },
                    onOpenPodcast: onOpenPodcast
                )
            }
        }
        .animation(AppAnimation.listChange, value: items.map(\.id))
    }

    // MARK: - Date and collections

    /// Today's date under the title ("SATURDAY, OCTOBER 17").
    private var dateHeader: some View {
        Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
            .overlineStyle()
            .padding(.horizontal, 20)
    }

    /// Three rows, like a magazine's index: icon, name in serif, how many,
    /// and ›. Each opens its list.
    private var collectionsSection: some View {
        CollectionRows(
            following: following.count,
            favorites: bookmarks.episodes.count,
            downloads: downloadManager.downloadedEpisodes.count,
            onOpenFollowing: onOpenFollowing,
            onOpenFavorites: onOpenFavorites,
            onOpenDownloads: onOpenDownloads
        )
        .padding(.horizontal, 20)
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
