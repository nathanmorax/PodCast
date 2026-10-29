//
//  PodcastEpisodeRow.swift
//  Podcast
//

import SwiftUI

/// One episode on its podcast's page, no cover (they'd all be the show's):
/// date · length in small capitals (↓ when downloaded), the title in tall
/// capitals, a line of what it's about, and ▶ in a thin ring. The row opens
/// the episode; ▶ plays it in the mini player.
struct PodcastEpisodeRow: View {

    let episode: Episode
    let onOpen: () -> Void

    var body: some View {
        let actions = EpisodeActionViewModel(episode: episode)

        HStack(alignment: .top, spacing: 14) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(episode.pubDate, format: .dateTime.day().month(.abbreviated).year())
                        Text(verbatim: "·")
                        Text(episode.durationDisplayText)
                        DownloadedBadge(episode: episode)
                    }
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(actions.isPlaying ? AppColor.Accent.strong : AppColor.Text.secondary)
                    .lineLimit(1)

                    Text(episode.title)
                        .font(.system(.title3, weight: .bold).width(.compressed))
                        .textCase(.uppercase)
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if !episode.description.isEmpty {
                        Text(episode.description)
                            .font(.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            Button {
                actions.playOrPause()
            } label: {
                Image(systemName: actions.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(actions.isPlaying ? AppColor.Accent.strong : AppColor.Text.primary)
                    .frame(width: 16, height: 16)
                    .offset(x: actions.isPlaying ? 0 : 1)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle().strokeBorder(
                            actions.isPlaying ? AppColor.Accent.strong : AppColor.Text.primary.opacity(0.3),
                            lineWidth: 1
                        )
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
            .accessibilityLabel(actions.isPlaying ? Text("Pause") : Text("Play"))
        }
        .padding(.vertical, 14)
    }
}
