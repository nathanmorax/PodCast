//
//  LibraryView.swift
//  Podcast
//

import SwiftUI

/// The Library: every episode you have, in tabs (New · Saved · Downloads ·
/// History), grouped by show. Each show is a band in its own color with
/// its episodes under it, as lines or as covers two or three across (the
/// picker next to the title; remembered). A sideways swipe moves to the
/// next or previous tab. Hosted by LibraryController.
///
/// One plain ScrollView (not a paging TabView): a TabView clips its pages
/// at the safe area, so nothing showed behind the mini player and the bar;
/// a ScrollView scrolls under them like every other list in the app.
struct LibraryView: View {

    /// The followed podcasts' episodes (the Inbox's), shared with Home.
    let followingFeed: FollowingFeedViewModel
    /// An episode was tapped (its screen opens; ▶ plays it instead).
    let onOpen: (LibraryItem) -> Void

    @Environment(\.favoritesManager) private var favoritesManager
    @Environment(\.bookmarks) private var bookmarks
    @Environment(\.downloadManager) private var downloads
    @Environment(\.recentlyPlayed) private var recentlyPlayed

    @State private var tab: LibraryTab
    @AppStorage("library.layout") private var layout: LibraryLayout = .list

    init(followingFeed: FollowingFeedViewModel, tab: LibraryTab = .new, onOpen: @escaping (LibraryItem) -> Void) {
        self.followingFeed = followingFeed
        self.onOpen = onOpen
        _tab = State(initialValue: tab)
    }

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
        let items = self.items
        let groups = LibraryGroups.group(items)

        // The ScrollView is the screen itself, so it reaches the bottom edge
        // and its shows pass behind the mini player and the bar; the title,
        // picker and tabs stay pinned on top (a safe-area inset).
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(groups) { group in
                    LibraryShowSection(
                        group: group,
                        layout: layout,
                        badge: badge(count: group.items.count),
                        onOpen: onOpen
                    )
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        // Each tab starts at its top.
        .id(tab)
        .overlay {
            if items.isEmpty { LibraryEmptyState(tab: tab) }
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .contentShape(Rectangle())
        .simultaneousGesture(swipe)
        .animation(AppAnimation.listChange, value: items.map(\.id))
        .animation(AppAnimation.listChange, value: layout)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: tab)
        .sensoryFeedback(.selection, trigger: layout)
    }

    // MARK: - Header

    /// LIBRARY in tall capitals with the layout picker, then the tabs.
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                Text("Library")
                    .font(AppFont.feedHero)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LibraryLayoutPicker(layout: $layout)
            }
            .padding(.leading, 20)
            .padding(.trailing, 16)
            .padding(.top, 4)

            LibraryTabBar(tab: $tab)
        }
        .background(AppColor.screenBackground)
        .overlay(alignment: .bottom) { Divider() }
    }

    /// "3 NEW" on New; elsewhere just how many.
    private func badge(count: Int) -> Text {
        if tab == .new {
            Text("\(count) new")
        } else {
            Text("\(count)")
        }
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
}
