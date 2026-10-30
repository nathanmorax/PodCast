//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// Home, like a social app's feed:
/// 1. Your shows (always on top): the podcasts you follow, as rounded
///    covers with their names; new episodes peek out from behind them.
/// 2. For You · Following · Continue, pinned under them while you scroll.
/// 3. The chosen tab's posts: each episode with its show's avatar, name and
///    category, a big rounded image with a bookmark, its title and ▶.
/// Following nothing yet: an invitation to search above the tabs.
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.interestsManager) private var interests

    /// Owned by HomeController: the Library button in the navigation bar
    /// reads the same episodes. Loaded here, as follows change.
    let followingFeed: FollowingFeedViewModel
    /// Owned by the view: the picks stay while Home lives.
    @State private var forYou = ForYouViewModel(cache: .standard)
    @State private var tab: HomeTab = .forYou

    let onOpenPodcast: (Podcast) -> Void
    /// The section says which card the episode zooms out of and back into.
    let onOpenEpisode: (Episode, Podcast, ZoomID.Section) -> Void
    /// An episode with no podcast at hand (a half-listened one).
    let onOpenPlayedEpisode: (Episode) -> Void
    let onSearch: () -> Void
    let onOpenFollowing: () -> Void

    private var following: [Podcast] { favoritesManager.favorites }

    private var posts: [HomePost] {
        switch tab {
        case .forYou:
            HomePosts.posts(forYou.visibleItems(excluding: Set(following.map(\.trackId))))
        case .following:
            HomePosts.posts(InboxFeed.items(following: following, episodes: followingFeed.episodesByPodcast))
        case .continueListening:
            HomePosts.continuePosts(recentlyPlayed.items)
        }
    }

    var body: some View {
        let posts = self.posts

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                if following.isEmpty {
                    emptyState
                        .padding(.bottom, 24)
                } else {
                    showsStrip
                        .padding(.bottom, 14)
                }

                Section {
                    feed(posts)
                        .padding(.top, 18)
                } header: {
                    HomeTabBar(tab: $tab)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
        .animation(AppAnimation.listChange, value: posts.map(\.id))
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

    // MARK: - Feed

    @ViewBuilder
    private func feed(_ posts: [HomePost]) -> some View {
        if posts.isEmpty {
            if tab == .forYou, forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                emptyTab
                    .frame(maxWidth: .infinity, minHeight: 260)
            }
        } else {
            LazyVStack(spacing: 34) {
                ForEach(posts) { post in
                    HomePostCard(
                        post: post,
                        onOpen: { open(post) },
                        onOpenShow: post.podcast.map { podcast in { onOpenPodcast(podcast) } }
                    )
                }
            }
        }
    }

    private func open(_ post: HomePost) {
        if let podcast = post.podcast {
            onOpenEpisode(post.episode, podcast, post.section)
        } else {
            onOpenPlayedEpisode(post.episode)
        }
    }

    @ViewBuilder
    private var emptyTab: some View {
        switch tab {
        case .forYou:
            ContentUnavailableView(
                "Nothing picked yet",
                systemImage: "sparkles",
                description: Text("Choose what you like to listen to and picks will show up here.")
            )
        case .following:
            ContentUnavailableView(
                "No new episodes",
                systemImage: "tray",
                description: Text("New episodes from the podcasts you follow show up here.")
            )
        case .continueListening:
            ContentUnavailableView(
                "Nothing to continue",
                systemImage: "play.circle",
                description: Text("Episodes you leave halfway show up here.")
            )
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
