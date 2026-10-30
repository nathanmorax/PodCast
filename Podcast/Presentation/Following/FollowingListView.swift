//
//  FollowingListView.swift
//  Podcast
//

import SwiftUI

/// Every podcast you follow, opened from "See All" in Home: FOLLOWING in
/// tall capitals with how many shows and new episodes, then each show as a
/// band in its own color with its newest episode (▶ plays it). Shows with
/// new episodes come first. Touch and hold a band to unfollow.
struct FollowingListView: View {

    /// The followed shows' episodes, shared with Home.
    let followingFeed: FollowingFeedViewModel
    let onOpenPodcast: (Podcast) -> Void

    @Environment(\.favoritesManager) private var favoritesManager

    private var podcasts: [Podcast] { favoritesManager.favorites }

    private var shows: [FollowingShow] {
        FollowingShows.rows(
            podcasts: podcasts,
            episodes: followingFeed.episodesByPodcast,
            newEpisodes: NewEpisodeMarks.newEpisodes(
                podcasts: podcasts,
                episodes: followingFeed.episodesByPodcast,
                inboxSeen: InboxSeen.shared.lastSeen,
                showSeen: ShowSeen.shared.lastSeen
            )
        )
    }

    var body: some View {
        let shows = self.shows

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header(shows)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 14)

                LazyVStack(spacing: 6) {
                    ForEach(shows) { show in
                        FollowingShowBand(show: show) { onOpenPodcast(show.podcast) }
                            .contextMenu {
                                Button("Unfollow", systemImage: "minus.circle", role: .destructive) {
                                    withAnimation(AppAnimation.listChange) {
                                        favoritesManager.deleteFavorite(show.podcast)
                                    }
                                }
                            }
                    }
                }
            }
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .scrollIndicators(.hidden)
        .overlay {
            if podcasts.isEmpty {
                ContentUnavailableView(
                    "Nothing followed yet",
                    systemImage: "square.stack",
                    description: Text("Tap + on a podcast to follow it. It'll show up here.")
                )
            }
        }
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: shows.map(\.id))
        .task { followingFeed.load(following: podcasts) }
    }

    /// FOLLOWING and "7 shows · 6 new episodes".
    private func header(_ shows: [FollowingShow]) -> some View {
        let newCount = shows.reduce(0) { $0 + $1.newCount }
        return VStack(alignment: .leading, spacing: 6) {
            Text("Following")
                .font(AppFont.feedHero)
                .textCase(.uppercase)
                .foregroundStyle(AppColor.Text.primary)
                .accessibilityAddTraits(.isHeader)
            if !shows.isEmpty {
                Group {
                    if newCount > 0 {
                        // Two plural phrases ("1 show", "6 new episodes") joined.
                        Text("\(Text("\(shows.count) shows")) · \(Text("\(newCount) new episodes"))")
                    } else {
                        Text("\(shows.count) shows")
                    }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.Text.secondary)
            }
        }
    }
}
