//
//  ContinueListeningCard.swift
//  Podcast
//

import SwiftUI

/// Big card for the last unfinished episode: play/pause right there.
struct ContinueListeningCard: View {

    let item: RecentlyPlayed
    @Environment(\.playerManager) private var playerManager

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.id
    }

    private var isPlaying: Bool {
        isCurrent && playerManager.viewModel.isPlaying
    }

    /// Live progress for the episode that's loaded, saved progress otherwise.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                playerManager.play(item.episode)
            } label: {
                HStack(spacing: 14) {
                    Color.clear
                        .frame(width: 88, height: 88)
                        .overlay { PodcastImage(source: item.episode.imageUrl) }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.episode.author)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.5))
                            .lineLimit(1)
                        Text(item.episode.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        ProgressView(value: min(max(progress, 0), 1))
                            .tint(AppColor.lavenderInk)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the player")

            Button {
                if isCurrent {
                    playerManager.togglePlayPause()
                } else {
                    playerManager.play(item.episode, presentation: .mini)
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.black)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(AppColor.lavender))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? Text("Pause") : Text("Resume"))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
    }
}
