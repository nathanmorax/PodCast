//
//  FromTheShowRow.swift
//  Podcast
//

import SwiftUI

/// The show this episode is from: its rounded cover, its name, "Host ·
/// Science", and Follow (filled in the accent) / Following (soft). The cover and name open the
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
                            .frame(width: 64, height: 64)
                            .overlay { ZoomSourceImage(podcast: podcast, cornerRadius: 12) }
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(podcast.trackName ?? "")
                                .font(.headline)
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isFollowing ? AppColor.Text.primary : AppColor.Text.inverse)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 36)
                        .background(isFollowing ? AppColor.Surface.muted : AppColor.Accent.strong, in: Capsule())
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
