//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// "Library", the main screen:
/// 1. Today's date, and Following · Favorites · Downloads as three rows.
/// 2. Recently played: what you listened to, with how far you got. The
///    episode playing now lives in the mini player, so it isn't repeated here.
/// 3. Library: the podcasts you follow, as round covers with their names.
/// 4. For you: the latest episodes of the podcasts you follow.
/// 5. Browse podcasts: category chips and a row of shows; "Show all" opens
///    the interests picker.
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.playerManager) private var playerManager
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.bookmarks) private var bookmarks
    @Environment(\.downloadManager) private var downloadManager
    @Environment(\.interestsManager) private var interests

    /// Owned by the view: created once, keeps its results while Library lives.
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

    /// Recently played, minus the one in the mini player.
    private var played: [RecentlyPlayed] {
        let current = playerManager.currentEpisode?.streamUrl
        return recentlyPlayed.items.filter { $0.id != current }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 14) {
                    dateHeader
                    collectionsSection
                }

                if !played.isEmpty {
                    recentlyPlayedSection
                        .transition(.opacity)
                }

                if following.isEmpty {
                    emptyState
                } else {
                    librarySection
                    forYouSection
                }

                BrowsePodcastsSection(
                    viewModel: browse,
                    interests: interests.genres,
                    onOpenPodcast: onOpenPodcast,
                    onShowAll: { interests.edit() }
                )
            }
            .padding(.top, 12)
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
        .animation(AppAnimation.listChange, value: played.map(\.id))
        // Reload when you follow or unfollow a podcast.
        .task(id: following.map(\.trackId)) {
            forYou.load(following: following)
        }
    }

    // MARK: - Recently played

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LibrarySectionHeader(title: "Recently played")

            RecentlyPlayedRow(
                items: played,
                onResume: { item in
                    // From where it was left (finished ones start over).
                    playerManager.play(item.episode, from: item.resumeProgress)
                },
                onOpen: { onOpenPlayedEpisode($0.episode) },
                onRemove: { item in
                    withAnimation(AppAnimation.listChange) { recentlyPlayed.remove(item) }
                }
            )
        }
    }

    // MARK: - Library

    /// The podcasts you follow, as circles; "Show all" opens Following.
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LibrarySectionHeader(title: "Library", onShowAll: onOpenFollowing)
            LibraryCircles(podcasts: following, onOpen: onOpenPodcast)
        }
    }

    // MARK: - For you

    /// The latest episodes of the podcasts you follow, in one row.
    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LibrarySectionHeader(title: "For you")

            if forYou.items.isEmpty && forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .padding(.horizontal, 20)
            } else {
                ForYouEpisodesRow(
                    items: forYou.items,
                    onOpen: { onOpenEpisode($0.episode, $0.podcast) },
                    onPlay: { playerManager.play($0) },
                    onOpenPodcast: onOpenPodcast
                )
            }
        }
        .animation(AppAnimation.listChange, value: forYou.items.map(\.id))
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

// MARK: - Preview

#Preview {
    HomeView(
        onOpenPodcast: { _ in },
        onOpenEpisode: { _, _ in },
        onOpenPlayedEpisode: { _ in },
        onSearch: {},
        onOpenFollowing: {},
        onOpenFavorites: {},
        onOpenDownloads: {}
    )
    .environment(\.favoritesManager, .preview)
    .environment(\.playerManager, .preview)
    .environment(\.recentlyPlayed, .preview)
    .environment(\.interestsManager, .preview)
}
