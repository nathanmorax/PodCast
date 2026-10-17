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
                .font(AppFont.headline)
                .foregroundStyle(AppColor.Text.primary)
            Text("Tap + on a podcast to follow it. It'll show up here.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 80)
    }
}

/// Cover, name, "artist · genre".
private struct FollowingRow: View {

    let podcast: Podcast
    let showsSeparator: Bool

    @Environment(\.displayScale) private var displayScale

    private var subtitle: String {
        [podcast.artistName, podcast.primaryGenreName]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 52, height: 52)
                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(podcast.trackName ?? "")
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

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.Text.tertiary)
                .accessibilityHidden(true)
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

#Preview {
    FollowingListView(onOpenPodcast: { _ in })
        .environment(\.favoritesManager, .preview)
}
