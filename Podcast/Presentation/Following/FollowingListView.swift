//
//  FollowingListView.swift
//  Podcast
//

import SwiftUI

/// Every podcast the listener follows, opened from "Following" in Home.
/// Plain rows with a hairline separator (no cards), like the episode list.
struct FollowingListView: View {

    let onOpenPodcast: (Podcast) -> Void

    @Environment(\.favoritesManager) private var favoritesManager

    private var podcasts: [Podcast] { favoritesManager.favorites }

    var body: some View {
        Group {
            if podcasts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(podcasts.enumerated()), id: \.element.trackId) { index, podcast in
                            Button {
                                onOpenPodcast(podcast)
                            } label: {
                                FollowingRow(podcast: podcast, showsSeparator: index < podcasts.count - 1)
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
                    .padding(.top, 8)
                    .padding(.bottom, 24) // the bottom bar's space comes from the safe area
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: podcasts.map(\.trackId))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.stack")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.Accent.soft)
            Text("Nothing followed yet")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
            Text("Tap + on a podcast to follow it. It'll show up here.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 80)
    }
}

/// Category in serif capitals, the name in bold, who makes it; the cover
/// on the right (like every list row).
private struct FollowingRow: View {

    let podcast: Podcast
    let showsSeparator: Bool

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                RowOverline(text: podcast.primaryGenreName ?? "")
                RowTitle(text: podcast.trackName ?? "")
                if let artist = podcast.artistName, !artist.isEmpty {
                    Text(artist)
                        .font(.system(.callout, weight: .medium))
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RowArtwork(side: 72) {
                ZoomSourceImage(podcast: podcast, cornerRadius: 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(AppColor.Text.tertiary.opacity(0.5))
                    .frame(height: 1 / displayScale)
                    .padding(.horizontal, 20)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
