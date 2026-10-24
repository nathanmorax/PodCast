//
//  MiniPlayerCapsule.swift
//  Podcast
//

import SwiftUI

/// What's playing: artwork, title, a thin progress bar with the time left
/// under it, play/pause and ⟳ 15 (the same jump as the full player and the
/// lock screen). Tapping the info opens the full player.
struct MiniPlayerCapsule: View {

    @Environment(\.playerManager) private var manager
    let episode: Episode

    var body: some View {
        HStack(spacing: 4) {
            Button {
                manager.expand()
            } label: {
                HStack(spacing: 10) {
                    Color.clear
                        .frame(width: 38, height: 38)
                        .overlay { PodcastImage(source: episode.imageUrl) }
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    VStack(alignment: .leading, spacing: 7) {
                        Text(episode.title)
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.Text.primary)
                            .lineLimit(1)
                        // Its own view: only the bar redraws as playback moves.
                        MiniProgressBar()
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(verbatim: episode.title))
            .accessibilityHint("Opens the player")

            Button {
                manager.togglePlayPause()
            } label: {
                Image(systemName: manager.viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(manager.viewModel.isPlaying ? Text("Pause") : Text("Play"))

            Button {
                manager.skipForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!manager.canSkip)
            .opacity(manager.canSkip ? 1 : 0.4)
            .accessibilityLabel("Skip forward 15 seconds")
        }
        .padding(.leading, 9)
        .padding(.trailing, 6)
        .frame(maxHeight: .infinity)
        .glassCapsule()
    }
}

/// A thin capsule track with the played part in mustard, and the time left
/// next to it ("−23:10"). Reads the progress itself, so the rest of the mini
/// player doesn't update every tick.
private struct MiniProgressBar: View {

    @Environment(\.playerManager) private var manager

    var body: some View {
        let progress = CGFloat(min(max(manager.viewModel.progress, 0), 1))
        let remaining = manager.viewModel.remainingTimeText
        HStack(spacing: 8) {
            Capsule()
                .fill(AppColor.Text.tertiary.opacity(0.35))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.accent)
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                }
                .clipShape(Capsule())

            if !remaining.isEmpty {
                Text(verbatim: "−\(remaining)")
                    .font(AppFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Time left")
        .accessibilityValue(Text(verbatim: remaining))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    MiniPlayerCapsule(episode: .mock)
        .frame(height: 62)
        .padding()
        .environment(\.playerManager, .preview)
}
