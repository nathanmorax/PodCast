//
//  InboxBarButton.swift
//  Podcast
//

import SwiftUI

/// The Inbox tray as Library's navigation bar button (top right): counts
/// what's new in the followed podcasts' episodes and opens the Inbox with
/// them. Hosted in a UIBarButtonItem by HomeController.
struct InboxBarButton: View {

    let feed: FollowingFeedViewModel
    let onOpen: ([PodcastEpisode]) -> Void

    @Environment(\.favoritesManager) private var favoritesManager

    private var items: [PodcastEpisode] {
        InboxFeed.items(following: favoritesManager.favorites, episodes: feed.episodesByPodcast)
    }

    private var newCount: Int {
        InboxFeed.newCount(in: items, since: InboxSeen.shared.lastSeen)
    }

    var body: some View {
        InboxButton(newCount: newCount) { onOpen(items) }
            .animation(AppAnimation.listChange, value: newCount)
    }
}
