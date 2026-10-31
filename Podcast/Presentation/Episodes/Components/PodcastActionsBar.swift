//
//  PodcastActionsBar.swift
//  Podcast
//

import SwiftUI

/// Centered under the name: Follow (filled in the accent; soft once you
/// follow), ▶ Latest (plays the newest episode) and share.
struct PodcastActionsBar: View {

    let podcast: Podcast
    let isFollowing: Bool
    let onFollow: () -> Void
    let onLatest: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onFollow) {
                Label(isFollowing ? "Following" : "Follow",
                      systemImage: isFollowing ? "checkmark" : "plus")
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(isFollowing ? AppColor.Text.primary : AppColor.Text.inverse)
                    .padding(.horizontal, 22)
                    .frame(minHeight: 44)
                    .background(isFollowing ? AppColor.Surface.muted : AppColor.Accent.strong, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: isFollowing) { _, following in following }
            .animation(AppAnimation.selection, value: isFollowing)

            Button(action: onLatest) {
                Label("Latest", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 44)
                    .background(AppColor.Surface.muted, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play the latest episode")

            if let url = URL(string: "https://podcasts.apple.com/podcast/id\(podcast.trackId)") {
                ShareLink(item: url, subject: Text(podcast.trackName ?? "")) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .frame(width: 44, height: 44)
                        .background(AppColor.Surface.muted, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
