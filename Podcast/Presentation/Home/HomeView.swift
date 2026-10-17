//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// "Library", the main screen. Everything fits on one screen:
/// 1. The podcasts you follow, as a row of covers (no text).
/// 2. For you: ONE recommendation mixed from your genres.
/// 3. Collections: Following, Favorites, Downloads.
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
                    if !following.isEmpty {
                        FollowingCovers(podcasts: following, onOpen: onOpenPodcast)
                    }

                    if !interests.genres.isEmpty {
                        forYouSection
                    }

                    collectionsSection
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

    /// One podcast, picked from the mix of your genres. "Edit" reopens the
    /// genres screen.
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

            if let podcast = forYou.recommendation {
                Button {
                    onOpenPodcast(podcast)
                } label: {
                    RecommendationRow(podcast: podcast)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            } else if forYou.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .padding(.horizontal, 20)
        .animation(AppAnimation.stateChange, value: forYou.recommendation?.trackId)
    }

    // MARK: - Collections

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Collections")
            VStack(spacing: 10) {
                CollectionRow(title: "Following", systemImage: "square.stack", action: onOpenFollowing)
                CollectionRow(title: "Favorites", systemImage: "heart.fill", action: onOpenFavorites)
                CollectionRow(title: "Downloads", systemImage: "arrow.down", action: onOpenDownloads)
            }
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
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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

// MARK: - Recommendation

/// Big cover, name, "artist · genre". No card around it.
private struct RecommendationRow: View {

    let podcast: Podcast

    private var subtitle: String {
        [podcast.artistName, podcast.primaryGenreName]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 14) {
            Color.clear
                .frame(width: 120, height: 120)
                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(podcast.trackName ?? "")
                    .font(AppFont.sheetTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Collection row

/// A collection: violet icon and name on a rounded surface. No counts, no ›.
private struct CollectionRow: View {

    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(AppColor.Surface.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
