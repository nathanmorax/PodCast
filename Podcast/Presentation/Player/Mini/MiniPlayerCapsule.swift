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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                        if showsSubtitle {
                            Text(subtitle)
                                .font(.system(size: 11))
                                .monospacedDigit()
                                .foregroundStyle(.black.opacity(0.55))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Abre el reproductor")

            Button {
                manager.togglePlayPause()
            } label: {
                Image(systemName: manager.viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(manager.viewModel.isPlaying ? "Pausar" : "Reproducir")
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
