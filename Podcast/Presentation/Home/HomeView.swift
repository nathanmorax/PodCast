//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// Home, like a classic podcast app's:
/// 1. The shows you follow (always on top): big rounded covers with their
///    name and maker; a green dot means new episodes. When they don't all
///    fit, the row ends with See All (Following).
/// 2. Recently played: what you last listened to, one card at a time
///    with dots, each with how far along and ▶. See All opens History.
/// 3. Latest Episodes: the newest of those shows, each with a line of what
///    it's about, ▶, how far along, save and ⋮. See All opens the Library.
/// 4. For You: picks from your interests, in the same rows.
/// Following nothing yet: an invitation to search, then For You.
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
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
    /// An episode with no podcast at hand (a recently played one).
    let onOpenPlayedEpisode: (Episode) -> Void
    let onOpenLibrary: (LibraryTab) -> Void
    let onSearch: () -> Void
    let onOpenFollowing: () -> Void

    private var following: [Podcast] { favoritesManager.favorites }

    var body: some View {
        let latest = HomeSections.latest(
            InboxFeed.items(following: following, episodes: followingFeed.episodesByPodcast)
        )
        let picks = HomeSections.picks(
            forYou.visibleItems(excluding: Set(following.map(\.trackId))),
            excluding: latest
        )
        let played = Dictionary(recentlyPlayed.items.map { ($0.id, $0) }) { first, _ in first }
        let recent = HomeSections.recentlyPlayed(recentlyPlayed.items)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if following.isEmpty {
                    emptyState
                        .padding(.bottom, 28)
                } else {
                    let marks = NewEpisodeMarks.newEpisodes(
                        podcasts: following,
                        episodes: followingFeed.episodesByPodcast,
                        inboxSeen: InboxSeen.shared.lastSeen,
                        showSeen: ShowSeen.shared.lastSeen
                    )
                    YourPodcastsRow(
                        podcasts: NewEpisodeMarks.newFirst(following, newEpisodes: marks),
                        newEpisodes: marks,
                        onOpen: onOpenPodcast,
                        onSeeAll: onOpenFollowing
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }

                if !recent.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HomeSectionHeader(title: "Recently played") { onOpenLibrary(.history) }
                            .padding(.horizontal, 20)
                        RecentlyPlayedCarousel(
                            items: recent,
                            onOpen: { onOpenPlayedEpisode($0.episode) },
                            onRemove: { item in
                                withAnimation(AppAnimation.listChange) { recentlyPlayed.remove(item) }
                            }
                        )
                    }
                    .padding(.bottom, 28)
                    .transition(.opacity)
                }

                if !latest.isEmpty {
                    episodeSection("Latest Episodes", items: latest, played: played) {
                        onOpenLibrary(.new)
                    }
                    .padding(.bottom, 20)
                }

                if !picks.isEmpty {
                    episodeSection("For You", items: picks, played: played, onSeeAll: nil)
                } else if forYou.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
        .animation(AppAnimation.listChange, value: latest.map(\.id))
        .animation(AppAnimation.listChange, value: recent.map(\.id))
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

    // MARK: - Episodes

    /// A title (with See All), then the episodes with a hairline between.
    private func episodeSection(
        _ title: LocalizedStringKey,
        items: [PodcastEpisode],
        played: [String: RecentlyPlayed],
        onSeeAll: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HomeSectionHeader(title: title, onSeeAll: onSeeAll)
            ForEach(items) { item in
                EpisodeListRow(
                    episode: item.episode,
                    artwork: item.feedArtwork,
                    showName: item.showName,
                    played: played[item.id]
                ) {
                    onOpenEpisode(item.episode, item.podcast, .feed)
                }
                if item.id != items.last?.id {
                    Divider()
                }
            }
        }
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
        .padding(.top, 8)
    }
}
