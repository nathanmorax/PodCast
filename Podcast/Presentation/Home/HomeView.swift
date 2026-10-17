//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// "Library", the main screen. Three things, always the same size:
/// 1. A pile of what's new from the podcasts you follow (swipe for the next).
/// 2. Your collections: Following, Favorites, Downloads.
/// 3. For you: one row mixing your genres (not one row per genre).
/// What you're listening to lives in the mini player, so it isn't repeated here.
struct HomeView: View {

    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.playerManager) private var playerManager
    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.interestsManager) private var interests
    @Environment(\.downloadManager) private var downloadManager

    /// Owned by the view: created once, they keep their results while Library lives.
    @State private var newEpisodes = NewEpisodesViewModel()
    @State private var forYou = ForYouViewModel()

    let onOpenPodcast: (Podcast) -> Void
    let onSearch: () -> Void
    let onOpenFollowing: () -> Void
    let onOpenFavorites: () -> Void
    let onOpenDownloads: () -> Void

    /// Saved episodes, only for the count next to "Favorites".
    private let bookmarks = BookMarkEpisodeManager.shared

    private var following: [Podcast] { favoritesManager.favorites }

    private var isEmpty: Bool {
        following.isEmpty && interests.genres.isEmpty
    }

    /// Reload the pile when what you follow, or what you've played, changes.
    private struct NewKey: Hashable {
        let followingIDs: [Int]
        let played: Set<String>
    }

    private var newKey: NewKey {
        NewKey(followingIDs: following.map(\.trackId), played: Set(recentlyPlayed.items.map(\.id)))
    }

    /// Reload "For you" when the chosen genres or what you follow change.
    private struct ForYouKey: Hashable {
        let genreIDs: [String]
        let followingIDs: Set<Int>
    }

    private var forYouKey: ForYouKey {
        ForYouKey(genreIDs: interests.genreIDs, followingIDs: Set(following.map(\.trackId)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if isEmpty {
                    emptyState
                } else {
                    if !newEpisodes.items.isEmpty {
                        NewEpisodesPile(
                            items: newEpisodes.items,
                            onOpenPodcast: onOpenPodcast,
                            onPlay: { playerManager.play($0) }
                        )
                        .transition(.opacity)
                    }

                    collections

                    if !interests.genres.isEmpty {
                        forYouSection
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: newEpisodes.items.map(\.id))
        .animation(AppAnimation.listChange, value: forYou.podcasts.map(\.trackId))
        .task(id: newKey) {
            newEpisodes.load(following: following, played: newKey.played)
        }
        .task(id: forYouKey) {
            forYou.load(genres: interests.genres, excluding: forYouKey.followingIDs)
        }
    }

    // MARK: - Collections

    /// Plain rows: icon, name, count, ›. Each opens its list.
    private var collections: some View {
        VStack(spacing: 0) {
            CollectionRow(title: "Following", systemImage: "square.stack",
                          count: following.count, action: onOpenFollowing)
            CollectionRow(title: "Favorites", systemImage: "heart",
                          count: bookmarks.episodes.count, action: onOpenFavorites)
            CollectionRow(title: "Downloads", systemImage: "arrow.down.circle",
                          count: downloadManager.downloadedEpisodes.count, action: onOpenDownloads,
                          showsSeparator: false)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - For you

    /// One row mixing the genres picked in onboarding. "Edit" reopens that screen.
    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("For you")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Edit") {
                    withAnimation(AppAnimation.onboarding) { interests.edit() }
                }
                .font(AppFont.link)
                .foregroundStyle(AppColor.lavenderInk)
                .accessibilityLabel("Edit interests")
            }
            .padding(.horizontal, 20)

            if forYou.podcasts.isEmpty && forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(forYou.podcasts, id: \.trackId) { podcast in
                            Button {
                                onOpenPodcast(podcast)
                            } label: {
                                PodcastTile(podcast: podcast)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColor.lavenderInk)
                .accessibilityHidden(true)
            Text("Your library is empty")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
            Text("Search for a podcast and follow it. Its new episodes will show up here.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)
            Button(action: onSearch) {
                Label("Search podcasts", systemImage: "magnifyingglass")
                    .font(AppFont.link)
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
        .padding(.top, 48)
    }
}

// MARK: - Collection row

/// A collection as a plain row: violet icon, name, count in gray, ›.
private struct CollectionRow: View {

    let title: LocalizedStringKey
    let systemImage: String
    let count: Int
    let action: () -> Void
    var showsSeparator = true

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)
                Spacer(minLength: 0)
                Text(count, format: .number)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.secondary)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.Text.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(AppColor.Text.tertiary.opacity(0.5))
                    .frame(height: 1 / displayScale)
                    .padding(.leading, 38)
            }
        }
        .animation(AppAnimation.stateChange, value: count)
    }
}

// MARK: - Preview

#Preview {
    HomeView(
        onOpenPodcast: { _ in },
        onSearch: {},
        onOpenFollowing: {},
        onOpenFavorites: {},
        onOpenDownloads: {}
    )
    .environment(\.recentlyPlayed, .preview)
    .environment(\.playerManager, .preview)
    .environment(\.favoritesManager, .preview)
    .environment(\.interestsManager, .preview)
    .environment(\.downloadManager, .preview)
}
