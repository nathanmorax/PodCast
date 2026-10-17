//
//  SearchPagesView.swift
//  Podcast
//

import SwiftUI

/// What the Search sheet shows before a catalog search: a picker
/// (Search · Following · Favorites) and the three pages, swiped sideways.
/// Pulling the sheet down still goes back Home (MainContainerController).
struct SearchPagesView: View {

    let navigator: AppNavigator
    let genresViewModel: GenresViewModel
    /// A recently searched podcast.
    let onOpenPodcast: (Podcast) -> Void
    /// A podcast from Following (not recorded as a recent search).
    let onOpenFollowed: (Podcast) -> Void
    let onSelectGenre: (Genre) -> Void

    var body: some View {
        // A paging ScrollView, not a page-style TabView: the TabView clipped
        // each page to the safe area, so nothing showed behind the picker or
        // the bottom bar. Here every list runs full height and scrolls behind
        // both (their glass shows it through).
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(SearchSection.allCases) { page in
                    pageView(page)
                        .containerRelativeFrame(.horizontal)
                        .id(page)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: visiblePage)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        // The picker floats over the pages: lists start below it and scroll
        // behind its glass.
        .safeAreaInset(edge: .top, spacing: 0) {
            SearchSectionPicker(selection: section)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 10)
        }
        .background(AppColor.screenBackground)
    }

    @ViewBuilder
    private func pageView(_ page: SearchSection) -> some View {
        switch page {
        case .explore:
            SearchExploreView(
                genresViewModel: genresViewModel,
                onOpenPodcast: onOpenPodcast,
                onSelectGenre: onSelectGenre
            )
        case .following:
            FollowingPage(query: navigator.searchQuery, onOpen: onOpenFollowed)
        case .favorites:
            FavoriteEpisodesPage(query: navigator.searchQuery)
        }
    }

    /// The page the horizontal scroll rests on, tied to the picker.
    private var visiblePage: Binding<SearchSection?> {
        Binding(
            get: { navigator.searchSection },
            set: { if let page = $0 { navigator.searchSection = page } }
        )
    }

    private var section: Binding<SearchSection> {
        Binding(
            get: { navigator.searchSection },
            set: { navigator.searchSection = $0 }
        )
    }
}

// MARK: - Picker

/// Three pills on a clear glass track; the selected one slides (same look
/// as the player's tabs).
struct SearchSectionPicker: View {

    @Binding var selection: SearchSection
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SearchSection.allCases) { section in
                button(section)
            }
        }
        .padding(3)
        // Clear glass, like the bottom bar: the list shows through.
        .glassEffect(.regular, in: Capsule())
        // Also animates when the page is swiped, not only tapped.
        .animation(AppAnimation.playerTab, value: selection)
    }

    private func button(_ section: SearchSection) -> some View {
        let isOn = selection == section
        return Button {
            // Animated: the pages slide to the chosen one.
            withAnimation(AppAnimation.screenSlide) { selection = section }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(section.title)
                    .font(AppFont.itemTitle)
                    .lineLimit(1)
            }
            .foregroundStyle(isOn ? AppColor.Text.primary : AppColor.Accent.strong)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background {
                if isOn {
                    Capsule()
                        .fill(AppColor.Surface.raised)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                        .matchedGeometryEffect(id: "pill", in: pill)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - Following

private struct FollowingPage: View {

    let query: String
    let onOpen: (Podcast) -> Void

    @Environment(\.favoritesManager) private var favoritesManager

    var body: some View {
        let podcasts = LocalSearch.podcasts(favoritesManager.favorites, matching: query)
        Group {
            if favoritesManager.favorites.isEmpty {
                SearchPageEmptyState(
                    systemImage: "square.stack",
                    title: "Nothing followed yet",
                    message: "Tap + on a podcast to follow it. It'll show up here."
                )
            } else if podcasts.isEmpty {
                SearchPageEmptyState(
                    systemImage: "magnifyingglass",
                    title: "No matches",
                    message: "Nothing you follow matches “\(query)”."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(podcasts.enumerated()), id: \.element.trackId) { index, podcast in
                            Button {
                                onOpen(podcast)
                            } label: {
                                SearchPageRow(
                                    imageSource: podcast.artworkUrl600,
                                    title: podcast.trackName ?? "",
                                    subtitle: [podcast.artistName, podcast.primaryGenreName]
                                        .compactMap { $0 }
                                        .joined(separator: " · "),
                                    showsSeparator: index < podcasts.count - 1
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Unfollow", systemImage: "minus.circle", role: .destructive) {
                                    withAnimation(AppAnimation.listChange) {
                                        favoritesManager.deleteFavorite(podcast)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(AppAnimation.listChange, value: podcasts.map(\.trackId))
    }
}

// MARK: - Favorites

private struct FavoriteEpisodesPage: View {

    let query: String

    @Environment(\.playerManager) private var playerManager
    private let bookmarks = BookMarkEpisodeManager.shared

    var body: some View {
        let episodes = LocalSearch.episodes(bookmarks.episodes, matching: query)
        Group {
            if bookmarks.episodes.isEmpty {
                SearchPageEmptyState(
                    systemImage: "heart",
                    title: "No favorites yet",
                    message: "Save an episode from its ••• menu and it'll show up here."
                )
            } else if episodes.isEmpty {
                SearchPageEmptyState(
                    systemImage: "magnifyingglass",
                    title: "No matches",
                    message: "None of your favorites match “\(query)”."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(episodes.enumerated()), id: \.element.streamUrl) { index, episode in
                            Button {
                                playerManager.play(episode)
                            } label: {
                                SearchPageRow(
                                    imageSource: episode.imageUrl,
                                    title: episode.title,
                                    subtitle: "\(episode.author) · \(episode.durationDisplayText)",
                                    showsPlay: true,
                                    showsSeparator: index < episodes.count - 1
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Remove from favorites", systemImage: "heart.slash", role: .destructive) {
                                    withAnimation(AppAnimation.listChange) {
                                        bookmarks.delete(episode)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(AppAnimation.listChange, value: episodes.map(\.streamUrl))
    }
}

// MARK: - Shared pieces

/// Cover, title, subtitle; a hairline separator, no card (like the episode list).
private struct SearchPageRow: View {

    let imageSource: String?
    let title: String
    let subtitle: String
    var showsPlay = false
    let showsSeparator: Bool

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 52, height: 52)
                .overlay { PodcastImage(source: imageSource) }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if showsPlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(width: 34, height: 34)
                    .background(AppColor.Accent.wash, in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(AppColor.Text.tertiary.opacity(0.5))
                    .frame(height: 1 / displayScale)
                    .padding(.leading, 84)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct SearchPageEmptyState: View {

    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.Accent.soft)
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)
            Text(message)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    SearchSectionPicker(selection: .constant(.following))
        .padding()
}
