//
//  ContinueShowStrip.swift
//  Podcast
//

import SwiftUI

/// The mustard strip over a podcast's episodes when one of them was left
/// halfway: ▶, "Continue · 23 min left", its title and how far it got. ▶
/// resumes it in the mini player; the rest opens it.
struct ContinueShowStrip: View {

    let item: RecentlyPlayed
    let onResume: () -> Void
    let onOpen: () -> Void

    @Environment(\.playerManager) private var playerManager

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.episode.streamUrl
    }

    private var isPlaying: Bool { isCurrent && playerManager.viewModel.isPlaying }

    /// Live for the episode in the player; as saved for the others.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onResume) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColor.Accent.soft)
                    .frame(width: 18, height: 18)
                    .offset(x: isPlaying ? 0 : 1)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? Text("Pause") : Text("Resume"))

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue · \(item.minutesLeftText(at: progress)) left")
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                        .monospacedDigit()
                    Text(item.episode.title)
                        .font(.system(.headline, weight: .bold).width(.compressed))
                        .textCase(.uppercase)
                        .lineLimit(1)
                    Capsule()
                        .fill(AppColor.Text.onPastel.opacity(0.2))
                        .frame(height: 3)
                        .overlay(alignment: .leading) {
                            GeometryReader { geometry in
                                Capsule()
                                    .fill(AppColor.Text.onPastel)
                                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
                            }
                        }
                        .padding(.top, 3)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Shows the episode's details")
        }
        .foregroundStyle(AppColor.Text.onPastel)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppColor.Accent.soft)
    }
}
