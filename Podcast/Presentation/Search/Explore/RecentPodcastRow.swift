//
//  RecentPodcastRow.swift
//  Podcast
//

import SwiftUI

/// A podcast opened from Search: square cover, name in tall capitals, "Podcast · Genre",
/// and an × to take it off the list.
struct RecentPodcastRow: View {

    let podcast: Podcast
    let onOpen: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    ZoomSourceImage(podcast: podcast, cornerRadius: 0)
                        .frame(width: 44, height: 44)
                        .clipped()
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(podcast.trackName ?? "")
                            .font(.system(.headline, weight: .bold).width(.compressed))
                            .textCase(.uppercase)
                            .foregroundStyle(AppColor.Text.primary)
                            .lineLimit(1)
                        Text(kind)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.Text.tertiary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove from recents")
        }
        .frame(minHeight: 60)
    }

    /// "Podcast · Science".
    private var kind: String {
        [String(localized: "Podcast"), podcast.primaryGenreName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
