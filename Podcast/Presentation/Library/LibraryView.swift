//
//  LibraryView.swift
//  Podcast
//

import SwiftUI

/// The Library: every episode you have, in tabs (New · Saved · Downloads ·
/// History). A line slides under the chosen tab; a sideways swipe moves
/// to the next or previous one. Hosted by LibraryController.
///
/// One plain ScrollView (not a paging TabView): a TabView clips its pages
/// at the safe area, so nothing showed behind the mini player and the bar;
/// a ScrollView scrolls under them like every other list in the app.
struct LibraryView: View {

    /// The followed podcasts' episodes (the Inbox's), shared with Home.
    let followingFeed: FollowingFeedViewModel
    let onOpen: (Episode) -> Void

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.bookmarks) private var bookmarks
    @Environment(\.downloadManager) private var downloads
    @Environment(\.recentlyPlayed) private var recentlyPlayed

    @State private var tab: LibraryTab

    init(followingFeed: FollowingFeedViewModel, tab: LibraryTab = .new, onOpen: @escaping (Episode) -> Void) {
        self.followingFeed = followingFeed
        self.onOpen = onOpen
        _tab = State(initialValue: tab)
    }
    @Namespace private var tabLine

    private var newEpisodes: [PodcastEpisode] {
        InboxFeed.items(following: favoritesManager.favorites, episodes: followingFeed.episodesByPodcast)
    }

    private var items: [LibraryItem] {
        tab.items(
            new: newEpisodes,
            saved: bookmarks.episodes,
            downloads: downloads.downloadedEpisodes,
            history: recentlyPlayed.items
        )
    }

    var body: some View {
        // The ScrollView is the screen itself, so it reaches the bottom edge
        // and its rows pass behind the mini player and the bar; the tabs
        // stay pinned on top (a safe-area inset, over the page's color).
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    LibraryEpisodeCard(item: item) { onOpen(item.episode) }
                    if item.id != items.last?.id {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        // Each tab starts at its top.
        .id(tab)
        .overlay {
            if items.isEmpty { emptyState(tab) }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                tabBar
                Divider()
            }
            .background(AppColor.screenBackground)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(swipe)
        .animation(AppAnimation.listChange, value: items.map(\.id))
        .background(AppColor.screenBackground.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: tab)
    }

    // MARK: - Tabs

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(LibraryTab.allCases) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 12)
    }

    private func tabButton(_ item: LibraryTab) -> some View {
        let isOn = tab == item
        return Button {
            withAnimation(AppAnimation.selection) { tab = item }
        } label: {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isOn ? AppColor.Text.primary : AppColor.Text.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 48)
                .overlay(alignment: .bottom) {
                    if isOn {
                        Rectangle()
                            .fill(AppColor.Status.critical)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "line", in: tabLine)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected, .isHeader] : [])
    }

    /// Sideways (clearly more than up or down): the next or previous tab.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > 60, abs(dx) > abs(value.translation.height) * 2 else { return }
                let tabs = LibraryTab.allCases
                guard let index = tabs.firstIndex(of: tab) else { return }
                let next = dx < 0 ? index + 1 : index - 1
                guard tabs.indices.contains(next) else { return }
                withAnimation(AppAnimation.selection) { tab = tabs[next] }
            }
    }

    // MARK: - Empty

    @ViewBuilder
    private func emptyState(_ tab: LibraryTab) -> some View {
        switch tab {
        case .new:
            ContentUnavailableView(
                "No new episodes",
                systemImage: "tray",
                description: Text("New episodes from the podcasts you follow show up here.")
            )
        case .saved:
            ContentUnavailableView(
                "No saved episodes",
                systemImage: "bookmark",
                description: Text("Save an episode from its ••• menu and it'll be here.")
            )
        case .downloads:
            ContentUnavailableView(
                "No downloads yet",
                systemImage: "arrow.down.circle",
                description: Text("Downloaded episodes play without internet.")
            )
        case .history:
            ContentUnavailableView(
                "Nothing played yet",
                systemImage: "clock.arrow.circlepath",
                description: Text("Episodes you play show up here.")
            )
        }
    }
}
