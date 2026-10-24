//
//  InboxBarButton.swift
//  Podcast
//

import SwiftUI

/// The Inbox tray as Library's navigation bar button (top right): counts
/// what's new in the episodes "For you" already downloaded and opens the
/// Inbox with them. Hosted in a UIBarButtonItem by HomeController.
struct InboxBarButton: View {

    let forYou: ForYouViewModel
    let onOpen: ([ForYouViewModel.Item]) -> Void

    @Environment(\.favoritesManager) private var favoritesManager

    private var items: [ForYouViewModel.Item] {
        InboxFeed.items(following: favoritesManager.favorites, episodes: forYou.episodesByPodcast)
    }

    private var newCount: Int {
        InboxFeed.newCount(in: items, since: InboxSeen.shared.lastSeen)
    }

    var body: some View {
        InboxButton(newCount: newCount) { onOpen(items) }
            .animation(AppAnimation.listChange, value: newCount)
    }
}
