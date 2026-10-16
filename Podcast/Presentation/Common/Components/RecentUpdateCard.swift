//
//  RecentUpdateCard.swift
//  Podcast
//

import SwiftUI

struct RecentUpdateCard: View {
    let item: RecentlyPlayed
    @Environment(\.playerManager) private var playerManager

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.id
    }

    /// Live progress for the episode that's playing, saved progress for the rest.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Clear square + overlay: the cover always fills the same square
            // (before, `.aspectRatio(.fill)` after `.frame` could overflow).
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { PodcastImage(source: item.episode.imageUrl) }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    if isCurrent {
                        Label("Sonando", systemImage: "waveform")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppColor.lavender))
                            .padding(8)
                    }
                }

            Text(item.episode.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black) // was .white on a light background: unreadable
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 4) {
                Text(item.lastPlayedAt, format: .relative(presentation: .named))
                Text("·")
                Text(item.episode.author)
            }
            .font(.system(size: 12))
            .foregroundStyle(.black.opacity(0.5))
            .lineLimit(1)

            if progress > 0.01 {
                ProgressView(value: min(progress, 1))
                    .tint(AppColor.lavender)
                    .accessibilityLabel(progress >= 0.98 ? "Terminado" : "Escuchado \(Int(progress * 100)) por ciento")
            }
        }
        .accessibilityElement(children: .combine)
    }
}
