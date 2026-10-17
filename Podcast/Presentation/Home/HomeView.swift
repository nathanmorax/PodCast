//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// "Library", the main screen. Everything fits on one screen:
/// 1. Collections: Following, Favorites, Downloads, as three small tiles.
/// 2. The podcasts you follow, as a row of covers (no text).
/// 3. For you: the latest episodes of the podcasts you follow.
/// What you're listening to lives in the mini player, so it isn't repeated here.
struct HomeView: View {

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.playerManager) private var playerManager

    /// Owned by the view: created once, keeps its results while Library lives.
    @State private var forYou = ForYouViewModel()

    let onOpenPodcast: (Podcast) -> Void
    let onSearch: () -> Void
    let onOpenFollowing: () -> Void
    let onOpenFavorites: () -> Void
    let onOpenDownloads: () -> Void

    private var following: [Podcast] { favoritesManager.favorites }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                collectionsSection

                if following.isEmpty {
                    emptyState
                } else {
                    FollowingCovers(podcasts: following, onOpen: onOpenPodcast)
                    forYouSection
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: following.map(\.trackId))
        // Reload when you follow or unfollow a podcast.
        .task(id: following.map(\.trackId)) {
            forYou.load(following: following)
        }
    }

    // MARK: - For you

    /// The latest episodes of the podcasts you follow, in one row.
    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("For you")
                .padding(.horizontal, 20)

            if forYou.items.isEmpty && forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .padding(.horizontal, 20)
            } else {
                ForYouEpisodesRow(
                    items: forYou.items,
                    onPlay: { playerManager.play($0) },
                    onOpenPodcast: onOpenPodcast
                )
            }
        }
        .animation(AppAnimation.listChange, value: forYou.items.map(\.id))
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
            Text("Nothing followed yet")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
            Text("Follow a podcast and its new episodes will show up here.")
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
        .padding(.top, 24)
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

// MARK: - For you episodes

/// Big covers with the episode inside: "7 hours ago · 25 min" and its title.
/// Tap plays it; the context menu goes to its podcast.
private struct ForYouEpisodesRow: View {

    let items: [ForYouViewModel.Item]
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void

    private static let side: CGFloat = 180

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    Button {
                        onPlay(item.episode)
                    } label: {
                        EpisodeCover(item: item, side: Self.side)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Go to podcast", systemImage: "square.stack") {
                            onOpenPodcast(item.podcast)
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

private struct EpisodeCover: View {

    let item: ForYouViewModel.Item
    let side: CGFloat

    var body: some View {
        Color.clear
            .frame(width: side, height: side)
            .overlay { PodcastImage(source: item.episode.imageUrl ?? item.podcast.artworkUrl600) }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    // "7 hours ago · 25 min"
                    HStack(spacing: 0) {
                        Text(item.episode.pubDate, format: .relative(presentation: .numeric, unitsStyle: .wide))
                        Text(verbatim: " · \(item.episode.durationDisplayText)")
                    }
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    Text(item.episode.title)
                        .font(AppFont.itemTitle)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                // The fade keeps the text readable on any artwork.
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.75)],
                                   startPoint: .top, endPoint: .bottom)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: CoverStyle.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("Plays the episode")
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
    .environment(\.playerManager, .preview)
}
