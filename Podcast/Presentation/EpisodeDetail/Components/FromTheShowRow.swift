//
//  FromTheShowRow.swift
//  Podcast
//

import SwiftUI

/// The show this episode is from: its cover, its name in tall capitals,
/// "Host · Science", and Follow / Following. The cover and name open the
/// show (zooming out of the cover).
struct FromTheShowRow: View {

    let podcast: Podcast
    let isFollowing: Bool
    let onOpen: () -> Void
    let onToggleFollow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EpisodeSectionTitle(title: "From the show")

            HStack(spacing: 14) {
                Button(action: onOpen) {
                    HStack(spacing: 14) {
                        Color.clear
                            .frame(width: 72, height: 72)
                            .overlay { ZoomSourceImage(podcast: podcast, cornerRadius: 0) }
                            .clipped()
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(podcast.trackName ?? "")
                                .font(AppFont.feedTitle)
                                .textCase(.uppercase)
                                .lineLimit(2)
                            Text(caption)
                                .font(.caption)
                                .foregroundStyle(AppColor.Text.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the podcast")

                Button(action: onToggleFollow) {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 36)
                        .overlay { Capsule().strokeBorder(AppColor.Text.primary, lineWidth: 1) }
                        .frame(minHeight: 44)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: isFollowing) { _, following in following }
            }
        }
        .foregroundStyle(AppColor.Text.primary)
    }

    /// "Host · Science".
    private var caption: String {
        [podcast.artistName, podcast.genreName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
