//
//  LibraryButton.swift
//  Podcast
//

import SwiftUI

/// The books button at the top right of Home: opens the Library. A mustard
/// badge counts the new episodes of the shows you follow (it bounces when
/// one more arrives).
struct LibraryButton: View {

    let newCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "books.vertical")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(AppColor.Text.primary)
                .symbolEffect(.bounce, value: newCount)
                .frame(width: 44, height: 44)
                .overlay(alignment: .topTrailing) {
                    if newCount > 0 { badge }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Library")
        .accessibilityValue(newCount > 0 ? Text("\(newCount) new episodes") : Text(verbatim: ""))
    }

    private var badge: some View {
        Text(verbatim: newCount > 99 ? "99+" : "\(newCount)")
            .font(.system(size: 11, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(AppColor.Text.onPastel)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(Capsule().fill(AppColor.Accent.soft))
            .offset(x: -1, y: 3)
            .transition(.scale.combined(with: .opacity))
    }
}

/// LibraryButton in Home's navigation bar: counts what's new in the followed
/// shows. Hosted in a UIBarButtonItem by HomeController.
struct LibraryBarButton: View {

    let feed: FollowingFeedViewModel
    let onOpen: () -> Void

    @Environment(\.favoritesManager) private var favoritesManager

    private var newCount: Int {
        let items = InboxFeed.items(following: favoritesManager.favorites, episodes: feed.episodesByPodcast)
        return InboxFeed.newCount(in: items, since: InboxSeen.shared.lastSeen)
    }

    var body: some View {
        LibraryButton(newCount: newCount, action: onOpen)
            .animation(AppAnimation.listChange, value: newCount)
    }
}
