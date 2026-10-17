//
//  MiniPlayerCapsule.swift
//  Podcast
//

import SwiftUI

/// What's playing: artwork with its progress strip, title, play/pause.
/// Tapping the info opens the full player.
struct MiniPlayerCapsule: View {

    @Environment(\.playerManager) private var manager
    let episode: Episode
    /// Author and remaining time; hidden when the bar is folded.
    let showsSubtitle: Bool

    var body: some View {
        HStack(spacing: 4) {
            Button {
                manager.expand()
            } label: {
                HStack(spacing: 10) {
                    artwork

                    VStack(alignment: .leading, spacing: 1) {
                        Text(episode.title)
                            .font(AppFont.itemTitle)
                            .foregroundStyle(AppColor.Text.primary)
                            .lineLimit(1)
                        if showsSubtitle {
                            Text(subtitle)
                                .font(AppFont.caption)
                                .monospacedDigit()
                                .foregroundStyle(AppColor.Text.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(!showsSubtitle ? Text(verbatim: episode.title) : Text(verbatim: "\(episode.title), \(subtitle)"))
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
        }
        .padding(.leading, 9)
        .padding(.trailing, 6)
        .frame(maxHeight: .infinity)
        .glassCapsule()
    }

    private var artwork: some View {
        Color.clear
            .frame(width: 38, height: 38)
            .overlay { PodcastImage(source: episode.imageUrl) }
            .overlay(alignment: .bottomLeading) {
                // Progress lives on the artwork's bottom edge.
                GeometryReader { geo in
                    Rectangle()
                        .fill(AppColor.lavender)
                        .frame(width: geo.size.width * CGFloat(manager.viewModel.progress), height: 3)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var subtitle: String {
        let remaining = manager.viewModel.remainingTimeText
        return remaining.isEmpty ? episode.author : "\(episode.author) · −\(remaining)"
    }
}
