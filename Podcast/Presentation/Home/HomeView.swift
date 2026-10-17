//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// "Inicio": pick up where you left off, your podcasts, and what you played.
struct HomeView: View {

    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.playerManager) private var playerManager
    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.interestsManager) private var interests

    /// Owned by the view: created once, keeps its results while Home lives.
    @State private var forYou = ForYouViewModel()

    let onOpenPodcast: (Podcast) -> Void
    let onSearch: () -> Void
    /// "Following" under the title: the podcasts you follow.
    let onOpenFollowing: () -> Void
    /// "Favorites" under the title: the episodes you saved.
    let onOpenFavorites: () -> Void

    /// Saved episodes, only for the count next to "Favorites".
    private let bookmarks = BookMarkEpisodeManager.shared

    private var favorites: [Podcast] { favoritesManager.favorites }

    /// The most recent episode that isn't finished.
    private var continueItem: RecentlyPlayed? {
        recentlyPlayed.items.first { $0.progress < 0.98 }
    }

    private var otherRecents: [RecentlyPlayed] {
        Array(recentlyPlayed.items.filter { $0.id != continueItem?.id }.prefix(10))
    }

    private var isEmpty: Bool {
        recentlyPlayed.items.isEmpty && favorites.isEmpty && interests.genres.isEmpty
    }

    /// Reload "For you" when the chosen genres or the favorites change.
    private struct ForYouKey: Hashable {
        let genreIDs: [String]
        let favoriteIDs: Set<Int>
    }

    private var forYouKey: ForYouKey {
        ForYouKey(genreIDs: interests.genreIDs, favoriteIDs: Set(favorites.map(\.trackId)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header

                if let item = continueItem {
                    section("Continue listening") {
                        ContinueListeningCard(item: item)
                            .padding(.horizontal, 20)
                    }
                }
                
                if !otherRecents.isEmpty {
                    section("Recently played") { recentsRow }
                }

                if !interests.genres.isEmpty {
                    forYouSection
                }

                if isEmpty {
                    emptyState
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: recentlyPlayed.items.map(\.id))
        .animation(AppAnimation.listChange, value: forYou.rows.map(\.id))
        .task(id: forYouKey) {
            forYou.load(genres: interests.genres, excluding: forYouKey.favoriteIDs)
        }
    }

    // MARK: - For you

    /// One row per genre picked in onboarding. "Edit" reopens that screen.
    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 22) {
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

            if forYou.rows.isEmpty && forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            }

            ForEach(forYou.rows) { row in
                VStack(alignment: .leading, spacing: 10) {
                    Text(row.genre.name)
                        .font(AppFont.overline)
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(AppColor.lavenderInk)
                        .padding(.horizontal, 20)
                    podcastRow(row.podcasts)
                }
            }
        }
    }

    private func podcastRow(_ podcasts: [Podcast]) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(podcasts, id: \.trackId) { podcast in
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

    // MARK: - Header

    /// Under the title "Home" (the navigation bar's): two violet links,
    /// Following and Favorites, each with its count. Then today's date.
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 18) {
                libraryLink("Following", count: favorites.count, action: onOpenFollowing)
                libraryLink("Favorites", count: bookmarks.episodes.count, action: onOpenFavorites)
            }

            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(AppFont.overline)
                .foregroundStyle(AppColor.Text.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 20)
    }

    /// Plain text: the name in violet, the count in gray. Opens its list.
    private func libraryLink(_ title: LocalizedStringKey, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title)
                    .font(AppFont.link)
                    .foregroundStyle(AppColor.Text.link)
                Text(count, format: .number)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.secondary)
                    .contentTransition(.numericText())
            }
            .padding(.vertical, 6) // a comfortable tap target
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.stateChange, value: count)
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
                .padding(.horizontal, 20)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    // MARK: - Rows

    private var favoritesRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(favorites, id: \.trackId) { podcast in
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

    private var recentsRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(otherRecents) { item in
                    Button {
                        playerManager.play(item.episode)
                    } label: {
                        RecentUpdateCard(item: item)
                            .frame(width: 150)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Remove from recents", systemImage: "minus.circle", role: .destructive) {
                            withAnimation(AppAnimation.listChange) { recentlyPlayed.remove(item) }
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColor.lavenderInk)
                .accessibilityHidden(true)
            Text("Your home is empty")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
            Text("Search for a podcast and start listening. You'll pick it up here right where you left off.")
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

// MARK: - Preview

#Preview {
    HomeView(
        onOpenPodcast: { _ in },
        onSearch: {},
        onOpenFollowing: {},
        onOpenFavorites: {}
    )
    .environment(\.recentlyPlayed, .preview)
    .environment(\.playerManager, .preview)
    .environment(\.favoritesManager, .preview)
    .environment(\.interestsManager, .preview)
}
