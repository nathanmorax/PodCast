//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// Home, laid out like a magazine's audio front page. Each section has one
/// job, so nothing shows twice:
/// 1. Your shows (always on top): the podcasts you follow, as square
///    covers; new episodes peek out from behind their show's cover.
/// 2. Continue listening: what you started and didn't finish, as compact
///    rows with a progress ring (finished ones: Library › History).
/// 3. New episodes: the followed shows' newest, as big cards to play right
///    away ("Show all": Library › New).
/// 4. Selected for you: discovery from your interests.
/// Following nothing yet: an invitation to search instead of 1 and 3.
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.playerManager) private var playerManager
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.interestsManager) private var interests

    /// Owned by HomeController: the Library button in the navigation bar
    /// reads the same episodes. Loaded here, as follows change.
    let followingFeed: FollowingFeedViewModel
    /// Owned by the view: "Selected for you" stays while Library lives.
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

    /// Started and not finished, last played first.
    private var unfinished: [RecentlyPlayed] {
        ContinueListeningSection.unfinished(recentlyPlayed.items)
    }

    /// The followed shows' recent episodes, newest first.
    private var newEpisodes: [PodcastEpisode] {
        InboxFeed.items(following: following, episodes: followingFeed.episodesByPodcast)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                if following.isEmpty {
                    emptyState
                } else {
                    librarySection
                }

                if !unfinished.isEmpty {
                    ContinueListeningSection(
                        items: unfinished,
                        onResume: resume,
                        onOpen: { onOpenPlayedEpisode($0.episode) },
                        onRemove: remove,
                        onShowAll: { onOpenLibrary(.history) }
                    )
                    .transition(.opacity)
                }

                if !following.isEmpty, !newEpisodes.isEmpty {
                    NewEpisodesCarousel(
                        items: newEpisodes,
                        onOpen: { onOpenEpisode($0.episode, $0.podcast, .newEpisodes) },
                        // ▶ plays (or pauses) in the mini player, opening nothing.
                        onPlay: play,
                        onOpenPodcast: onOpenPodcast,
                        onShowAll: { onOpenLibrary(.new) }
                    )
                    .transition(.opacity)
                }

                selectedForYouSection
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
        .animation(AppAnimation.listChange, value: unfinished.map(\.id))
        .animation(AppAnimation.listChange, value: newEpisodes.isEmpty)
        // Reload when you follow or unfollow a podcast.
        .task(id: following.map(\.trackId)) {
            followingFeed.load(following: following)
        }
        // "Updating" in the status pill while the feeds are read.
        .onChange(of: followingFeed.isLoading, initial: true) { _, loading in
            StatusCenter.shared.isUpdating = loading
        }
        // "Selected for you" depends on the interests (and skips what you follow).
        .task(id: interests.genreIDs) {
            forYou.load(interests: interests.genres, following: following)
        }
    }

    private func play(_ episode: Episode) {
        playerManager.playOrToggle(episode, presentation: .mini)
    }

    // MARK: - Selected for you

    /// Podcasts you don't follow yet, from your interests: discovery. What
    /// you follow is in Your shows and New episodes; what you started, in
    /// Continue listening.
    @ViewBuilder
    private var selectedForYouSection: some View {
        let items = forYou.visibleItems(excluding: Set(following.map(\.trackId)))
        if !items.isEmpty {
            SelectedForYouList(
                items: items,
                onOpen: { onOpenEpisode($0.episode, $0.podcast, .forYou) },
                onPlay: play,
                onOpenPodcast: onOpenPodcast
            )
            .animation(AppAnimation.listChange, value: items.map(\.id))
        } else if forYou.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        }
    }

    // MARK: - Your shows

    /// The podcasts you follow, as square covers; the See All tile at the
    /// end (only when they overflow) opens Following.
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // No "Show all" up here: the row ends with a See All tile when
            // the covers don't all fit.
//            LibrarySectionHeader(title: "Library")
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
