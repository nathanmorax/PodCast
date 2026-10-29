//
//  ForYouRow.swift
//  Podcast
//

import SwiftUI

/// "For you": cards (ForYouCard) that snap one by one, the next one peeking
/// at the right edge.
///
/// Tapping a card opens the episode, zooming out of it and back into it
/// (ZoomSourceHost + pushZooming in HomeController). ▶ on the artwork plays
/// it right away; holding the card offers Play and Go to podcast.
struct ForYouRow: View {

    let items: [PodcastEpisode]
    let onOpen: (PodcastEpisode) -> Void
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 18) {
                ForEach(items) { item in
                    ZoomSourceHost(
                        id: .episode(item.episode.streamUrl, section: .forYou),
                        cornerRadius: ForYouCard.cornerRadius
                    ) {
                        ForYouRowCard(
                            item: item,
                            onOpen: { onOpen(item) },
                            onPlay: { onPlay(item.episode) },
                            onOpenPodcast: { onOpenPodcast(item.podcast) }
                        )
                    }
                    // Most of the screen's width: the next card peeks.
                    .containerRelativeFrame(.horizontal) { width, _ in
                        min(width * 0.68, 300)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

/// The artwork and the texts open the episode; ▶ sits over the artwork's
/// corner as its own button (a button inside another button's label
/// wouldn't get its tap).
private struct ForYouRowCard: View {

    let item: PodcastEpisode
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onOpenPodcast: () -> Void

    @Environment(\.playerManager) private var playerManager

    private var isPlaying: Bool {
        playerManager.currentEpisode?.streamUrl == item.episode.streamUrl && playerManager.viewModel.isPlaying
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onOpen) {
                ForYouCard.Artwork(item: item)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottomTrailing) {
                playButton
                    .padding(10)
            }

            Button(action: onOpen) {
                ForYouCard.Texts(item: item)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .accessibilityHint("Opens the episode")
        .contextMenu {
            Button("Play", systemImage: "play.fill", action: onPlay)
            Button("Go to podcast", systemImage: "square.stack", action: onOpenPodcast)
        }
    }

    /// ▶ black, with a white ring.
    private var playButton: some View {
        Button(action: onPlay) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 15, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.black))
                .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? Text("Pause") : Text("Play"))
    }
}
