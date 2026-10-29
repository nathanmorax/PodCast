//
//  PodcastActionsBar.swift
//  Podcast
//

import SwiftUI

/// Follow (mustard; outlined once you follow), Latest (plays the newest
/// episode) and share.
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
                    .font(.subheadline.weight(.bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(isFollowing ? AppColor.Text.primary : AppColor.Text.onPastel)
                    .padding(.horizontal, 22)
                    .frame(minHeight: 46)
                    .background {
                        if isFollowing {
                            Capsule().strokeBorder(AppColor.Text.primary.opacity(0.3), lineWidth: 1)
                        } else {
                            Capsule().fill(AppColor.Accent.soft)
                        }
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: isFollowing) { _, following in following }
            .animation(AppAnimation.selection, value: isFollowing)

            Button(action: onLatest) {
                Label("Latest", systemImage: "play.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColor.Text.primary)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 46)
                    .overlay { Capsule().strokeBorder(AppColor.Text.primary.opacity(0.3), lineWidth: 1) }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play the latest episode")

            Spacer(minLength: 0)

            if let url = URL(string: "https://podcasts.apple.com/podcast/id\(podcast.trackId)") {
                ShareLink(item: url, subject: Text(podcast.trackName ?? "")) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColor.Text.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
            }
        }
    }
}
