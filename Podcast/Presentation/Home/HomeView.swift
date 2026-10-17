//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// "Library", the main screen. Everything fits on one screen:
/// 1. Collections: Following, Favorites, Downloads, as three small tiles.
/// 2. The podcasts you follow, as a row of covers (no text).
/// 3. For you: one row of big covers with the name inside, mixed from your genres.
/// What you're listening to lives in the mini player, so it isn't repeated here.
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.interestsManager) private var interests

    /// Owned by the view: created once, keeps its results while Library lives.
    @State private var forYou = ForYouViewModel()

    let onOpenPodcast: (Podcast) -> Void
    let onSearch: () -> Void
    let onOpenFollowing: () -> Void
    let onOpenFavorites: () -> Void
    let onOpenDownloads: () -> Void

    private var following: [Podcast] { favoritesManager.favorites }

    private var isEmpty: Bool {
        following.isEmpty && interests.genres.isEmpty
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
            VStack(alignment: .leading, spacing: 32) {
                if isEmpty {
                    emptyState
                } else {
                    collectionsSection

                    if !following.isEmpty {
                        FollowingCovers(podcasts: following, onOpen: onOpenPodcast)
                    }

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
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
        .task(id: forYouKey) {
            forYou.load(genres: interests.genres, excluding: forYouKey.followingIDs)
        }
    }

    // MARK: - For you

    /// A few podcasts from the mix of your genres, in one row. "Edit" reopens
    /// the genres screen.
    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("For you")
                Spacer()
                Button("Edit") {
                    withAnimation(AppAnimation.onboarding) { interests.edit() }
                }
                .font(AppFont.link)
                .foregroundStyle(AppColor.lavenderInk)
                .accessibilityLabel("Edit interests")
            }
            .padding(.horizontal, 20)

            if forYou.recommendations.isEmpty && forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .padding(.horizontal, 20)
            } else {
                RecommendationsRow(podcasts: forYou.recommendations, onOpen: onOpenPodcast)
            }
        }
        .animation(AppAnimation.listChange, value: forYou.recommendations.map(\.trackId))
    }

    // MARK: - Collections

    /// Three small tiles in a row. Each opens its list.
    private var collectionsSection: some View {
        HStack(spacing: 10) {
            CollectionTile(title: "Following", systemImage: "square.stack.3d.up", action: onOpenFollowing)
            CollectionTile(title: "Favorites", systemImage: "bookmark", action: onOpenFavorites)
            CollectionTile(title: "Downloads", systemImage: "arrow.down.to.line", action: onOpenDownloads)
        }
        .padding(.horizontal, 20)
    }

    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(AppFont.sectionTitle)
            .foregroundStyle(AppColor.Text.primary)
            .accessibilityAddTraits(.isHeader)
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
            Text("Search for a podcast and follow it. It'll show up here.")
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

// MARK: - Following covers

/// The podcasts you follow: big covers only (VoiceOver reads the names).
private struct FollowingCovers: View {

    let podcasts: [Podcast]
    let onOpen: (Podcast) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        Color.clear
                            .frame(width: 104, height: 104)
                            .overlay { PodcastImage(source: podcast.artworkUrl600) }
                            .clipShape(RoundedRectangle(cornerRadius: CoverStyle.cornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: podcast.trackName ?? ""))
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

// MARK: - Covers

/// Every cover in Library: barely rounded, so the artwork reads as a square.
private enum CoverStyle {
    static let cornerRadius: CGFloat = 10
}

// MARK: - Recommendations

/// Big covers with the name inside, over a dark fade, in one horizontal row.
private struct RecommendationsRow: View {

    let podcasts: [Podcast]
    let onOpen: (Podcast) -> Void

    private static let side: CGFloat = 180

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        RecommendationCover(podcast: podcast, side: Self.side)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

private struct RecommendationCover: View {

    let podcast: Podcast
    let side: CGFloat

    var body: some View {
        Color.clear
            .frame(width: side, height: side)
            .overlay { PodcastImage(source: podcast.artworkUrl600) }
            .overlay(alignment: .bottomLeading) {
                Text(podcast.trackName ?? "")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // The fade keeps the name readable on any artwork.
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.7)],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: CoverStyle.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
    }
}

// MARK: - Collection tile

/// A small tile: violet icon on top, name under it.
private struct CollectionTile: View {

    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.Accent.strong)
                    .accessibilityHidden(true)
                Text(title)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.Surface.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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
    .environment(\.favoritesManager, .preview)
    .environment(\.interestsManager, .preview)
}
